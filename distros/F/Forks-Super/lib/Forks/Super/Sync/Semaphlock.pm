package Forks::Super::Sync::Semaphlock;
use strict;
use warnings;
use Carp;
use Time::HiRes;
use Forks::Super::Util;
our $VERSION = '0.93';
our @ISA = qw(Forks::Super::Sync);

my $ipc_seq = 0;
my $sync_count = 0;

sub new {
    my ($pkg, $count, @initial) = @_;
    my $self = bless {}, $pkg;
    $self->{count} = $count;
    $self->{initial} = [ @initial ];
    $self->{id} = $sync_count++;
    bless $self, $pkg;

    for my $i (0 .. $count-1) {
        my $file = _get_filename();
        $self->_register_ipc_file($file, "count $i");
        if (open my $fh, '>>', $file) {
            $self->{files}[$i] = $file;
            close $fh;
        } else {
            carp "could not use $file as a synchronization file: $!";
        }
    }
    return $self;
}

sub _register_ipc_file {
    my ($self, $filename, $i) = @_;
    if (defined &Forks::Super::Job::Ipc::_register_ipc_file) {
      Forks::Super::Job::Ipc::_register_ipc_file(
          $filename, [ purpose => "sync object id $self->{id} $i" ]);
    } else {
        $self->{unlink} ||= [];
        push @{$self->{unlink}}, $filename;
    }
    return;
}

sub _touch {
  my $file = shift;
  open my $touch, '>>', $file;
  close $touch;
  return;
}

sub _releaseAfterFork {
    my $self = shift;

    # for this implementation, it is more like acquire after fork
    my $label = $$ == $self->{ppid} ? 'P' : 'C';

    my $wait = time + 5.0;

    for my $i (0 .. $self->{count} - 1) {
        if ($self->{initial}[$i] eq $label) {
            my $file = $self->{files}[$i];
            if ($file) {
                my $fh;
                if (!open $fh, '>>', $file) {
                    carp 'FS::Sync::Semaphlock::releaseAfterFork: ',
                         "error acquiring resource $i in $label";
                    next;
                }
                flock $fh, 2;
                $self->{acquired}[$i] = $fh;
            } else {
                carp 'FS::Sync::Semaphlock::releaseAfterFork: ',
                    "no resource $i $file to acquire in $label";
            }
        }
    }
    return;
}

sub release {
    my ($self, $n) = @_;
    return if $n<0 || $n>=$self->{count};
    if (defined $self->{acquired}[$n]) {
        my $z = flock $self->{acquired}[$n], 8;
        $self->{acquired}[$n] = undef;
        return $z;
    }
    return;
}

sub acquire {
    my ($self, $n, $timeout) = @_;
    return if $n<0 || $n>=$self->{count};
    my $file = $self->{files}[$n];
    if (defined $self->{acquired}[$n]) {
        return -1;
    }
    my $fh;

    # on Cygwin, using fcntl to emulate flock, this open can
    # (intermittently) fail with $! := "Device or resource busy"
    for my $try (1..5) {
        last if open $fh, '>>', $file;
        if ($try == 5) {
            carp "failed to acquire file resource $file after 5 tries: $!";
            return;
        }
        Time::HiRes::sleep(0.25 * $try);
    }

    if (defined $timeout) {
        my $expire = Time::HiRes::time() + $timeout;
        my $z;
        do {
            $z = flock $fh, 6;
            if ($z) {
                $self->{acquired}[$n] = $fh;
                return $z;
            }
            if ($timeout > 0.0) {
                Time::HiRes::sleep(0.01);
            }
        } while (Time::HiRes::time() < $expire);
        close $fh;
        return 0;
    }

    # no timeout
    my $z = flock $fh, 2;
    if ($z) {
        $self->{acquired}[$n] = $fh;
    }
    return $z;
}

sub DESTROY {
    my $self = shift;
    $self->release($_) for 0 .. $self->{count}-1;
    $self->{acquired} = [];
    unlink @{$self->{unlink}} if $self->{unlink};
    $self->{files} = [];
}

sub _get_filename {
    no warnings 'once';
    # best if this file is not on an NFS filesystem
    my @dirs;
    if ($^O eq 'MSWin32') {
        @dirs = ('C:/Temp', 'C:/Windows/Temp',
                 'C:/Winnt/Temp', 'D:/Windows/Temp', 'D:/Winnt/Temp',
                 'E:/Windows/Temp', 'E:/Winnt/Temp', $ENV{TEMP}, '.');
    } else {
	my ($cwd) = Forks::Super::Util::abs_path('.');
        @dirs = ('/tmp', '/var/tmp', '/usr/tmp', $cwd);
    }
    foreach my $dir (@dirs, $Forks::Super::IPC_DIR) {
        if ($dir =~ /\S/ && -d $dir && -r $dir && -w $dir && -x $dir) {
            return sprintf "%s/_sync%d-%03d",
                           $dir, $Forks::Super::MAIN_PID || $$, $ipc_seq++;
        }
    }
    carp "Forks::Super::Sync::Semaphlock: ",
        "trouble finding suitable lockfile dir";
    return sprintf "%s/.sync%03d", $Forks::Super::IPC_DIR, $ipc_seq++;
}

sub remove {
    my $self = shift;
    foreach my $fh (@{$self->{acquired}}) {
        if ($fh) {
            close $fh;
        }
    }
    delete $self->{count};
    $self->{fh} = [];
    return;
}

1;

__END__

=head1 NAME

Forks::Super::Sync::Semaphlock
- Forks::Super sync object using advisory file locking

=head1 SYNOPSIS

    $lock = Forks::Super::Sync->new(implementation => 'Semaphlock', ...);

    $pid=fork();
    $lock->releaseAfterFork();

    if ($pid == 0) { # child code
       $lock->acquire(...);
       $lock->release(...);
    } else {
       $lock->acquire(...);
       $lock->release(...);
    }

=head1 DESCRIPTION

IPC synchronization object implemented with advisory file locking.
Useful as a last resort if your system does not have good
support for semaphores or shared memory.

Advantages: should work anywhere that implements L<perlfunc/flock>.

Disadvantages: creates files, IPC litter. Uses precious filehandles.

=head1 SEE ALSO

L<Forks::Super::Sync|Forks::Super::Sync>

=cut

