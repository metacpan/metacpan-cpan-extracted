#!/usr/bin/perl

# Program to extract fragment mass errors from peptSpectra.xml files
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
#  Upper Austria University of Applied Science at Hagenberg
#  Hauptstrasse 117
#  A-4232 Hagenberg, Austria
#  http://www.fhs-hagenberg.ac.at

=head1 NAME

fragErrorDistr.pl - Extraction of fragment ion mass errors from .peptSpectra.xml files

=head1 SYNOPSIS

fragErrorDistr.pl [options] peptSpectra.xml files

=head1 OPTIONS

Use fragErrorDistr.pl -h

=head1 DESCRIPTION

The script parses a collection of trusted peptide/spectrum matches stored in one or several .peptSpectra.xml
files to extract fragment ion mass errors. The files can be gzipped.

It is possible to export results in text format or in a format readable by R. The mass errors can be printed either in Daltons or in ppm.

=head1 EXAMPLE

./fragErrorDistr.pl example.peptSpectra.xml > fragerr.txt

=head1 AUTHOR

Jacques Colinge

=cut


use strict;
use XML::Parser;
use Getopt::Long;
use InSilicoSpectro;
use InSilicoSpectro::InSilico::MassCalculator;
use InSilicoSpectro::InSilico::Peptide;
use InSilicoSpectro::Spectra::PeakDescriptor;
use InSilicoSpectro::Spectra::ExpSpectrum;
use InSilicoSpectro::InSilico::MSMSTheoSpectrum;

my ($help, $imposedCharge, $relint, $rFormat);
my $fragTypes = 'a,b,b-NH3,b-H2O,b++,y,y-NH3,y-H2O,y++';
my $tol = 600;
my $minTol = 0.2;
my $matchSel = 'closest';
my $configFile;
my $ppm;
my $verbose;

if (!GetOptions('help' => \$help,
		'h' => \$help,
		'ppm' => \$ppm,
		'verbose' => \$verbose,
		'configfile=s' => \$configFile,
		'charge=i' => \$imposedCharge,
		'tol=f' => \$tol,
		'mintol=f' => \$minTol,
		'matchsel=s' => \$matchSel,
		'rformat' => \$rFormat,
		'frag=s' => \$fragTypes) || defined($help)){
  print STDERR "Usage: fragErrorDistr.pl [options] peptSpectra.xml files
--configFile=string xml configuration file for Masscalculator.pm
--frag=string       list of fragment types separated by comas, default is [$fragTypes]
--charge=int        only look at peptides at this charge state, default is no imposed charge
--tol=float         relative mass error tolerance in ppm, default [$tol]
--mintol=float      absolute mass error tolerance in Da, default [$minTol]
--matchsel=string   select the match algorithm (closest|greedy|mostintense), the order is given by frag in case of greedy
-ppm                relative error instead of absolute in Daltons
-verbose
-help
-h\n";
  exit(0);
}

if($configFile){
  InSilicoSpectro::init($configFile);
}
else{
  InSilicoSpectro::init();
}

my @fragTypes = split(/,/, $fragTypes);
my %errorStat;
our $file;
foreach $file (@ARGV){
  print STDERR "Parsing $file\n" if ($verbose);

  if ($file =~ /\.gz$/){
    open(F, "gunzip -c $file |") || print STDERR "Warning, cannot open [$file]: $!";
  }
  else{
    open(F, $file) || print STDERR "Warning, cannot open [$file]: $!";
  }
  my $parser = new XML::Parser(Style => 'Stream');
  $parser->parse(\*F);
  close(F);
}

my $maxLen = 0;
foreach my $frag (keys(%errorStat)){
  if ((@{$errorStat{$frag}} > $maxLen)){
    $maxLen = scalar(@{$errorStat{$frag}});
  }
}
if (defined($rFormat)){
  foreach my $frag (sort InSilicoSpectro::InSilico::MSMSOutput::cmpFragTypes (keys(%errorStat))){
    print "\"$frag\"\t";
  }
  print "\n";
  for (my $i = 1; $i <= $maxLen; $i++){
    print "\"$i\"";
    foreach my $frag (sort InSilicoSpectro::InSilico::MSMSOutput::cmpFragTypes (keys(%errorStat))){
      if (defined($errorStat{$frag}[$i-1])){
	printf "\t%.4f", $errorStat{$frag}[$i-1];
      }
      else{
	print "\tNA";
      }
    }
    print "\n";
  }
}
else{
  foreach my $frag (sort InSilicoSpectro::InSilico::MSMSOutput::cmpFragTypes (keys(%errorStat))){
    print $frag;
    foreach (@{$errorStat{$frag}}){
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

      # Extracts statistics
      my $len = length($peptide);
      foreach my $frag (keys(%{$spectrum{mass}{term}})){
	for (my $i = 0; $i < @{$spectrum{ionType}{$frag}}; $i++){
	  for (my $j = $i*$len; $j < ($i+1)*$len; $j++){
	    if (defined($spectrum{mass}{term}{$frag}[$j]) && defined($spectrum{match}{term}{$frag}[$j])){
	      my $theoMass = $spectrum{mass}{term}{$frag}[$j];
	      my $expMass = $spectrum{match}{term}{$frag}[$j][0];
	      if ((abs($theoMass-$expMass)/($theoMass+$expMass)*2.0e6 <= $tol) || (abs($theoMass-$expMass) <= $minTol)){
		push(@{$errorStat{$spectrum{ionType}{$frag}[$i]}}, defined($ppm) ? ($expMass-$theoMass)/($theoMass+$expMass)*2.0e+6 : $expMass-$theoMass);
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
	      push(@{$errorStat{"$frag($aa)"}}, defined($ppm) ? ($expMass-$theoMass)/($theoMass+$expMass)*2.0e+6 : $expMass-$theoMass);
	    }
	  }
	}
      }
    }
  }

} # EndTag
