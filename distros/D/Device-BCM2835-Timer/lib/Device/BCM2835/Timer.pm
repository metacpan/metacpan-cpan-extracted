package Device::BCM2835::Timer;

use v5.12;

use Fcntl qw(:DEFAULT O_ASYNC O_DIRECT);
use Sys::Mmap;

=head1 NAME

Device::BCM2835::Timer - Access to Raspberry Pi's timer

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

my $DEVMEMFH;

my $timer_CLO_reg;
my $timer_CHI_reg;

=head1 SYNOPSIS

This module's C<timer()> method returns the current value of the Raspberry Pi's internal timer.

    use Device::BCM2835::Timer;
    say Device::BCM2835::Timer::timer();

=head1 FUNCTIONS

=head2 timer()

This function returns the number of microseconds elapsed since the Raspberry Pi in hand was
turned on.

The function gives the value of the 64 bit timer counter installed on the BCM2835 chip.
It ossillates at 1 MHz, thus every tick corresponds to 1 microsecond. Internally, it is a
pair of two 32 bit registers, which are read and added up correspondently in pure Perl.

=cut

my $_init_done = 0;

sub _init {
    unless (
            sysopen($DEVMEMFH, "/dev/mem", O_RDWR|O_SYNC, 0666)
        ) {
        return;
    }

    unless (
            # Mmapping CLO and CHI timer registers, each 32 bits long.
            # See chapter 12 System Timer of the BCM2835 manual:
            # http://www.raspberrypi.org/wp-content/uploads/2012/02/BCM2835-ARM-Peripherals.pdf
            mmap($timer_CLO_reg, 4, PROT_READ|PROT_WRITE, MAP_SHARED, $DEVMEMFH, 0x20003004) &&
            mmap($timer_CHI_reg, 4, PROT_READ|PROT_WRITE, MAP_SHARED, $DEVMEMFH, 0x20003008)
        ) {
        close($DEVMEMFH);
        return;
    }

    $_init_done = 1;
}

sub timer {
    _init() unless $_init_done;

    my $timer_lo = unpack 'L', $timer_CLO_reg;
    my $timer_hi = unpack 'L', $timer_CHI_reg;

    my $timer = $timer_lo + ($timer_hi << 32);

    return $timer;
}

=head1 AUTHOR

Andrew Shitov, C<< <andy at shitov.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-device-bcm2835-timer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-BCM2835-Timer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::BCM2835::Timer


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Andrew Shitov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0).

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
