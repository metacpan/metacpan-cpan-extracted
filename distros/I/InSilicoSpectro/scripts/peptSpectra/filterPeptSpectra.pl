#!/usr/bin/perl

# Mass spectrometry Perl program for filtering a peptSpectra.xml file

# Copyright (C) 2006 Jacques Colinge

# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.

# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Contact:
#  Prof. Jacques Colinge
#  Upper Austria University of Applied Sciences at Hagenberg
#  Hauptstrasse 117
#  A-4232 Hagenberg, Austria
#  www.fh-hagenberg.at

=head1 NAME

filterPeptSpectra.pl - Filters the matches of a .peptSpectra.xml file

=head1 SYNOPSIS

filterPeptSpectra.pl [options] peptSpectra.xml

=head1 OPTIONS

Use filterPeptSpectra.pl -h

=head1 DESCRIPTION

The script filters the matches of a .peptSpectra.xml file by applying several possible criteria.

It is possible to impose a maximum parent ion mass error in Daltons or in ppm.

It is possible to restrict the matches to an imposed charge states.

It is possible to impose a minimum number of peaks in the experimental fragmentation spectra, either
an absolute number or a number relative to the average number of amino acids (by supposing an average
mass of 100 Da).

When several criteria are used simultaneously, then the selected peptides must satisfy them all.

=head1 EXAMPLE

./filterPeptSpectra.pl --relnumpeaks=17 --imposedcharge=2 --tol=500 example.peptSpectra.xml > test.peptSPectra.xml

=head1 AUTHOR

Jacques Colinge

=cut

use strict;
use Getopt::Long;
use InSilicoSpectro;
use InSilicoSpectro::InSilico::MassCalculator;

my ($help, $tol, $imposedCharge, $numPeaks, $relNumPeaks);
my $unit = 'ppm';

if (!GetOptions('help' => \$help,
		'h' => \$help,
		'tol=f' => \$tol,
		'numpeaks=i' => \$numPeaks,
		'relnumpeaks=f' => \$relNumPeaks,
		'imposedcharge=i' => \$imposedCharge,
		'unit=s' => \$unit) || defined($help) || (!defined($tol) && !defined($imposedCharge) && !defined($numPeaks) && !defined($relNumPeaks))){
  print STDERR "Usage: filterPeptSpectra.pl [options] peptSpectra.xml
\t-h
\t-help
\t--imposedcharge=int
\t--tol=float            [mass tolerance]
\t--unit=string          ['ppm' or 'Da', default is '$unit']
\t--numPeaks=int         [minimum number of peaks in an experimental spectrum]
\t--relnumpeaks=float    [minimum relative number of peaks, divide the parent mass by 100 and multiply by this number to obtain the minimum number of peaks required]\n";
  exit(0);
}

$unit = uc($unit);
InSilicoSpectro::init();

open(F, $ARGV[0]) || CORE::die("Cannot open [$ARGV[0]]: $!");
while (<F>){
  print;
  last if (/<idi:Identifications>/);
}

my ($oneIdentification, $peptide, $modif, $charge, $moz, $numMoz);
while (<F>){
  last if (/<\/idi:Identifications>/);
  $oneIdentification .= $_;

  if (/<idi:sequence>(.+)<\/idi:sequence>/){
    $peptide = $1;
  }
  elsif (/<idi:modif>(.+)<\/idi:modif>/){
    $modif = $1;
  }
  elsif (/<idi:charge>(.+)<\/idi:charge>/){
    $charge = $1+0;
  }
  elsif (/<ple:ParentMass><!\[CDATA\[(.+)\]\]><\/ple:ParentMass>/){
    $moz = (split(/\s+/, $1))[0];
  }
  elsif (/<ple:peaks><!\[CDATA\[/){
    $numMoz = 0;
    while (<F>){
      $oneIdentification .= $_;
      last if (/\]\]><\/ple:peaks>/);
      $numMoz++;
    }
  }
  elsif (/<\/idi:OneIdentification>/){
    # Checks charge state
    if (defined($imposedCharge) && ($charge != $imposedCharge)){print STDERR "$charge != $imposedCharge\n";
      undef($oneIdentification);
      next;
    }

    # Checks parent ion mass error
    if (defined($tol)){
      my @modif = split(/:/, $modif);
      my $theoMass = getPeptideMass(pept=>$peptide, modif=>\@modif);
      my ($charge, $moz2) = getCorrectCharge($theoMass, $moz);
      my $expMass = ($moz-getMass('el_H+'))*$charge;
      my $err = ($unit eq 'PPM') ? ($expMass-$theoMass)/($expMass+$theoMass)*2.e+6 : $expMass-$theoMass;
      if (abs($err) > $tol){print STDERR "$err > $tol\n";
	undef($oneIdentification);
	next;
      }
    }

    # Checks number of peaks
    if (defined($numPeaks) && ($numMoz < $numPeaks)){print STDERR "$numMoz < $numPeaks\n";
      undef($oneIdentification);
      next;
    }
    if (defined($relNumPeaks)){
      my @modif = split(/:/, $modif);
      my $theoMass = getPeptideMass(pept=>$peptide, modif=>\@modif);
      my ($charge, $moz2) = getCorrectCharge($theoMass, $moz);
      my $expMass = ($moz-getMass('el_H+'))*$charge;
      my $n = $expMass/100.0;
      if ($numMoz < $n*$relNumPeaks){print STDERR "$numMoz < $n*$relNumPeaks\n";
	undef($oneIdentification);
	next;
      }
    }

    print $oneIdentification;
    undef($oneIdentification);
  }
}
print;
while (<F>){
  print;
}
close(F);
