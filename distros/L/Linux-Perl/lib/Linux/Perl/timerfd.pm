package Linux::Perl::timerfd;

=encoding utf-8

=head1 NAME

Linux::Perl::timerfd

=head1 SYNOPSIS

    my $tfd = Linux::Perl::timerfd->new(
        clockid => 'REALTIME',
        flags => [ 'NONBLOCK', 'CLOEXEC' ],
    );

    #or, e.g., Linux::Perl::timerfd::x86_64

    my $fd = $tfd->fileno();

    ($old_interval, $old_value) = $tfd->settime(
        interval => $interval_seconds,
        value    => $value_seconds,
        flags    => [ 'ABSTIME', 'CANCEL_ON_SET' ],
    );

    my ($interval, $value) = $tfd->gettime();

    $tfd->set_ticks(12);

    my $read = $tfd->read();

=head1 DESCRIPTION

This is an interface to the C<timerfd_*> family of system calls.

This class inherits from L<Linux::Perl::Base::TimerEventFD>.

=cut

use strict;
use warnings;

use parent 'Linux::Perl::Base::TimerEventFD';

use Call::Context;

use Linux::Perl;
use Linux::Perl::Endian;
use Linux::Perl::ParseFlags;
use Linux::Perl::TimeSpec;

use constant {
    _clock_REALTIME  => 0,
    _clock_MONOTONIC => 1,
    _clock_BOOTTIME  => 7,
    _clock_REALTIME_ALARM => 8,
    _clock_BOOTTIME_ALARM => 9,

    _ENOTTY => 25,  #constant for Linux?
};

#----------------------------------------------------------------------

=head1 METHODS

=head2 I<CLASS>->new( %OPTS )

%OPTS is:

=over

=item * C<clockid> - One of: C<REALTIME>, C<MONOTONIC>, C<BOOTTIME>,
C<REALTIME_ALARM>, or C<BOOTTIME_ALARM>. Not all kernel versions support
all of these; check C<man 2 timerfd_create> for your system.

=item * C<flags> - Optional, an array reference of any or all of:
C<NONBLOCK>, C<CLOEXEC>.

This follows the same practice as L<Linux::Perl::eventfd> regarding
CLOEXEC and C<$^F>.

=back

=cut

sub new {
    my ($class, %opts) = @_;

    my $clockid_str = $opts{'clockid'} || die 'Need “clockid”!';
    my $clockid = $class->can("_clock_$clockid_str");
    if (!$clockid) {
        die "Unknown “clockid”: “$clockid_str”!";
    }

    $clockid = $clockid->();

    my $flags = Linux::Perl::ParseFlags::parse( $class, $opts{'flags'} );

    my $arch_module = $class->can('NR_timerfd_create') && $class;
    $arch_module ||= do {
        require Linux::Perl::ArchLoader;
        Linux::Perl::ArchLoader::get_arch_module($class);
    };

    my $fd = Linux::Perl::call( $arch_module->NR_timerfd_create(), 0 + $clockid, $flags );

    #Force CLOEXEC if the flag was given.
    local $^F = 0 if $flags & $arch_module->_flag_CLOEXEC();

    open my $fh, '+<&=' . $fd;

    return bless [$fh], $arch_module;
}

#----------------------------------------------------------------------

=head2 $OBJ = I<OBJ>->settime( %OPTS )

=head2 ($old_interval, $old_value) = I<OBJ>->settime( %OPTS )

See C<man 2 timerfd_settime> for details about what this does.

%OPTS is:

=over

=item * C<value> - in seconds.

=item * C<interval> - in seconds. Must be falsy if C<value> is falsy.
(Rationale: C<timerfd_settime> will ignore C<interval> if C<value>
is zero. This seems unintuitive, so we avoid that situation
altogether.)

=item * C<flags> - Optional, arrayref. Accepted values are
C<ABSTIME> and C<CANCEL_ON_SET>. Your kernel may not support
all of these; check C<man 2 timerfd_settime> for details.

=back

In scalar context this returns the object. This facilitates easy
setting of the value on instantiation.

In list context it returns the previous interval and value.

=cut

sub settime {
    my ($self, %opts) = @_;

    my $flags = Linux::Perl::ParseFlags::parse(
        'Linux::Perl::timerfd::_set_flags',
        $opts{'flags'},
    );

    if (!$opts{'value'}) {
        if ($opts{'interval'}) {
            die "“interval” is ignored if “value” is 0.";
        }

        $opts{'value'} = 0;
    }

    $opts{'interval'} ||= 0;

    my $int_packed = Linux::Perl::TimeSpec::from_float( $opts{'interval'} || 0 );
    my $val_packed = Linux::Perl::TimeSpec::from_float( $opts{'value'} || 0 );

    my $new_packed = $int_packed . $val_packed;
    my $old_packed = ("\0") x length $new_packed;

    Linux::Perl::call( $self->NR_timerfd_settime(), 0 + $self->fileno(), 0 + $flags, $new_packed, $old_packed );

    return wantarray ? _parse_itimerspec($old_packed) : $self;
}

#----------------------------------------------------------------------

=head2 ($old_interval, $old_value) = I<OBJ>->gettime()

Returns the old C<interval> and C<value>, in seconds.

=cut

sub gettime {
    my ($self) = @_;

    Call::Context::must_be_list();

    my $packed = ( Linux::Perl::TimeSpec::from_float(0) ) x 2;

    Linux::Perl::call( $self->NR_timerfd_gettime(), 0 + $self->fileno(), $packed );

    return _parse_itimerspec($packed);
}

#----------------------------------------------------------------------

=head2 my $ok_yn = I<OBJ>->set_ticks( $NUM_TICKS )

See C<man 2 timerfd_create> (look for C<TFD_IOC_SET_TICKS>) for details
on what this does.

This returns truthy if the operation succeeded and falsy if
the system does not support this operation. (Any other failure
will prompt an exception to be thrown.)

=cut

# man 2 ioctl_list
use constant _TFD_IOC_SET_TICKS => 0x40085400;

sub set_ticks {
    my ($self, $num_ticks) = @_;

    my $buf = "\0" x 8;

    if ($self->_PERL_CAN_64BIT()) {
        $buf = pack 'Q', $num_ticks;
    }
    elsif (Linux::Perl::Endian::SYSTEM_IS_BIG_ENDIAN) {
        $buf = ("\0" x 4) . pack('N', $num_ticks);
    }
    else {
        $buf = pack('V', $num_ticks) . ("\0" x 4);
    }

    local $!;
    return 1 if ioctl( $self->[0], _TFD_IOC_SET_TICKS(), $buf );

    return !1 if $! == _ENOTTY();   #falsy

    die "ioctl($self->[0][0], TFD_IOC_SET_TICKS): $!";
}

#----------------------------------------------------------------------

=head2 $expirations = I<OBJ>->read()

See C<man 2 timerfd_create> for details on what this returns.
Sets C<$!> and returns undef on error.

=cut

*read = __PACKAGE__->can('_read');

#----------------------------------------------------------------------

sub _parse_itimerspec {
    my ($packed) = @_;

    my $tslen = length($packed) / 2;
    my ($int, $val) = unpack "a${tslen}a${tslen}", $packed;
    $_ = Linux::Perl::TimeSpec::to_float($_) for ($int, $val);

    return ($int, $val);
}

#----------------------------------------------------------------------

package Linux::Perl::timerfd::_set_flags;

use constant {
    _flag_ABSTIME => 1,
    _flag_CANCEL_ON_SET => 2,
};

1;
