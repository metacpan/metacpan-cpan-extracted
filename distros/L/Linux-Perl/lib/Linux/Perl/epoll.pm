package Linux::Perl::epoll;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Linux::Perl::epoll

=head1 SYNOPSIS

    my $epl = Linux::Perl::epoll->new();

    $epl->add( $fh, events => ['IN', 'ET'] );

    my @events = $epl->wait(
        maxevents => 3,
        timeout => 2,   #seconds
        sigmask => ['INT', 'TERM'], #optional
    );

    $epl->delete($fh);

=head1 DESCRIPTION

An interface to Linux’s “epoll” feature.

Note that older kernel versions may not support all of the functionality
documented here. Check your system’s epoll documentation (i.e.,
C<man 7 epoll> and the various system calls’ pages) for full details.

=cut

use parent 'Linux::Perl::Base';

use Linux::Perl;
use Linux::Perl::Constants::Fcntl;
use Linux::Perl::EasyPack;
use Linux::Perl::ParseFlags;
use Linux::Perl::SigSet;

*_flag_CLOEXEC = \*Linux::Perl::Constants::Fcntl::flag_CLOEXEC;

=head1 METHODS

=head2 I<CLASS>->new( %OPTS )

Creates a new epoll instance. %OPTS are:

=over

=item * C<flags> - Currently only C<CLOEXEC> is recognized.

=item * C<size> - Optional, and only useful on pre-2.6.8 kernels.
See C<main 2 epoll_create> for more details.

=back

=cut

sub new {
    my ($class, %opts) = @_;

    local ($!, $^E);

    my $arch_module = $class->_get_arch_module();

    my $flags = Linux::Perl::ParseFlags::parse( $class, $opts{'flags'} );

    my $call_name = 'NR_epoll_create';

    my $fd;

    if ($flags) {
        $call_name .= '1';

        $fd = Linux::Perl::call( $arch_module->$call_name(), 0 + $flags );
    }
    else {
        $opts{'size'} ||= 1;

        $fd = Linux::Perl::call( $arch_module->$call_name(), 0 + $opts{'size'} );
    }

    # Force the CLOEXEC behavior that Perl imposes on its file handles
    # unless the CLOEXEC flag was given explicitly.
    my $fh;

    if ( !($flags & _flag_CLOEXEC()) ) {
        open $fh, '+<&=' . $fd;
    }

    # NB: tests access the filehandle directly.
    return bless [$fd, $fh], $arch_module;
}

sub DESTROY {
    my ($self) = @_;

    # Create a Perl filehandle for the file descriptor so
    # that we get a close() when the filehandle object goes away.
    $self->[1] || do {
        local $^F = 1 + $self->[0];
        open my $temp_fh, '+<&=' . $self->[0];
    };

    return;
}

my ($epoll_event_keys_ar, $epoll_event_pack);

BEGIN {
    my $arch_is_64bit = (8 == length pack 'L!');

    my @_epoll_event_src = (
        events => 'L',  #uint32_t
        (
            $arch_is_64bit
                ? ( data => 'Q' )
                : (
                    q<> => 'xxxx',
                    data   => 'L!',  #uint64_t
                ),
        ),
    );

    ($epoll_event_keys_ar, $epoll_event_pack) = Linux::Perl::EasyPack::split_pack_list(@_epoll_event_src);
}

#----------------------------------------------------------------------

=head2 I<CLASS>->EVENT_NUMBER()

Returns a (constant) hash reference that cross-references event names
and their numbers. This is useful, e.g., for parsing events from the return
of C<wait()>.

The recognized event names are C<IN>, C<OUT>, C<RDHUP>, C<PRI>, C<ERR>,
and C<HUP>.

=cut

use constant {
    EVENT_NUMBER => {
        IN => 1,
        OUT => 4,
        RDHUP => 0x2000,
        PRI => 2,
        ERR => 8,
        HUP => 16,
    },

    _EPOLL_CTL_ADD => 1,
    _EPOLL_CTL_DEL => 2,
    _EPOLL_CTL_MOD => 3,

    _EVENT_FLAGS => {
        ET => (1 << 31),
        ONESHOT => (1 << 30),
        WAKEUP => (1 << 29),
        EXCLUSIVE => (1 << 28),
    },
};

#----------------------------------------------------------------------

=head2 I<OBJ>->add( $FD_OR_FH, %OPTS )

Adds a listener to the epoll instance. $FD_OR_FH is either a
Perl filehandle or a file descriptor number. %OPTS are:

=over

=item * C<events> - An array reference of events/switches. Each member
is either a key from C<EVENT_NUMBER()> or one of the following
switches: C<ET>, C<ONESHOT>, C<WAKEUP>, C<EXCLUSIVE>. Your kernel
may not support all of those; check C<man 2 epoll_ctl> for details.

=item * C<data> - Optional, an arbitrary number to store with the file
descriptor. This defaults to the file descriptor because this is the obvious
way to correlate an event with its filehandle; however, you can set your own
numeric value here if you’d rather.

=back

=cut

sub add {
    my ($self, $fd_or_fh, @opts_kv) = @_;

    return $self->_add_or_modify( _EPOLL_CTL_ADD(), $fd_or_fh, @opts_kv );
}

=head2 I<OBJ>->modify( $FD_OR_FH, %OPTS )

Same arguments as C<add()>; use this to update an existing epoll listener.

=cut

sub modify {
    my ($self, $fd_or_fh, @opts_kv) = @_;

    return $self->_add_or_modify( _EPOLL_CTL_MOD(), $fd_or_fh, @opts_kv );
}

sub _opts_to_event {
    my ($opts_hr) = @_;

    if (!$opts_hr->{'events'} || !@{ $opts_hr->{'events'} }) {
        die 'Need events!';
    }

    my $events = 0;
    for my $evtname ( @{ $opts_hr->{'events'} } ) {
        $events |= EVENT_NUMBER()->{$evtname} || _EVENT_FLAGS()->{$evtname} || do {
            die "Unknown event '$evtname'";
        };
    }

    return pack $epoll_event_pack, $events, $opts_hr->{'data'};
}

sub _add_or_modify {
    my ($self, $op, $fd_or_fh, %opts) = @_;

    my $fd = ref($fd_or_fh) ? fileno($fd_or_fh) : $fd_or_fh;

    if (!defined $opts{'data'}) {
        $opts{'data'} = $fd;
    }

    my $event_packed = _opts_to_event(\%opts);

    Linux::Perl::call(
        $self->NR_epoll_ctl(),
        0 + $self->[0],
        0 + $op,
        0 + $fd,
        $event_packed,
    );

    return $self;
}

#----------------------------------------------------------------------

=head2 I<OBJ>->delete( $FD_OR_FH )

Removes an epoll listener.

=cut

sub delete {
    my ($self, $fd_or_fh) = @_;

    my $fd = ref($fd_or_fh) ? fileno($fd_or_fh) : $fd_or_fh;

    Linux::Perl::call(
        $self->NR_epoll_ctl(),
        0 + $self->[0],
        0 + _EPOLL_CTL_DEL(),
        0 + $fd,
        (pack $epoll_event_pack),   #accommodate pre-2.6.9 kernels
    );

    return $self;
}

#----------------------------------------------------------------------

=head2 @events = I<OBJ>->wait( %OPTS )

Waits for one or more events on the epoll. %OPTS are:

=over

=item * C<maxevents> - The number of events to listen for.

=item * C<timeout> - in seconds

=item * C<sigmask> - Optional, an array of signals to block as part of
this function call. Give signals either as names (e.g., C<INT>) or as numbers.  See C<man 2 epoll_pwait> for why you might want to do this.  Also see
L<Linux::Perl::sigprocmask> for an easy, light way to block signals.

=back

The return is a list of key-value pairs. Each pair is:

=over

=item * The C<data> number given in C<add()>—or, if you didn’t
set a custom C<data> value, the file descriptor associated with the event.

=item * A number that corresponds to the C<events> array given in C<add()>,
but to optimize performance this is returned as a single number. Check
for specific events by iterating through the C<EVENT_NUMBER()> hash
reference.

=back

You can generally assign this list into a hash for easy parsing, as long
as you do not specify non-unique custom C<data> values.

=cut

sub wait {
    my ($self, %opts) = @_;

    my $sigmask;

    my $call_name = 'NR_epoll_';
    if ($opts{'sigmask'}) {
        $call_name .= 'pwait';
        $sigmask = Linux::Perl::SigSet::from_list( @{$opts{'sigmask'}} );
    }
    else {
        $call_name .= 'wait';
    }

    my $blank_event = pack $epoll_event_pack;
    my $buf = $blank_event x $opts{'maxevents'};

    my $timeout = int(1000 * $opts{'timeout'});

    my $count = Linux::Perl::call(
        $self->$call_name(),
        0 + $self->[0],
        $buf,
        0 + $opts{'maxevents'},
        0 + $timeout,
        ( (defined($sigmask) && length($sigmask))
            ? ( $sigmask, length $sigmask )
            : (),
        ),
    );

    my @events_kv;
    for (1 .. $count) {
        my ($events_num, $data) = unpack( $epoll_event_pack, substr( $buf, 0, length($blank_event), q<> ) );

        push @events_kv, $data => $events_num;
    }

    return @events_kv;
}

1;
