package Linux::Perl::mq;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Linux::Perl::mq - POSIX message queue

=head1 SYNOPSIS

    my $mq = Linux::Perl::mq->new(
        name => 'my_message_queue',
        flags => ['CREAT'],

        # Only needed for message creation:
        msgsize => 16,
        maxmsg => 5,
        mode => 0644,
    );

    $mq->send( msg => 'Hello, world!' );

    my $got_msg = $mq->receive( msgsize => 16 );

    $mq->blocking(0);   # sets non-blocking mode
    $mq->blocking();    # returns 0

    my $attrs_hr = $mq->getattr();

    # For select, epoll, or poll:
    my $fileno = $mq->fileno();

=cut

use parent 'Linux::Perl::Base';

use Linux::Perl;
use Linux::Perl::EasyPack;
use Linux::Perl::Constants::Fcntl;
use Linux::Perl::ParseFlags;
use Linux::Perl::TimeSpec;

*_flag_CLOEXEC = \*Linux::Perl::Constants::Fcntl::flag_CLOEXEC;
*_flag_NONBLOCK = \*Linux::Perl::Constants::Fcntl::flag_NONBLOCK;
*_flag_CREAT = \*Linux::Perl::Constants::Fcntl::flag_CREAT;
*_flag_EXCL = \*Linux::Perl::Constants::Fcntl::flag_EXCL;

use constant {
    _ENOENT => 2,
    _EAGAIN => 11,
    _ETIMEDOUT => 110,

    _name_length_max => 254,   # NAME_MAX - 1 (for the initial solidus)
};

my ($mq_attr_keys_ar, $mq_attr_pack);

BEGIN {
    ($mq_attr_keys_ar, $mq_attr_pack) = Linux::Perl::EasyPack::split_pack_list(
        flags => 'L!',
        maxmsg => 'L!',
        msgsize => 'L!',
        curmsgs => 'L!',
        q<>     => '(L!)4',
    );

    pop @$mq_attr_keys_ar;
}

#----------------------------------------------------------------------

=head1 METHODS

=head2 I<CLASS>->unlink( $NAME )

Returns truthy if a queue is removed or falsy if no queue
with the given $NAME exists.

Throws an exception on failure.

=cut

sub unlink {
    my ($class, $name) = @_;

    _validate_name($name);

    my $arch_module = $class->_get_arch_module();

    local @Linux::Perl::_TOLERATE_ERRNO = (_ENOENT());

    my $result = Linux::Perl::call(
        $arch_module->NR_mq_unlink(),
        $name,
    );

    return (-1 != $result);
}

#----------------------------------------------------------------------

=head2 I<CLASS>->new( %OPTS )

Creates a new read/write message queue object.

%OPTS are:

=over

=item * C<name>

=item * C<flags> - Any/all/none of: C<CLOEXEC>, C<NONBLOCK>,
C<CREAT>, C<EXCL>.

=item * C<mode> - Only relevant if the C<CREAT> flag is given.

=item * C<maxmsg> - Only relevant if the C<CREAT> flag is given.

=item * C<msgsize> - Only relevant if the C<CREAT> flag is given.

=back

=cut

sub new {
    my ($class, @opts_kv) = @_;

    return $class->_new(
        Linux::Perl::Constants::Fcntl::mode_RDWR(),
        @opts_kv,
    );
}

=head2 I<CLASS>->new_wronly( %OPTS )

Like C<new()>, but the queue handle is write-only.

=cut

sub new_wronly {
    my ($class, @opts_kv) = @_;

    return $class->_new(
        Linux::Perl::Constants::Fcntl::mode_WRONLY(),
        @opts_kv,
    );
}

=head2 I<CLASS>->new_rdonly( %OPTS )

Like C<new()>, but the queue handle is read-only.

=cut

sub new_rdonly {
    my ($class, @opts_kv) = @_;

    return $class->_new(
        Linux::Perl::Constants::Fcntl::mode_RDONLY(),
        @opts_kv,
    );
}

sub _new {
    my ($class, $flags, %opts) = @_;

    local ($!, $^E);

    my $arch_module = $class->_get_arch_module();

    _validate_name($opts{'name'});

    $flags |= Linux::Perl::ParseFlags::parse( $class, $opts{'flags'} );

    my @creat_args;

    if ($flags & _flag_CREAT()) {
        my $mode = $opts{'mode'};
        die 'Need mode!' if !defined $mode;

        # TODO: be consistent
        #die "Non-numeric mode: [$mode]" if tr<0-9><>c;
        #die "mode exceeds 0777: [$mode]" if $mode > 0777;

        my $maxmsg = $opts{'maxmsg'} or die 'Need nonzero maxmsg!';
        my $msgsize = $opts{'msgsize'} or die 'Need nonzero msgsize!';

        my $attr_pack = pack $mq_attr_pack, 0, $maxmsg, $msgsize, 0;

        push @creat_args, 0 + $mode, $attr_pack;
    }
    else {
        for my $opt ( qw( mode maxmsg msgsize ) ) {
            warn "no $opt flag; ignoring '$opt'" if defined $opts{$opt};
        }
    }

    my $mqd = Linux::Perl::call(
        $arch_module->NR_mq_open(),
        $opts{'name'},
        0 + $flags,
        @creat_args,
    );

    open my $mqfh, '+<&=', $mqd;

    return bless [ $mqd, $mqfh ], $arch_module;
}

#----------------------------------------------------------------------

=head2 I<OBJ>->fileno()

Returns the file descriptor number. This is useful, e.g., for use with
select, L<epoll|Linux::Perl::epoll>, or poll.

=cut

sub fileno { fileno $_[0][0] }

#----------------------------------------------------------------------

=head2 I<OBJ>->getattr()

Returns a hashref of attributes that corresponds to C<struct mq_attr>.
See C<man 3 mq_getattr> for details.

=cut

sub getattr {
    my ($self) = @_;

    # cf. uapi/linux/mqueue.h - there are 4 (undocumented!) longs
    # after the 4 documented ones.
    my $buf = pack $mq_attr_pack;

    Linux::Perl::call(
        $self->NR_mq_getsetattr(),
        0 + $self->[0],
        undef,
        $buf,
    );

    my %ret;
    @ret{ @$mq_attr_keys_ar } = unpack $mq_attr_pack, $buf;

    return \%ret;
}

#----------------------------------------------------------------------

=head2 I<OBJ>->blocking()

Imitates L<IO::Handle>’s method of the same name.
Returns a boolean that indicates whether the message queue handle
is blocking.

=head2 I<OBJ>->blocking( $BLOCKING_YN )

Sets the message queue handle as blocking or non-blocking.

=cut

sub blocking {
    my ($self, $turn_on_yn) = @_;

    if (!defined $turn_on_yn) {
        return !$self->getattr()->{'flags'};
    }

    my $flags = $turn_on_yn ? 0 : _flag_NONBLOCK();
    my $buf = pack $mq_attr_pack, $flags;

    Linux::Perl::call(
        $self->NR_mq_getsetattr(),
        0 + $self->[0],
        $buf,
        undef,
    );

    return $self;
}

sub _send_receive_prio_timeout {
    my ($opts_hr) = @_;

    my $timeout = Linux::Perl::TimeSpec::from_float($opts_hr->{'timeout'} || 0);

    my $prio = $opts_hr->{'prio'} || 0;

    return (0 + $prio, $timeout);
}

=head2 I<OBJ>->send( %OPTS )

Sends a message to the queue. An exception is thrown on failure,
e.g., if the queue cannot accommodate another message.

=over

=item * C<msg> - The message to send.

=item * C<prio> - Optional, the message priority. Defaults to 0
(highest priority).

=item * C<timeout> - Optional, in seconds. (Can be fractional.)

=back

=cut

sub send {
    my ($self, %opts) = @_;

    my $msg = $opts{'msg'};
    if (!defined $msg) {
        die "Need msg!";
    }

#    local @Linux::Perl::_TOLERATE_ERRNO = (
#        _EAGAIN(),
#        _ETIMEDOUT(),
#    );

    my $ret = Linux::Perl::call(
        $self->NR_mq_timedsend(),
        0 + $self->[0],
        $msg,
        length($msg),
        _send_receive_prio_timeout(\%opts),
    );

    return undef if $ret == -1;

    return 1;
}

=head2 I<OBJ>->receive( \$BUFFER, %OPTS )

Attempts to slurp a message from the queue.

$BUFFER is a pre-initialized buffer where the message will be stored.
It B<must> be at least as long as the message queue’s C<msgsize>.

%OPTS are:

=over

=item * C<prio> - Optional, the receive priority. Defaults to 0
(highest priority).

=item * C<timeout> - Optional, in seconds. (Can be fractional.)

=back

Returns the message length on success; if there is no message available,
undef is returned. Any other failure prompts an exception.

=cut

sub receive {
    my ($self, $buffer_sr, %opts) = @_;

    local @Linux::Perl::_TOLERATE_ERRNO = (
        _EAGAIN(),
        _ETIMEDOUT(),
    );

    my $len = Linux::Perl::call(
        $self->NR_mq_timedreceive(),
        0 + $self->[0],
        $$buffer_sr,
        length $$buffer_sr,
        _send_receive_prio_timeout(\%opts),
    );

    return( ($len != -1) ? $len : undef );
}

#----------------------------------------------------------------------

sub _validate_name {
    my ($name) = @_;

    if (!defined $name || !length $name) {
        die 'Need name!';
    }

    if (-1 != index($name, '/')) {
        die "name cannot contain a solidus (/)!";
    }

    if (-1 != index($name, "\0")) {
        die "name cannot contain a NUL byte!";
    }

    if ( length($name) > _name_length_max() ) {
        die sprintf("name ($name) exceeds the length limit (%d)!", _NAME_MAX());;
    }

    return;
}

1;
