#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;

use MIDI::RtController;

my $in  = $ARGV[0] || 'oxy';
my $out = $ARGV[1] || 'gs';

my $rtc = MIDI::RtController->new( input => $in, output => $out );

push @{ $rtc->filters->{note_on} }, sub { say join ', ', @{ $_[0] } };

$rtc->run;
