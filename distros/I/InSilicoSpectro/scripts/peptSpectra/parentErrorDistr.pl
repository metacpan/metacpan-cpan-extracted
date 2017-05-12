#!/usr/bin/perl

# Mass spectrometry Perl program for computing the parent ion mass error distribution from peptSpectra.xml files

# Copyright (C) 2005 Jacques Colinge

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

parentErrorDistr.pl - Extraction of parent ion mass errors from .peptSpectra.xml files

=head1 SYNOPSIS

parentErrorDistr.pl [options] peptSpectra.xml files

=head1 OPTIONS

Use parentErrorDistr.pl -h

=head1 DESCRIPTION

The script parses a collection of trusted peptide/spectrum matches stored in one or several .peptSpectra.xml
files to extract parent ion mass errors. The files can be gzipped.

It is possible to export results in text format or in a format readable by R. It is also possible to
restrict the output to an imposed charge state. The mass errors can be printed either in Daltons or in ppm.

=head1 EXAMPLE

./parentErrorDistr.pl example.peptSpectra.xml > parerr.txt

=head1 AUTHOR

Jacques Colinge

=cut

use strict;
use Getopt::Long;
use InSilicoSpectro;
use InSilicoSpectro::InSilico::MassCalculator;

my ($ppm, $help, $imposedCharge, $verbose, $rFormat);

if (!GetOptions('help' => \$help,
		'h' => \$help,
		'verbose' => \$verbose,
		'ppm' => \$ppm,
		'rformat' => \$rFormat,
		'imposedcharge=i' => \$imposedCharge) || defined($help)){
  print STDERR "Usage: parentErrorDistrib.pl [options] peptSpectra.xml
\t-h
\t-help
\t-verbose
\t-rFormat                 format readable by R
\t-ppm                     output in ppm instead of Daltons
\t--imposedcharge=int      specific charge\n";
}


InSilicoSpectro::init();
my @err;
use XML::Parser;
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

if (defined($rFormat)){
  print '"error"'."\n";
  for (my $i = 1; $i <= @err; $i++){
    print "\"$i\"";
    printf "\t%.4f\n", $err[$i-1];
  }
}
else{
  print join("\n", @err);
  print "\n";
}


# ------------------------------------------------------------------------
# XML parsing
# ------------------------------------------------------------------------

my ($curChar, $massIndex, $intensityIndex, $charge, $peptide, $modif, $moz, $itemIndex);

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
  elsif ($el eq 'ple:ParentMass'){
    $moz = (split(/\s+/, $curChar))[0];
  }
  elsif (($el eq 'idi:OneIdentification') && (!defined($imposedCharge) || ($charge == $imposedCharge))){
    # Compares exp and theo masses
    my @modif = split(/:/, $modif);
    my $theoMass = getPeptideMass(pept=>$peptide, modif=>\@modif);
    my ($charge, $moz2) = getCorrectCharge($theoMass, $moz);
    my $expMass = ($moz-getMass('el_H+'))*$charge;
    my $err = defined($ppm) ? ($expMass-$theoMass)/($expMass+$theoMass)*2.e+6 : $expMass-$theoMass;
    push(@err, $err);
  }

} # EndTag
