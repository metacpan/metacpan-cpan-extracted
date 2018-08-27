package Linux::Perl::Base::TimerEventFD;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Linux::Perl::Base::TimerEventFD

=head1 DESCRIPTION

L<Linux::Perl::timerfd> and L<Linux::Perl::eventfd> require a fair amount of
similar logic to implement. This base class contains that logic.

=cut

use parent qw( Linux::Perl::Base::BitsTest );

use Linux::Perl::Constants::Fcntl;
use Linux::Perl::Endian;

*_flag_CLOEXEC = \*Linux::Perl::Constants::Fcntl::flag_CLOEXEC;
*_flag_NONBLOCK = \*Linux::Perl::Constants::Fcntl::flag_NONBLOCK;

#----------------------------------------------------------------------

=head1 METHODS

=head2 I<OBJ>->fileno()

Returns the file descriptor number.

=cut

sub fileno { fileno $_[0][0] }

#----------------------------------------------------------------------

sub _read {
    return undef if !sysread $_[0][0], my $buf, 8;

    return _parse64($buf);
}

my ($big, $low);

sub _parse64 {
    my ($buf) = @_;

    if (__PACKAGE__->_PERL_CAN_64BIT()) {
        $low = unpack('Q', $buf);
    }
    else {
        if (Linux::Perl::Endian::SYSTEM_IS_BIG_ENDIAN()) {
            ($big, $low) = unpack 'NN', $buf;
        }
        else {
            ($low, $big) = unpack 'VV', $buf;
        }

        #TODO: Need to test what happens on a 32-bit Perl.
        $big && die "No 64-bit support! (high=$big, low=$low)";
    }

    return $low;
}

1;
