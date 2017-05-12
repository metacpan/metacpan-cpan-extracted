#!/usr/bin/perl

# Mass spectrometry Perl program for splitting a peptSpectra.xml file into two files (training/test sets)

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

splitPeptSpectraAtRandom.pl - Splits a .peptSpectra.xml file in two .peptSpectra.xml files

=head1 SYNOPSIS

splitPeptSpectraAtRandom.pl [options] peptSpectra.xml files

=head1 OPTIONS

Use splitPeptSpectraAtRandom.pl -h

=head1 DESCRIPTION

The script splits a .peptSpectra.xml file in two .peptSpectra.xml files randomly. It is mainly
used for creating a training and a test set from one original set of peptide/spectrum matches.

The respective sizes of the two created files can be defined via a proportion or by setting a
fixed number of requested matches for the first output file.

=head1 EXAMPLE

./splitPeptSpectraAtRandom.pl --proportion=0.5 --out=test example.peptSpectra.xml

=head1 AUTHOR

Jacques Colinge

=cut

use strict;
use Getopt::Long;
use Math::Random::TT800;

my ($help, $number, $proportion, $out, $setOne, $setTwo);

if (!GetOptions('help' => \$help,
		'h' => \$help,
		'number=i' => \$number,
		'proportion=f' => \$proportion,
		'out=s' => \$out,
		'set1=s' => \$setOne,
		'set2=s' => \$setTwo) || defined($help) || (!defined($number) && !defined($proportion)) || (!defined($out) && (!defined($setOne) || !defined($setTwo)))){
  print STDERR "Usage: extractUniquePeptSpectra.pl [options] peptSpectra.xml
\t-h
\t-help
\t--number=int           [number of spectra in the first set]
\t--proportion=float     [proportion of spectra in the first set]
\t--out=fname            [base file name for the two output files]
\t--set1=fname           [file name for set one]
\t--set2=fname           [file name for set two]\n";
exit(0);
}

# Counts the peptides
my $count;
open(F, $ARGV[0]) || CORE::die("Cannot open [$ARGV[0]]: $!");
while (<F>){
  if (/<idi:sequence>/){
    $count++;
  }
}
close(F);
my $first = defined($number) ? $number : int($proportion*$count);
$first = $count if ($first > $count);
$first = 0 if ($first < 0);

# Generates the random selection
my (%selected, @remain);
my $tt = new Math::Random::TT800;
for (my $i = 0; $i < $count; $i++){
  $remain[$i] = $i;
}
for (my $i = 0; $i < $first; $i++){
  my $sel = int($tt->next()*($count-$i));
  $selected{$remain[$sel]} = 1;
  $remain[$sel] = $remain[$count-1-$i];
}

# Prints the header
if (defined($out)){
  $setOne = "$out-1.peptSpectra.xml";
  $setTwo = "$out-2.peptSpectra.xml";
}
open(S1, ">$setOne") || CORE::die("Cannot create [$setOne]: $!");
open(S2, ">$setTwo") || CORE::die("Cannot create [$setTwo]: $!");
open(F, $ARGV[0]) || CORE::die("Cannot open [$ARGV[0]]: $!");
while (<F>){
  print S1;
  print S2;
  last if (/<idi:Identifications>/);
}

# Dispatch spectra
my $oneIdentification;
my $num = 0;
while (<F>){
  last if (/<\/idi:Identifications>/);

  $oneIdentification .= $_;
  if (/<\/idi:OneIdentification>/){
    if ($selected{$num}){
      print S1 $oneIdentification;
    }
    else{
      print S2 $oneIdentification;
    }
    $num++;
    undef($oneIdentification);
  }
}

# Prints the end of the file
print S1;
print S2;
while (<F>){
  print S1;
  print S2
}
close(F);
close(S1);
close(S2);
