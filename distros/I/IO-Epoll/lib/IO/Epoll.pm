package IO::Epoll;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;
use POSIX ();

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use IO::Epoll ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'default' => [ qw(
	EPOLLERR
	EPOLLET
	EPOLLHUP
	EPOLLIN
	EPOLLMSG
	EPOLLOUT
	EPOLLPRI
	EPOLLRDBAND
	EPOLLRDNORM
	EPOLLWRBAND
	EPOLLWRNORM
	EPOLL_CTL_ADD
	EPOLL_CTL_DEL
	EPOLL_CTL_MOD
        epoll_create
        epoll_ctl
        epoll_wait
        epoll_pwait
) ],
                     'compat' => [ qw(
        POLLIN
        POLLOUT
        POLLERR
        POLLHUP
        POLLNVAL
        POLLPRI
        POLLRDNORM
        POLLWRNORM
        POLLRDBAND
        POLLWRBAND
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'default'} },
                   @{ $EXPORT_TAGS{'compat'}  } );

our @EXPORT = qw(
	EPOLLERR
	EPOLLET
	EPOLLHUP
	EPOLLIN
	EPOLLMSG
	EPOLLOUT
	EPOLLPRI
	EPOLLRDBAND
	EPOLLRDNORM
	EPOLLWRBAND
	EPOLLWRNORM
	EPOLL_CTL_ADD
	EPOLL_CTL_DEL
	EPOLL_CTL_MOD
        epoll_create
        epoll_ctl
        epoll_wait
        epoll_pwait
);

our $VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&IO::Epoll::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('IO::Epoll', $VERSION);

# Preloaded methods go here.

# IO::Poll Compatibility API

# [0] maps fd's to requested masks
# [1] maps fd's to returned  masks
# [2] maps fd's to handles
# [3] is the epoll fd
# [4] is the signal mask, if used. If present will use epoll_pwait() instead of epoll_wait()

sub new
{
    my $package = shift;
    my $self = bless [ {}, {}, {}, undef, undef ] => $package;

    $self->[3] = epoll_create(15);
    if ($self->[3] < 0) {
        if ($! =~ /not implemented/) {
            die "You need at least Linux 2.5.44 to use IO::Epoll";
        }
        else {
            die "epoll_create: $!\n";
        }
    }
    return $self;
}

sub mask
{
    my $self = shift;
    my $io   = shift;
    my $fd   = fileno $io;

    if (@_) {
        my $mask = shift;

        if ($mask) {
            my $combined_mask = $mask;
            my $op = &EPOLL_CTL_ADD;
            if ( exists $self->[0]{$fd} ) {
                $combined_mask |= $_ foreach values %{ $self->[0]{$fd} };
                $op = &EPOLL_CTL_MOD;
            }
            return if epoll_ctl($self->[3], $op, $fd, $combined_mask) < 0;
            $self->[0]{$fd}{$io} = $mask;
            $self->[2]{$io} = $io;
        }
        else {
            delete $self->[0]{$fd}{$io};
            delete $self->[2]{$io};

            my $op = &EPOLL_CTL_DEL;
            my $combined_mask = 0;
            if ( %{ $self->[0]{$fd} } ) {
                $combined_mask |= $_ foreach values %{ $self->[0]{$fd} };
                $op = &EPOLL_CTL_MOD;
            }
            else {
                delete $self->[1]{$fd};
                delete $self->[0]{$fd};
            }
            return if epoll_ctl($self->[3], $op, $fd, $combined_mask) < 0;
        }
    }

    return unless exists $self->[0]{$fd} and exists $self->[0]{$fd}{$io};
    return $self->[0]{$fd}{$io};
}

sub poll
{
    my ($self, $timeout) = @_;

    $self->[1] = {};

    # Set max events to half the number of descriptors, to a minumum of 10
    my $maxevents = int ((values %{ $self->[0] }) / 2);
    $maxevents = 10 if $maxevents < 10;

    my $msec = defined $timeout ? $timeout * 1000 : -1;

    my $ret = epoll_pwait($self->[3], $maxevents, $msec, $self->[4]);
    return -1 unless defined $ret;

    foreach my $event (@$ret) {
        $self->[1]{$event->[0]} = $event->[1];
    }
    return scalar(@$ret);
}

sub events
{
    my $self = shift;
    my $io   = shift;
    my $fd   = fileno $io;

    if ( exists $self->[1]{$fd} && exists $self->[0]{$fd}{$io} ) {
        return $self->[1]{$fd} & ($self->[0]{$fd}{$io} |
                                  &EPOLLHUP | &EPOLLERR );
    } else {
        return 0;
    }
}

sub remove
{
    my $self = shift;
    my $io   = shift;
    $self->mask($io, 0);
}

sub handles
{
    my $self = shift;
    return values %{ $self->[2] } unless @_;

    my $events = shift || 0;
    my($fd, $ev, $io, $mask);
    my @handles = ();

    while( ($fd, $ev) = each %{ $self->[1] } ) {
        while ( ($io, $mask) = each %{ $self->[0]{$fd} } ) {
            $mask |= &EPOLLHUP | &EPOLLERR;  # must allow these
            push @handles, $self->[2]{$io} if ($ev & $mask) & $events;
        }
    }
    return @handles;
}

# Close the epoll handle when object destroyed
sub DESTROY
{
    my $self = shift;

    POSIX::close($self->[3]);
}

# IO::Ppoll API extension

sub sigmask
{
    my $self = shift;

    if( my ( $newmask ) = @_ ) {
        $self->[4] = $newmask;
    }
    else {
        $self->[4] ||= POSIX::SigSet->new();
        return $self->[4];
    }
}

sub sigmask_add
{
    my $self = shift;
    my @signals = @_;

    my $sigmask = $self->sigmask;
    $sigmask->addset( $_ ) foreach @signals;
}

sub sigmask_del
{
    my $self = shift;
    my @signals = @_;

    my $sigmask = $self->sigmask;
    $sigmask->delset( $_ ) foreach @signals;
}

sub sigmask_ismember
{
    my $self = shift;
    my ( $signal ) = @_;

    return $self->sigmask->ismember( $signal );
}

# IO::Poll compatibility constants

sub POLLNVAL    () { 0            };
sub POLLIN      () { &EPOLLIN     };
sub POLLOUT     () { &EPOLLOUT    };
sub POLLERR     () { &EPOLLERR    };
sub POLLHUP     () { &EPOLLHUP    };
sub POLLPRI     () { &EPOLLPRI    };
sub POLLRDNORM  () { &EPOLLRDNORM };
sub POLLWRNORM  () { &EPOLLWRNORM };
sub POLLRDBAND  () { &EPOLLRDBAND };
sub POLLWRBAND  () { &EPOLLWRBAND };

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

IO::Epoll - Scalable IO Multiplexing for Linux 2.5.44 and higher

=head1 SYNOPSIS

    # Low level interface
    use IO::Epoll;

    $epfd = epoll_create(10);

    epoll_ctl($epfd, EPOLL_CTL_ADD, fileno STDIN, EPOLLIN) >= 0
        || die "epoll_ctl: $!\n";
    epoll_ctl($epfd, ...);

    $events = epoll_wait($epfd, 10, 1000); # Max 10 events returned, 1s timeout

    # High level IO::Poll emulation layer
    use IO::EPoll qw(:compat);

    $poll = new IO::Epoll;

    $poll->mask($input_handle => POLLIN);
    $poll->mask($output_handle => POLLOUT);

    $poll->poll($timeout);

    $ev = $poll->events($input);

=head1 DESCRIPTION

The C<epoll(4)> subsystem is a new, (currently) Linux-specific variant of
C<poll(2)>.  It is designed to offer O(1) scalability over large numbers of
watched file descriptors.  You will need at least version 2.5.44 of Linux
to use this module, and you might need to upgrade your C library.

The C<epoll(2)> API comprises four system calls: C<epoll_create(2)>,
C<epoll_ctl(2)>, C<epoll_wait(2)> and C<epoll_pwait(2)>.  C<IO::Epoll>
provides a low-level API which closely matches the underlying system calls.
It also provides a higher-level layer designed to emulate the behavior of
C<IO::Poll> and C<IO::Ppoll>.

=head1 LOW-LEVEL API

=over 4

=head2 epoll_create

Create a new C<epoll> file descriptor by requesting the kernel
allocate an event backing store dimensioned for C<size> descriptors.
The size is not the maximum size of the backing store but just a hint
to the kernel about how to dimension internal structures.  The
returned file descriptor will be used for all the subsequent calls
to the C<epoll> interface.  The file descriptor returned by
C<epoll_create> must be closed by using C<POSIX::close>.

    $epfd = epoll_create(15);
    ...
    POSIX::close($epfd);

When successful, C<epoll_create> returns a positive integer
identifying the descriptor.  When an error occurs, C<epoll_create>
returns -1 and errno is set appropriately.

=head2 epoll_ctl

Control an C<epoll> descriptor, $epfd, by requesting the operation op be
performed on the target file descriptor, fd.

  $ret = epoll_ctl($epfd, $op, $fd, $eventmask)

C<$epfd> is an C<epoll> descriptor returned from C<epoll_create>.

C<$op> is one of C<EPOLL_CTL_ADD>, C<EPOLL_CTL_MOD> or C<EPOLL_CTL_DEL>.

C<$fd> is the file desciptor to be watched.

C<$eventmask> is a bitmask of events defined by C<EPOLLIN>, C<EPOLLOUT>, etc.

When successful, C<epoll_ctl> returns 0.  When an error occurs,
C<epoll_ctl> returns -1 and errno is set appropriately.

=head2 epoll_wait

Wait for events on the C<epoll> file descriptor C<$epfd>.

  $ret = epoll_wait($epfd, $maxevents, $timeout)

C<$epfd> is an C<epoll> descriptor returned from C<epoll_create>.

C<$maxevents> is an integer specifying the maximum number of events to
be returned.

C<$timeout> is a timeout, in milliseconds

When successful, C<epoll_wait> returns a reference to an array of
events.  Each event is a two element array, the first element being
the file descriptor which triggered the event, and the second is the
mask of event types triggered.  For example, if C<epoll_wait> returned the
following data structure:

    [
      [ 0, EPOLLIN ],
      [ 6, EPOLLOUT | EPOLLIN ]
    ]

then file descriptor 0 would be ready for reading, and fd 4 would be
ready for both reading and writing.

On error, C<epoll_wait> returns undef and sets C<errno> appropriately.

=head2 epoll_pwait

Wait for events on the C<epoll> file descriptor C<$epfd>.

  $ret = epoll_pwait($epfd, $maxevents, $timeout, $sigmask)

Identical to C<epoll_wait>, except that the kernel will atomically swap the
current signal mask for the process to that supplied in C<$sigmask>, wait for
events, then restore it to what it was originally. The C<$sigmask> parameter
should be undef, or an instance of C<POSIX::SigSet>.

=back

=head1 HIGH LEVEL API

IO::Epoll provides an object oriented API designed to be a drop-in
replacement for IO::Poll.  See the documentation for that module for
more information.

=head1 METHODS

=over 4

=item mask ( IO [, EVENT_MASK ] )

If EVENT_MASK is given, then, if EVENT_MASK is non-zero, IO is added to the
list of file descriptors and the next call to poll will check for
any event specified in EVENT_MASK. If EVENT_MASK is zero then IO will be
removed from the list of file descriptors.

If EVENT_MASK is not given then the return value will be the current
event mask value for IO.

=item poll ( [ TIMEOUT ] )

Call the system level poll routine. If TIMEOUT is not specified then the
call will block. Returns the number of handles which had events
happen, or -1 on error. TIMEOUT is in seconds and may be fractional.

=item events ( IO )

Returns the event mask which represents the events that happend on IO
during the last call to C<poll>.

=item remove ( IO )

Remove IO from the list of file descriptors for the next poll.

=item handles( [ EVENT_MASK ] )

Returns a list of handles. If EVENT_MASK is not given then a list of all
handles known will be returned. If EVENT_MASK is given then a list
of handles will be returned which had one of the events specified by
EVENT_MASK happen during the last call ti C<poll>

=back

=head1 IO::Ppoll METHODS

IO::Epoll also provides methods compatible with IO::Ppoll. When any of these
methods are called, the IO::Epoll object switches up to IO::Ppoll-compatible
mode, and will use the C<epoll_pwait(2)> system call when the C<poll> method
is invoked.

=over 4

=item sigmask

Returns the C<POSIX::SigSet> object in which the signal mask is stored. Since
this is a reference to the object used in the call to C<epoll_pwait(2)>, any
modifications made to it will be reflected in the signal mask given to the
system call.

=item sigmask_add ( SIGNALS )

Adds the given signals to the signal mask. These signals will be blocked
during the C<poll> call.

=item sigmask_del ( SIGNALS )

Removes the given signals from the signal mask. These signals will not be
blocked during the C<poll> call, and may be delivered while C<poll> is
waiting.

=item sigmask_ismember ( SIGNAL )

Tests if the given signal is present in the signal mask.

=back


=head1 Exportable constants

Exported by default:

  EPOLLERR
  EPOLLET
  EPOLLHUP
  EPOLLIN
  EPOLLMSG
  EPOLLOUT
  EPOLLPRI
  EPOLLRDBAND
  EPOLLRDNORM
  EPOLLWRBAND
  EPOLLWRNORM
  EPOLL_CTL_ADD
  EPOLL_CTL_DEL
  EPOLL_CTL_MOD

Exported by the :compat tag:

  POLLNVAL
  POLLIN
  POLLOUT
  POLLERR
  POLLHUP
  POLLPRI
  POLLRDNORM
  POLLWRNORM
  POLLRDBAND
  POLLWRBAND

=head1 SEE ALSO

C<IO::Poll> C<IO::Select> C<IO::Ppoll> C<epoll(4)> C<epoll_create(2)>
C<epoll_ctl(2)> C<epoll_wait(2)> C<epoll_pwait(2)>

=head1 AUTHOR

Bruce J Keeler, E<lt>bruce@gridpoint.comE<gt>

=head1 CREDITS

The C<IO::Poll> compatibility code borrows heavily from the C<IO::Poll>
code itself, which was written by Graham Barr.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Bruce J. Keeler
Portions Copyright (C) 1997-8 Graham Barr <gbarr@pobox.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
