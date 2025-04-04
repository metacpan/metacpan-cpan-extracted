#!/usr/bin/env perl

# PERL_FUTURE_DEBUG=1 perl eg/math.pl

use curry;
use Future::IO::Impl::IOAsync;
use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();

my $input_name  = shift || 'joystick';
my $output_name = shift || 'usb';

my $rtc = MIDI::RtController->new(
    input   => $input_name,
    output  => $output_name,
    verbose => 1,
);

my $rtf = MIDI::RtController::Filter::CC->new(rtc => $rtc);

$rtc->add_filter('breathe', ['all'], $rtf->curry::breathe);

$rtc->run;

# ...and now trigger a MIDI message!
