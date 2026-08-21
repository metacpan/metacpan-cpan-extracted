#!/usr/bin/env perl

use MIDI::RtController ();
use MIDI::RtController::Filter::CC ();

my $in  = shift || 'pad';         # midi input controller
my $out = shift || 'usb';         # midi output
my $ctl = shift || '12=74,13=71'; # trigger=control,... cutoff,resonance

my %ctl = map { split /=/, $_ } split /,/, $ctl;
my @filters = map {
    +{
        port  => $in,
        event => 'control_change',
        trigger => $_,
        control => $ctl{$_},
    }
} keys %ctl;

my $controller = MIDI::RtController->new(
    input   => $in,
    output  => $out,
    verbose => 1,
);

MIDI::RtController::Filter::CC::add_filters(\@filters, { $in => $controller });

$controller->run;

# ...and now trigger a MIDI message!
