#!/usr/bin/env perl

use strict;
use warnings;

use MIDI::RtController;

my $in  = $ARGV[0] || 'oxy';
my $out = $ARGV[1] || 'gs';

my $rtc = MIDI::RtController->new( input => $in, output => $out );

$rtc->add_filter(
    'echo',
    all => sub {
        my ($dt, $event) = @_;
        print "dt: $dt, ev: ", join( ', ', @$event ), "\n"
            unless $event->[0] eq 'clock';
        return 0;
    }
);

$rtc->run;
