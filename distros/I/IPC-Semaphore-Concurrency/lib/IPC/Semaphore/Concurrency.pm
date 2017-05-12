package IPC::Semaphore::Concurrency;

use 5.008008;
use strict;
use warnings;

use Carp;
use POSIX qw(O_WRONLY O_CREAT O_NONBLOCK O_NOCTTY);
use IPC::SysV qw(ftok IPC_NOWAIT IPC_CREAT IPC_EXCL S_IRUSR S_IWUSR S_IRGRP S_IWGRP S_IROTH S_IWOTH SEM_UNDO);
use IPC::Semaphore;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.04';

sub new {
	my $class = shift;

	my %args;
	if (@_ == 1) {
		# Only one required argument
		$args{'path'} = shift;
	} else {
		%args = @_;
	}

	if (!exists($args{'path'})) {
		carp "Must supply a path!"; #TODO: Allow private semaphores
		return undef;
	}
	# Set defaults
	$args{'project'} = 0 if (!exists($args{'project'}));
	$args{'count'} = 1 if (!exists($args{'count'}));
	$args{'value'} = 1 if (!exists($args{'value'})); # TODO: allow array (one value per semaphore)
	$args{'touch'} = 1 if (!exists($args{'touch'}));

	my $self = bless {}, $class;
	$self->{'_args'} = { %args };

	$self->_touch($self->{'_args'}->{'path'}) if (!-e $self->{'_args'}->{'path'} || $self->{'_args'}->{'touch'}) or return undef;
	$self->{'_args'}->{'key'} = $self->_ftok() or return undef;

	$self->{'_args'}->{'sem'} = $self->_create($self->key()) or return undef;

	return $self;
}

# Internal functions
sub _touch {
	# Create and/or touch the path, returns false if there's an error
	my $self = shift;
	my $path = shift;
	sysopen(my $fh, $path, O_WRONLY|O_CREAT|O_NONBLOCK|O_NOCTTY) or carp "Can't create $path: $!" and return 0;
	utime(undef, undef, $path) if ($self->{'_args'}->{'touch'});
	close $fh or carp "Can't close $path: $!" and return 0;
	return 1;
}

sub _ftok {
	# Create an IPC key, returns result of ftok()
	my $self = shift;
	return ftok($self->{'_args'}->{'path'}, $self->{'_args'}->{'project'}) or carp "Can't create semaphore key: $!" and return undef;
}

sub _create {
	# Create the semaphore and assign it its initial value
	my $self = shift;
	my $key = shift;
	# Presubably the semaphore exists already, so try using it right away
	my $sem = IPC::Semaphore->new($key, 0, 0);
	if (!defined($sem)) {
		# Creatie a new semaphore...
		$sem = IPC::Semaphore->new($key, $self->{'_args'}->{'count'}, IPC_CREAT|IPC_EXCL|S_IRUSR|S_IWUSR|S_IRGRP|S_IWGRP|S_IROTH|S_IWOTH);
		if (!defined($sem)) {
			# Make sure another process did not create it in our back
			$sem = IPC::Semaphore->new($key, 0, 0) or carp "Semaphore creation failed!\n";
		} else {
			# If we created the semaphore now we assign its initial value
			for (my $i=0; $i<$self->{'_args'}->{'count'}; $i++) { # TODO: Support array - see above
				$sem->op($i, $self->{'_args'}->{'value'}, 0);
			}
		}
	}
	# Return whatever last semget call got us
	return $sem;
}

# External API

sub getall {
	my $self = shift;
	return $self->{'_args'}->{'sem'}->getall();
}

sub getval {
	my $self = shift;
	my $nsem = shift or 0;
	return $self->{'_args'}->{'sem'}->getval($nsem);
}

sub getncnt {
	my $self = shift;
	my $nsem = shift or 0;
	return $self->{'_args'}->{'sem'}->getncnt($nsem);
}

sub setall {
	my $self = shift;
	return $self->{'_args'}->{'sem'}->setall(@_);
}

sub setval {
	my $self = shift;
	my ($nsem, $val) = @_;
	return $self->{'_args'}->{'sem'}->setval($nsem, $val);
}

sub stat {
	my $self = shift;
	return $self->{'_args'}->{'sem'}->stat();
}

sub id {
	my $self = shift;
	return $self->{'_args'}->{'sem'}->id();
}

sub key {
	my $self = shift;
	return $self->{'_args'}->{'key'};
}

sub acquire {
	my $self = shift;

	my %args;
	if (@_ >= 1 && $_[0] =~ /^\d+$/) {
		# Positional arguments
		($args{'sem'}, $args{'wait'}, $args{'max'}, $args{'undo'}) = @_;
	} else {
		%args = @_;
	}
	# Defaults
	$args{'sem'} =  0 if (!defined($args{'sem'}));
	$args{'wait'} =  0 if (!defined($args{'wait'}));
	$args{'max'} = -1 if (!defined($args{'max'}));
	$args{'undo'} = 1 if (!defined($args{'undo'}));

	my $sem = $self->{'_args'}->{'sem'};
	my $flags = IPC_NOWAIT;
	$flags |= SEM_UNDO if ($args{'undo'});

	my ($ret, $ncnt);
	# Get blocked process count here to retain Errno (thus $!) after the first semop call.
	$ncnt = $self->getncnt($args{'sem'}) if ($args{'wait'});

	if (($ret = $sem->op($args{'sem'}, -1, $flags))) {
		return $ret;
	} elsif ($args{'wait'}) {
		return $ret if ($args{'max'} >= 0 && $ncnt >= $args{'max'});
		# Remove NOWAIT and block
		$flags ^= IPC_NOWAIT;
		return $sem->op($args{'sem'}, -1, $flags);
	}
	return $ret;
}

sub release {
	my $self = shift;
	my $number = shift || 0;
	return $self->{'_args'}->{'sem'}->op($number, 1, 0);
}

sub remove {
	my $self = shift;
	return $self->{'_args'}->{'sem'}->remove();
}

1;
__END__

=head1 NAME

IPC::Semaphore::Concurrency - Concurrency guard using semaphores

=head1 SYNOPSIS

    use IPC::Semaphore::Concurrency;

    my $c = IPC::Semaphore::Concurrency->new('/tmp/sem_file');

    if ($c->acquire()) {
        print "Do work\n";
    } else {
        print "Pass our turn\n";
    }


    my $c = IPC::Semaphore::Concurrency->new(
        path  => '/tmp/sem_file',
        count => 2,
        value => $sem_max,
        );

    if ($c->acquire(0, 1, 0)) {
        print "Do work\n";
    } else {
        print "Error: Another process is already locked\n";
    }

    if ($c->acquire(1)) {
        print "Do other work\n";
    }

=head1 DESCRIPTION

This module allows you to limit concurrency of specific portions of your
code. It can be used to limit resource usage or to give exclusive access to
specific resources.

This module is similar in functionality to IPC::Concurrency with the main
differences being that is uses SysV Semaphores, and allow queuing up
processes while others hold the semaphore. There are other difference which
gives more flexibility in some cases.

Generally, errors messages on failures can be retrieved with C<$!>.

=head2 EXPORTS

None

=head1 CONSTRUCTOR

    IPC::Semaphore::Concurrency->new( $path );

    IPC::Semaphore::Concurrency->new(
        path    => $path
        project => $proj_id
        count   => $sem_count
        value   => $sem_value
        touch   => $touch_path
        );

=over 4

=item path

The path to combine with the project id for creating the semaphore key.
This file is only used for the inode and device numbers. Will be created
if missing.

=item project

The project_id used for generating the key. If nothing else, the
semaphore value can be used as changing the count will force generating a
new semaphore. Defaults to 0.

=item count

Number of semaphores to create. Default is 1.

=item value

Value assigned to the semaphore at creation time. Default is 1.

=item touch

If true, tough the path when creating the semaphore. This can be used to
ensure a file in /tmp do not get removed because it is too old.

=back

=head1 FUNCTIONS

=head2 getall

=head2 getval

=head2 getncnt

=head2 id

=head2 setall

=head2 setval

=head2 stat

=head2 remove

These functions are wrapper of the same functions in IPC::Semaphore.

For getval and getncnt, if no argument is given the default is 0.

=head2 key

    $c->key();

Return the key used to create the semaphore.

=head2 acquire

    $c->acquire();

    $c->acquire($sem_number, $wait, $max, $undo);

    $c->acquire(
        sem  => $sem_number,
        wait => $wait,
        max  => $max,
        undo => $undo,
        );

Acquire a semaphore lock. Return true if the lock was acquired.

=over 4

=item sem

The semaphore number to get. Defaults to 0.

=item wait

If true, block on semaphore acquisition.

=item max

If C<wait> is true, don't block if C<max> processes or more are waiting
for the semaphore. Defaults to -1 (unlimited).

You may want to set it to some decent value if blocking on the semaphore
to ensure processes don't add up infinitely.

=item undo

If defined and false, the semaphore won't be released automatically when
process exits. You must release manually and B<only once> the semaphore
with C<< $c->release() >>. See C<release> for important information before using
this!

Use with caution as you can block semaphore slots if the process crash or
gets killed.

=back

=head2 release

    $c->release();

    $c->release($sem_number);

B<WARNING: Use this at your own risks and only after understanding the
implications below!>

This function is useful only if you turn off the C<undo> option in
C<acquire> function and B<must be used with it.> It merely increment the
semaphore by one.

In its usual use case, IPC::Semaphore::Concurrency is locked once and
until the process exits. This function allow you to control yourself the
release of the lock, but you must understand what releasing a semaphore
actually means. Semaphores are merely counters and every time you
C<acquire> them you merely decrease the value - the locking happens once
the counter reaches 0.

This means if you C<release> more than once, you will effectively
increase the semaphore value and next time the semaphore is used it will
require as many C<acquire> to lock or fail locking. B<This includes the
implicit increase when the process exits when you don't set C<undo> to
false in C<acquire>!>. This means if you use C<release> without C<undo>
set to false, you will raise the value again at every process exit and your
semaphore won't lock things anymore!

=head1 TODO

=head3 Allow setting semaphore permissions, default to 600

=head3 Allow private semaphores

=head3 Allow passing an array of values

=head1 BUGS

semop(3) and semop(3p) man pages both indicate that C<errno> should be set to
C<EAGAIN> if the call would block and C<IPC_NOWAIT> is used, yet in my tests
under Linux C<errno> was set to C<EWOULDBLOCK>. See C<example.pl> and
C<example2.pl> for examples of paranoiac error checking. YMMV.

Please report bugs to C<tguyot@gmail.com>.

=head1 SEE ALSO

L<IPC::Semaphore> - The module this is based on.

The code repository is mirrored on
L<http://repo.or.cz/w/IPC-Semaphore-Concurrency.git>

CLI tools for controlling semaphores:

ipcs(1), especially ipcs -s for listing all semaphores

ipcrm(1), for removing semaphores by ID (-s) or KEY (-S)

=head1 AUTHOR

Thomas Guyot-Sionnest <tguyot@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2014 Thomas Guyot-Sionnest <tguyot@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
