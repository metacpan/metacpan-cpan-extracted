#!/usr/bin/perl


# Test program for Perl module MassCalculator.pm
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


=head1 testCalcDigest.pl

This test and example program illustrates the use of the digestion methods with
enzymes defined as objects.

=cut

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}

use strict;
use Carp;
use InSilicoSpectro;
use InSilicoSpectro::InSilico::MassCalculator;
use InSilicoSpectro::InSilico::CleavEnzyme;
use InSilicoSpectro::InSilico::AASequence;
use InSilicoSpectro::InSilico::Peptide;

  InSilicoSpectro::init();

  my $test = shift;

  if ($test == 1){
    # Test 1, tryptic digestion
    my $protein = new InSilicoSpectro::InSilico::AASequence(sequence=>'MCTMACTKGIPRKQWWEMMKPCKADFCV', modif=>'::Cys_CAM::Oxidation::::::::::::::Oxidation:::::::::::', AC=>'12345');
    print "Protein:\n$protein", modifToString($protein->modif(), $protein->getLength()), "\n\nTryptic digestion (nmc=1):\n";
    my @result = digestByRegExp(protein=>$protein, methionine=>1, nmc=>1, enzyme=>InSilicoSpectro::InSilico::CleavEnzyme::getFromDico('Trypsin'));
    foreach (@result){
      $_->print();
      print "\n";
    }
  }

  if ($test == 2){
    # Test 2, half-tryptic digestion
    my $protein = new InSilicoSpectro::InSilico::AASequence(sequence=>'MCTMACTKGIPRKQWWEMMKPCKADFCV', modif=>'::Cys_CAM::Oxidation::::::::::::::Oxidation:::::::::::', AC=>'12345');
    print "Protein:\n$protein", modifToString($protein->modif(), $protein->getLength()), "\n\nHalf-tryptic digestion (PMF)\nminMass=2000 Da to limit output:\n";
    my @result = nonSpecificDigestion(protein=>$protein, enzyme=>InSilicoSpectro::InSilico::CleavEnzyme::getFromDico('Trypsin'), minMass=>2000, pmf=>1);
    foreach (@result){
      print "$_\t", join("\t", $_->start(), $_->end(), $_->enzymatic(), $_->getMass(), modifToString($_->modif())), "\n";
    }
  }

  if ($test == 3){
    # Test 3, tryptic digestion
    my $protein = new InSilicoSpectro::InSilico::AASequence(sequence=>'MCTMACTKGIPRKQWWEMMKPCKADFCV', modif=>'::Cys_CAM::Oxidation::::::::::::::Oxidation:::::::::::', AC=>'12345');
    print "Protein:\n$protein", modifToString($protein->modif(), $protein->getLength()), "\n\nTryptic digestion (nmc=1) with O18 (atoms):\n";
    my @result = digestByRegExp(protein=>$protein, methionine=>1, nmc=>1, enzyme=>InSilicoSpectro::InSilico::CleavEnzyme::getFromDico('Trypsin'));
    foreach (@result){
      print "$_\t", join("\t", $_->start(), $_->end(), $_->enzymatic(), $_->getMass(), modifToString($_->modif())), "\n";
    }
  }

  if ($test == 4){
    # Test 4, tryptic digestion
    my $protein = new InSilicoSpectro::InSilico::AASequence(sequence=>'MCTMACTKGIPRKQWWEMMKPCKADFCV', modif=>'::Cys_CAM::Oxidation::::::::::::::(*)Oxidation:::::::::::', AC=>'12345');
    print "Protein:\n$protein", modifToString($protein->modif(), $protein->getLength()), "\n\nTryptic digestion (nmc=1) with O18 (modif O18_twice):\n";
    my @result = digestByRegExp(protein=>$protein, methionine=>1, nmc=>1, enzyme=>InSilicoSpectro::InSilico::CleavEnzyme::getFromDico('Trypsin_O18modif'));
    foreach (@result){
      print "$_\t", join("\t", $_->start(), $_->end(), $_->enzymatic(), $_->getMass(), modifToString($_->modif())), "\n";
    }
  }
