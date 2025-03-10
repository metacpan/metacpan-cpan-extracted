#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;

use MIDI::RtController;

my $in  = $ARGV[0] || 'oxy';
my $out = $ARGV[1] || 'gs';

my $rtc = MIDI::RtController->new( input => $in, output => $out );

$rtc->add_filter(
    'say',
    note_on => sub { say "dt: $_[0], ev: ", join( ', ', @{ $_[1] } ) }
);

$rtc->run;
