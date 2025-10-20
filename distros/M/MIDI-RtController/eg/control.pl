#!/usr/bin/env perl
use strict;
use warnings;

use MIDI::RtController ();

my $in  = shift || 'pad'; # Synido TempoPAD Z-1
my $out = shift || 'usb'; # USB MIDI Interface

my $controller = MIDI::RtController->new(
    input   => $in,
    output  => $out,
    verbose => 1,
);

# set the controls for the heart of the sun
$controller->run;

__END__
> perl -MMIDI::RtController -E \
  '$c = MIDI::RtController->new(input=>shift, output=>shift, verbose=>1); $c->run' \
  keyboard usb

# BUT:
> perl -Midi -E 'i(@ARGV)' keyboard usb
