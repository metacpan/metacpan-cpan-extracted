#!/usr/bin/perl -w
use strict;
use Lutherie::FretCalc;

# Create new FretCalc object
my $fretcalc = Lutherie::FretCalc->new; 

# Config
$fretcalc->in_units('in');              # Default 'in'
$fretcalc->out_units('in');             # Default 'in'
$fretcalc->calc_method('t');            # Default 't'
$fretcalc->half_fret(6);                # Add 6+ fret
$fretcalc->half_fret(13);               # Add 13+ fret


my %chart = $fretcalc->dulc_calc(); 

foreach my $fret (sort {$a <=> $b} keys %chart) {
    my $dist = $chart{$fret};
    $fret = sprintf("%4s",$fret);
    print "Fret $fret: $dist\n";
}
