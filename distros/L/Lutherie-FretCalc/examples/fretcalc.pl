#!/usr/bin/perl -w
use strict;
use Lutherie::FretCalc;

# Create new FretCalc object
my $fretcalc = Lutherie::FretCalc->new; # Default 25
# Config
$fretcalc->num_frets(24);               # Default 24
$fretcalc->in_units('in');              # Default 'in'
$fretcalc->out_units('in');             # Default 'in'
$fretcalc->calc_method('t');            # Default 't'
$fretcalc->tet(12);                     # Default 12


my @chart = $fretcalc->fretcalc(); 

for my $fret(1..$#chart) {
    $fret = sprintf("%3d",$fret);
    print "Fret $fret: $chart[$fret]\n";
}

print "\n\n";

$fretcalc->fret_num(2);
my $fret = $fretcalc->fret();
my $fret_num = sprintf("%3d",$fretcalc->{fret_num});
print "Fret $fret_num: $fret\n";
