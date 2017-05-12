#!/usr/bin/perl

# Mass spectrometry Perl program for extracting unique peptides from a peptSpectra.xml file

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

extractUniquePeptSpectra.pl - Extracts unique peptides from a .peptSpectra.xml file

=head1 SYNOPSIS

extractUniquePeptSpectra.pl [options] peptSpectra.xml files

=head1 OPTIONS

Use extractUniquePeptSpectra.pl -h

=head1 DESCRIPTION

The script extracts peptide/spectrum matches from a .peptSpectra.xml file that involve unique
peptides. In case several matches involve the same peptide in the original file(s), by default
the match having the highest score is selected. If there is no score stored in the file(s) or
if the -random flag is used, then the selection is random.

In addition, it is possible to save all the remaining matches in a second file.

=head1 EXAMPLE

./extractUniquePeptSpectra.pl example.peptSpectra.xml > test.peptSpectra.xml

=head1 AUTHOR

Jacques Colinge

=cut

use strict;
use Getopt::Long;

my ($help, $unselected, $random);

if (!GetOptions('help' => \$help,
		'h' => \$help,
		'random' => \$random,
		'unselected=s' => \$unselected) || defined($help)){
  print STDERR "Usage: extractUniquePeptSpectra.pl peptSpectra.xml
\t-h
\t-help
\t-random               [select one spectra for a peptide sequence randomly instead of taking the best scoring one]
\t--unselected=fname    [a file name for unselected spectra, if not given then unselected spectra are ignored]\n";
}

# Finds the highest scoring match for each peptide
my (%score, $pept);
my $score = -1.0; # Incase it is the old file format
open(F, $ARGV[0]) || CORE::die("Cannot open [$ARGV[0]]: $!");
while (<F>){
  if (/<idi:sequence>([A-Z]+)<\/idi:sequence>/){
    $pept = $1;
  }
  elsif (/<idi:peptScore>([\.0-9]+)<\/idi:peptScore>/){
    $score = $1;
  }
  elsif (/<\/idi:OneIdentification>/){
    # Old file format - without score - support
    if (!defined($random)){
      if (($score > $score{$pept}) || ($score == -1.0)){
	$score{$pept} = $score;
      }
    }
    else{
      # At this stage we simply collect scores
      push(@{$score{$pept}}, $score);
    }
  }
}
close(F);
if (defined($random)){
  # Selects a score randomly for each peptide
  use Math::Random::TT800;
  my $tt = new Math::Random::TT800;
  foreach my $pept (keys(%score)){
    my $n = scalar(@{$score{$pept}});
    $score{$pept} = $score{$pept}[int($n*$tt->next())];
  }
}

if (defined($unselected)){
  open(U, ">$unselected") || CORE::die("Cannot create [$unselected]: $!");
}

# Prints the header
open(F, $ARGV[0]) || CORE::die("Cannot open [$ARGV[0]]: $!");
while (<F>){
  print;
  print U if (defined($unselected));
  last if (/<idi:Identifications>/);
}

# Prints highest-scoring peptides only
my $oneIdentification;
while (<F>){
  last if (/<\/idi:Identifications>/);

  $oneIdentification .= $_;
  if (/<idi:sequence>([A-Z]+)<\/idi:sequence>/){
    $pept = $1;
  }
  elsif (/<idi:peptScore>([\.0-9]+)<\/idi:peptScore>/){
    $score = $1;
  }
  elsif (/<\/idi:OneIdentification>/){
    if ($score == $score{$pept}){
      print $oneIdentification;
      undef($score{$pept}); # in case several matches have the save score
    }
    elsif (defined($unselected)){
      print U $oneIdentification;
    }
    undef($oneIdentification);
  }
}

# Prints the end of the file
print;
while (<F>){
  print;
  print U if (defined($unselected));
}
close(F);
