package Linux::Perl::signalfd;

use strict;
use warnings;

=head1 NAME

Linux::Perl::signalfd

=head1 SYNOPSIS

    # One potential way of preventing the signals
    # from taking down the process.
    Linux::Perl::sigprocmask->block( 'INT', 'ABRT' );

    my $sigfd = Linux::Perl::signalfd->new(
        flags => ['NONBLOCK', 'CLOEXEC'],
        signals => ['INT', 'ABRT'],
    );

    $sigfd->set_signals( 'INT' );

    my @evts = $sigfd->read();

=head1 DESCRIPTION

An implementation of Linux’s “signalfd”.

Note that you’ll need to ensure that whatever signals you
expect to receive don’t take down the process.
L<sigprocmask|Linux::Perl::sigprocmask> can help with this.

=cut

use parent qw(
    Linux::Perl::Base
    Linux::Perl::Base::BitsTest
);

use Call::Context;

use Linux::Perl;
use Linux::Perl::EasyPack;
use Linux::Perl::ParseFlags;
use Linux::Perl::SigSet;
use Linux::Perl::Constants::Fcntl;

*_flag_CLOEXEC = \*Linux::Perl::Constants::Fcntl::flag_CLOEXEC;
*_flag_NONBLOCK = \*Linux::Perl::Constants::Fcntl::flag_NONBLOCK;

use constant _sfd_siginfo_size => 128;

#----------------------------------------------------------------------

=head1 METHODS

=head2 I<CLASS>->new( %OPTS )

Creates a signalfd instance. %OPTS are:

=over

=item * C<signals> - An array reference, each of whose members is either
a string (e.g., C<INT>) or a signal number.

=item * C<flags> - Optional, an array reference of either/both of:
C<NONBLOCK>, C<CLOEXEC>.

=back

=cut

sub new {
    my ($class, %opts) = @_;

    my $arch_module = $class->_get_arch_module();

    my $flags = Linux::Perl::ParseFlags::parse( $class, $opts{'flags'} );

    my $fd = _call_signalfd( $arch_module, -1, $flags, $opts{'signals'} );

    local $^F = 1000 if $flags & _flag_CLOEXEC();

    open my $fh, '+<&=', $fd;

    return bless [$fd, $fh], $arch_module;
}

#----------------------------------------------------------------------

=head2 $num = I<OBJ>->fileno()

Returns the file descriptor, which can be used with, e.g.,
C<select()>, L<epoll()|Linux::Perl::epoll>, or C<poll()>.

=cut

sub fileno { return $_[0][0]; }

#----------------------------------------------------------------------

my ($sfd_siginfo_keys_ar, $sfd_siginfo_pack);

BEGIN {
    ($sfd_siginfo_keys_ar, $sfd_siginfo_pack) = Linux::Perl::EasyPack::split_pack_list(
        signo => 'L',
        errno => 'l',
        code => 'l',
        pid => 'L',
        uid => 'L',
        fd => 'l',
        tid => 'L',
        band => 'L',
        overrun => 'L',
        trapno => 'L',
        status => 'l',
        int => 'l',
        ptr => __PACKAGE__->_PACK_u64(),
        utime => __PACKAGE__->_PACK_u64(),
        stime => __PACKAGE__->_PACK_u64(),
        addr => __PACKAGE__->_PACK_u64(),
        addr_lsb => 'S',
    );
}

=head2 @signals = I<OBJ>-read()

Reads events from the signalfd instance. Each event is a hash reference
whose keys and values correspond to C<struct inotify_event>.
(cf. C<man 7 inotify>)

In scalar context the return is the number of hash references that would
be returned in list context.

An empty return (0 in scalar context) is an error state, in which case
C<$!> will indicate what the error was.

=cut

sub read {
    my ($self) = @_;

    Call::Context::must_be_list();

    return if !sysread( $self->[1], my $buf, 65536 );

    my @sigs;

    while (length $buf) {
        my $bufbuf = substr($buf, 0, _sfd_siginfo_size(), q<>);

        my %result;
        @result{ @$sfd_siginfo_keys_ar } = unpack $sfd_siginfo_pack, $bufbuf;

        push @sigs, \%result;
    }

    return @sigs;
}

#----------------------------------------------------------------------

=head2 I<OBJ>->set_signals( @SIGNALS )

Updates the signalfd instance’s list of signals to listen for.
@SIGNALS is a list such as the constructor’s C<signals> argument.

This returns the instance.

=cut

sub set_signals {
    my ($self, @signals) = @_;

    _call_signalfd(
        $self,
        $self->[0],
        0,
        \@signals,
    );

    return $self;
}

sub _call_signalfd {
    my ($arch_module, $fd, $flags, $signals_ar) = @_;

    my $sigmask = Linux::Perl::SigSet::from_list( @$signals_ar );

    my $call_name = 'NR_signalfd';
    $call_name .= '4' if $flags;

    $fd = Linux::Perl::call(
        $arch_module->$call_name(),
        $fd,
        $sigmask,
        length $sigmask,
        0 + $flags,
    );

    return $fd;
}

1;
