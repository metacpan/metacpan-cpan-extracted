#!/usr/bin/perl

# Program to extract ion intensities from a .peptSpectra.xml file
# Copyright (C) 2005 Jacques Colinge

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Contact:
#  Prof. Jacques Colinge
#  Upper Austria University of Applied Sciences at Hagenberg
#  Hauptstrasse 117
#  A-4232 Hagenberg, Austria
#  http://www.fhs-hagenberg.ac.at

=head1 NAME

getIonIntensities.pl - Extraction of ion intensities information from a .peptSpectra.xml file

=head1 SYNOPSIS

getIonIntensities.pl --pept=peptfile [options]

=head1 OPTIONS

Use getIonIntensities.pl -h

=head1 DESCRIPTION

The script parses a collection of trusted peptide/spectrum matches stored in a .peptSpectra.xml
file to extract statistics regarding fragment ion intensities. It is possible to output the results
either in text format (default) or in a format readable by R. In the latter case, the simple R script,
ionStat.R, can be used for plotting data.

In addition, plots can be generated for each match found in the .peptSpectra.xml file(s) by
using the -withplots.

=head1 EXAMPLE

./getIonIntensities.pl --pept=example.peptSpectra.xml -rformat -withplots > intensities.dataf

=head1 AUTHOR

Jacques Colinge

=cut

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}

use strict;
use XML::Parser;
use Getopt::Long;
use InSilicoSpectro;
use InSilicoSpectro::InSilico::MassCalculator;
use InSilicoSpectro::InSilico::Peptide;
use InSilicoSpectro::Spectra::PeakDescriptor;
use InSilicoSpectro::Spectra::ExpSpectrum;
use InSilicoSpectro::InSilico::MSMSTheoSpectrum;
use InSilicoSpectro::InSilico::MSMSOutput;

my ($help, $peptFile, $imposedCharge, $relint, $rFormat);
my $fragTypes = 'a,b,b-NH3,b-H2O,b++,y,y-NH3,y-H2O,y++';
my $tol = 600;
my $minTol = 0.2;
my $intSel = 'order';
my $matchSel = 'closest';
my $withPlots;
my $configFile;

if (!GetOptions('help' => \$help,
		'h' => \$help,
		'configfile=s' => \$configFile,
		'pept=s' => \$peptFile,
		'charge=i' => \$imposedCharge,
		'tol=f' => \$tol,
		'mintol=f' => \$minTol,
		'intsel=s' => \$intSel,
		'matchsel=s' => \$matchSel,
		'withplots' => \$withPlots,
		'rformat' => \$rFormat,
		'frag=s' => \$fragTypes) || defined($help) || !defined($peptFile)){
  print STDERR "Usage: getIonIntensities.pl --pept=peptfile [options]
--configFile=string xml configuration file for Masscalculator.pm
--frag=string       list of fragment types separated by comas, default is [$fragTypes]
--charge=int        only look at peptides at this charge state, default is no imposed charge
--tol=float         relative mass error tolerance in ppm, default [$tol]
--mintol=float      absolute mass error tolerance in Da, default [$minTol]
--intsel=string     select the intensity normalization (original|log|order|relative)
--matchsel=string   select the match algorithm (closest|greedy|mostintense), the order is given by frag in case of greedy
-withplots          generates individual plots for all the matches (png format)
-rformat            formats the output for R
-help
-h\n";
print "'$peptFile'\n";
  exit(0);
}

if($configFile){
  InSilicoSpectro::init($configFile);
}
else{
  InSilicoSpectro::init();
}


my @fragTypes = split(/,/, $fragTypes);
my %intensStat;
my $nPlot = 0;
open(F, $peptFile);
my $parser = new XML::Parser(Style => 'Stream');
$parser->parse(\*F);
close(F);

my $maxLen = 0;
foreach my $frag (keys(%intensStat)){
  if ((@{$intensStat{$frag}} > $maxLen)){
    $maxLen = scalar(@{$intensStat{$frag}});
  }
}
if (defined($rFormat)){
  foreach my $frag (sort InSilicoSpectro::InSilico::MSMSOutput::cmpFragTypes (keys(%intensStat))){
    print "\"$frag\"\t";
  }
  print "\n";
  for (my $i = 1; $i <= $maxLen; $i++){
    print "\"$i\"";
    foreach my $frag (sort InSilicoSpectro::InSilico::MSMSOutput::cmpFragTypes (keys(%intensStat))){
      if (defined($intensStat{$frag}[$i-1])){
	printf "\t%.3f", $intensStat{$frag}[$i-1];
      }
      else{
	print "\tNA";
      }
    }
    print "\n";
  }
}
else{
  foreach my $frag (sort InSilicoSpectro::InSilico::MSMSOutput::cmpFragTypes (keys(%intensStat))){
    print $frag;
    foreach (@{$intensStat{$frag}}){
      print "\t$_";
    }
    print "\n";
  }
}

# ------------------------------------------------------------------------
# XML parsing
# ------------------------------------------------------------------------

my ($curChar, $massIndex, $intensityIndex, $charge, $peptide, $modif, $peaks, $itemIndex);

sub Text
{
  $curChar .= $_;

} # Text


sub StartTag
{
  my ($p, $el) = @_;

  if ($el eq 'ple:ItemOrder'){
    $itemIndex = 0;
  }
  elsif ($el eq 'ple:item'){
    if ($_{type} eq 'mass'){
      $massIndex = $itemIndex;
    }
    elsif (($_{type} eq 'intensity') || ($_{type} eq 'height')){
      $intensityIndex = $itemIndex;
    }
    $itemIndex++;
  }

  undef($curChar);

} # StartTag


sub EndTag
{
  my($p, $el)= @_;
  if ($el eq 'idi:sequence'){
    $peptide = $curChar;
  }
  elsif ($el eq 'idi:modif'){
    $modif = $curChar;
  }
  elsif ($el eq 'idi:charge'){
    $charge = $curChar;
  }
  elsif ($el eq 'ple:peaks'){
    $peaks = $curChar;
  }
  elsif (($el eq 'idi:OneIdentification') && (!defined($imposedCharge) || ($charge == $imposedCharge))){

    # Builds the peak list
    my @lines = split(/\n/, $peaks);
    my (@peaks, $maxIntensity);
    foreach my $line (@lines){
      $line =~ s/\r//g;
      my @part = split(/\s+/, $line);
      if ($part[$massIndex] > 0.0){
	push(@peaks, [$part[$massIndex], $part[$intensityIndex]]);
	$maxIntensity = $part[$intensityIndex] if ($part[$intensityIndex] > $maxIntensity);
      }
    }

    if (defined($maxIntensity)){
      # Matches with theoretical masses
      my %spectrum;
      if ($matchSel eq 'closest'){
	matchSpectrumClosest(pept=>$peptide, modif=>$modif, spectrum=>\%spectrum, expSpectrum=>\@peaks, fragTypes=>\@fragTypes);
      }
      elsif ($matchSel eq 'greedy'){
	matchSpectrumGreedy(pept=>$peptide, modif=>$modif, spectrum=>\%spectrum, expSpectrum=>\@peaks, fragTypes=>\@fragTypes, order=>\@fragTypes, tol=>$tol);
      }
      elsif ($matchSel eq 'mostintense'){
	matchSpectrumGreedy(pept=>$peptide, modif=>$modif, spectrum=>\%spectrum, expSpectrum=>\@peaks, fragTypes=>\@fragTypes, tol=>$tol);
      }
      else{
	CORE::die("Unknown match type [$matchSel]");
      }

      if (defined($withPlots)){
	my $msms = new InSilicoSpectro::InSilico::MSMSOutput(spectrum=>\%spectrum, prec=>2, modifLvl=>1, expSpectrum=>\@peaks, intSel=>'order', tol=>$tol, minTol=>$minTol);
	$msms->plotSpectrumMatch(fname=>"$peptide-$$-$nPlot", format=>'png', fontChoice=>'default:Large', changeColModifAA=>1, legend=>'right', plotIntern=>1);
	$nPlot++;
      }

      # Normalizes intensities
      my %normInt;
      normalizeIntensities($intSel, \@peaks, \%normInt);

      # Extracts statistics
      my $len = length($peptide);
      foreach my $frag (keys(%{$spectrum{mass}{term}})){
	for (my $i = 0; $i < @{$spectrum{ionType}{$frag}}; $i++){
	  for (my $j = $i*$len; $j < ($i+1)*$len; $j++){
	    if (defined($spectrum{mass}{term}{$frag}[$j]) && defined($spectrum{match}{term}{$frag}[$j])){
	      my $theoMass = $spectrum{mass}{term}{$frag}[$j];
	      my $expMass = $spectrum{match}{term}{$frag}[$j][0];
	      if ((abs($theoMass-$expMass)/($theoMass+$expMass)*2.0e6 <= $tol) || (abs($theoMass-$expMass) <= $minTol)){
		push(@{$intensStat{$spectrum{ionType}{$frag}[$i]}}, $normInt{$spectrum{match}{term}{$frag}[$j][0]});
	      }
	    }
	  }
	}
      }
      foreach my $frag (keys(%{$spectrum{match}{intern}})){
	foreach my $aa (keys(%{$spectrum{match}{intern}{$frag}})){
	  if (defined($spectrum{match}{intern}{$frag}{$aa})){
	    my $theoMass = $spectrum{mass}{intern}{$frag}{$aa};
	    my $expMass = $spectrum{match}{intern}{$frag}{$aa}[0];
	    if ((abs($theoMass-$expMass)/($theoMass+$expMass)*2.0e6 <= $tol) || (abs($theoMass-$expMass) <= $minTol)){
	      push(@{$intensStat{"$frag($aa)"}}, $normInt{$spectrum{match}{intern}{$frag}{$aa}[0]});
	    }
	  }
	}
      }
    }
  }

} # EndTag
