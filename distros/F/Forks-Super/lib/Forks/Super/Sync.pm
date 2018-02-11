#
# portable synchronization objects to coordinate actions
# between parent and child
#

package Forks::Super::Sync;
use strict;
use warnings;
use Carp;

our $VERSION = '0.93';
our $SYNC_PARTNER_GONE = 3.0;

sub new {
    my ($pkg, %args) = @_;
    my $implementation_arg = $args{implementation} ||
      $ENV{"FORKS_SUPER_SYNC_IMPL"} || '';
    my $count = $args{count} || 1;
    my @initial = ('N') x $count;
    if ($args{initial}) {
	if (ref $args{initial} eq 'ARRAY') {
	    @initial = @{$args{initial}};
	} elsif (@initial == 1) {
	    @initial = split //, $initial[0];
	}
    }
    my $parent = $$;
    my $self;

    no warnings 'once';
    foreach my $impl ($implementation_arg,
		      @Forks::Super::SysInfo::SYNC_IMPLS,
		      qw[Semaphlock]) {

	next unless $impl;
	my $implementation = $impl;  # modifiable copy

	if ($implementation eq 'Win32') {

	    $self = eval {
		require Forks::Super::Sync::Win32;
		Forks::Super::Sync::Win32->new($count, @initial);
	    };
	    carp $@ if $@;

	} elsif ($implementation eq 'Win32::Mutex' ||
		 $implementation eq 'Win32Mutex') {

	    $self = eval {
		require Forks::Super::Sync::Win32Mutex;
		Forks::Super::Sync::Win32Mutex->new($count, @initial);
	    };
	    carp $@ if $@;
	    $implementation = 'Win32Mutex';

	} elsif ($implementation eq 'Semaphore' ||
		 $implementation eq 'IPCSemaphore') {

	    $self = eval {
                require Forks::Super::Sync::IPCSemaphore;
                Forks::Super::Sync::IPCSemaphore->new($count,@initial);
            };
	    carp $@ if $@;
	    $implementation = 'Semaphore';

	} elsif ($implementation eq 'Semaphlock') {

	    $self = eval {
		require Forks::Super::Sync::Semaphlock;
		Forks::Super::Sync::Semaphlock->new($count,@initial);
	    };
	    carp $@ if $@;

	} else {
	    carp "unrecognized Forks::Super::Sync implementation $impl";
	}

	if ($self) {
	    $self->{ppid} = $$;
	    $self->{implementation} = $implementation;
	}
	last if $self && ref($self) =~ /Forks::Super::Sync/;
    }

    $self->_prepare_initial_sync;
    return $self;
}

sub _prepare_initial_sync {

    # the parent and/or child process may have some initialization to
    # perform, and needs a way to guarantee that the other process
    # will not affect some shared resource until that initialization is
    # complete. One way to accomplish that is with two pairs of pipes
    # so that (1) a process can tell the other process when it is
    # done with the initialization and (2) a process can wait until the
    # other process is done with its initialization.

    my $self = shift;
    pipe my $r1, my $w1;
    pipe my $r2, my $w2;
    $self->{pipes} = { P => [ $r1, $w2 ], C => [ $r2, $w1 ] };
    return;
}

sub _perform_initial_sync {
    my ($self) = @_;
    my $label = $$ == $self->{ppid} ? 'P' : 'C';
    my ($reader, $writer) = @{$self->{pipes}{$label}};

    print {$writer} "\n";
    close $writer;

    readline($reader);
    close $reader;
}

sub acquire {
    croak "not implemented in baseclass\n";
}

sub release {
    croak "not implemented in baseclass\n";
}

sub acquireAndRelease {
    my ($self, $resource, $timeout) = @_;
    if (defined($timeout) && $timeout ne '') {
	my $z1 = $self->acquire($resource,$timeout);
	if ($z1) {
	    my $z2 = $self->release($resource);
	    if (!$z2) {
		$! = 502;
	    }
	    return $z2;
	} else {
	    $! = 501;
	    return $z1;
	}
    }

    my $z1 = $self->acquire($resource);
    if ($z1) {
	my $z2 = $self->release($resource);
	if (!$z2) {
	    $! = 504;
	}
	return $z2;
    } else {
	$! = 503;
	return $z1;
    }
}

sub releaseAfterFork {
    my ($self,$childPid) = @_;
    $self->_releaseAfterFork($childPid);
    $self->_perform_initial_sync;
}

sub _releaseAfterFork {
    my ($self) = @_;
    my $label = $$ == $self->{ppid} ? 'P' : 'C';
    for my $n (0 .. $#{$self->{initial}}) {
	if ($self->{initial}[$n] ne 'B' && $self->{initial}[$n] ne $label) {
	    $self->release($n);
	}
    }
    return;
}

sub acquired {
    my $self = shift;
    my @acq = map { !!$self->{acquired}[$_] || 0 } 0 .. $self->{count}-1;
    return wantarray ? @acq : join '', @acq;
}

sub remove {
}

sub releaseAll {
    my $self = shift;
    $self->release($_) for 0 .. $self->{count}-1;
    close $_ for @{$self->{pipes}{P}}, @{$self->{pipes}{C}};
}

#############################################################################

1;

__END__

=head1 NAME

Forks::Super::Sync - portable interprocess synchronization object

=head1 VERSION

0.93

=head1 SYNOPSIS

    $locks = Forks::Super::Sync->new(count => 4, initial => ['P','C','N','N'])
    $pid = fork(); $locks->releaseAfterFork();
    if ($pid == 0) { # child
        $locks->acquire(0);
        $locks->release(1);
        $locks->acquireAndRelease(2, 0.5);
    } else {         # parent
        $locks->acquire(2);
        $locks->release(0);
        $locks->acquire(1, 0.0);
        $locks->release(2);
    }

=head1 DESCRIPTION

C<Forks::Super::Sync> provides synchronization objects that can be
shared by parent and child processes and used to coordinate action
between the parent and child.

For example, a parent process might provide input to a child process,
but the child process should wait until input is ready before beginning
to process that input. One way to solve this problem would be for the
parent to acquire some shared resource either before or immediately
after the child process is spawned. When the parent process is ready to
send input to the child, the parent releases the shared resource.
The child process waits until the shared resource is available before
carrying out its function.

=head1 SUBROUTINES/METHODS

=head2 $sync = Forks::Super::Sync->new( %args )

Constructs a new synchronization object. Recognized key-value pairs in
C<%args> are:

=over 4

=item count => $count

Specifies the number of separate resources this synchronization object
will manage. [default: 1] The L<"acquire"> and L<"release"> methods will
expect an argument between 0 and C<$count-1>.

=item initial => [ @initial ]

=item initial => $string

A list of C<$count> (see L<"count">, above) items, or a string with C<$count>
characters, that specifies which process will possess access to a shared
resource after a fork. Each list element or character is expected to be one of:

=over 4

=item C<P> - after fork, the parent process should have a lock on the resource

=item C<C> - after fork, the child process should have a lock on the resource

=item C<N> - after fork, neither process should have a lock on the resource.
The first process to call L<"acquire"> on the resource will get a lock
on that resource.

=back

Both of these examples construct a new synchronization object with 3 different
locks. After fork, control of the first resource (resource #0) will be held
by the parent process, the second resource will be held by the child process,
and neither process will hold the third resource.

    $sync = Forks::Super::Sync->new(count => 3, initial => [ 'P', 'C', 'N' ]);
    $sync = Forks::Super::Sync->new(count => 3, initial => 'PCN');

[Default is for all resources to be unlocked and available after fork.]

=item implementation => $implementation

Specifies an implementation of L<Forks::Super::Sync|Forks::Super::Sync> to
use to synchronize actions between a parent and child process. 
Recognized implementations are

=over 4

=item Semaphlock

Uses C<Forks::Super::Sync::Semaphlock>, an implementation that uses
Perl's L<flock|perlfunc/flock> function and advisory file locking. This
is implemented just about everywhere, but it also ties up precious 
filehandle resources.

=item Win32

Uses L<Win32::Semaphore|Win32::Semaphore> objects. As you might expect, 
only works on Windows (including Cygwin).

=item Win32Mutex / Win32::Mutex

Another Windows/Cygwin specific synchronization implementation,
based on L<Win32::Mutex|Win32::Mutex> objects.

=item IPCSemaphore

Uses L<IPC::Semaphore|IPC::Semaphore> objects. Works on most
Unix-y systems (though not Cygwin, for whatever reason).

=back

[Default is C<Forks::Super::Sync::Semaphlock>, which ought to work just about
anywhere.]

=back


Implementations of C<Forks::Super::Sync> must include

=head2 $result = $sync->acquire($n)

=head2 $result = $sync->acquire($n,$timeout)

Acquire exclusive access to shared resource C<$n>. If a C<$timeout> argument
is provided, the function waits up to C<$timeout> seconds to acquire the
resource, returning zero if the function times out before the resource is
acquired. If no C<$timeout> is specified, the subroutine waits indefinitely.

Returns 1 on success, 0 on failure to acquire the resource,
-1 if the sync object believes that the process calling C<acquire> for
the resource already possesses the resource,
C<"0 but true"> if the resource is available because the partner process
has quit unexpectedly, or C<undef> for invalid choices of C<$n>.
Note that some implementations may use values of C<$n> less than 
zero for internal use, so choices of C<$n> E<lt> 0 may or may not be 
valid values.

=head2 $result = $sync->release($n)

Releases shared resource C<$n>, allowing it to be L<acquire|"acquire">'d 
in another process. 
Returns 1 on success, or C<undef> if called on a resource that is not
currently possessed by the calling process.

=head2 $result = $sync->acquireAndRelease($n)

=head2 $result = $sync->acquireAndRelease($n, $timeout)

Acquires and releases a resource, with an optional timeout on
acquiring the resource. Not unlike calling

    $sync->acquire($n [,$timeout]) && $sync->release($n)

=head1 DISCLAIMER

Implementations use and abuse subsets of features of file locking
and semaphores for the narrow purposes of the 
L<Forks::Super|Forks::Super> distribution. It is probably not a
good idea to try to use or extend this module for other purposes.

=head1 SEE ALSO

L<Forks::Super|Forks::Super>

Various implementations based on L<flock|perlfunc/"flock">,
L<IPC::Semaphore|IPC::Semaphore>, L<Win32::Semaphore|Win32::Semaphore>,
or L<Win32::Mutex|Win32::Mutex>.

=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
