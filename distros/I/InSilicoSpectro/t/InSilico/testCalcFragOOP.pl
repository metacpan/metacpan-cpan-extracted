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


BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}

use strict;
use Carp;
use InSilicoSpectro;
use InSilicoSpectro::InSilico::MassCalculator;
use InSilicoSpectro::InSilico::Peptide;
use InSilicoSpectro::InSilico::MSMSTheoSpectrum;
use InSilicoSpectro::InSilico::TermIonSeries;

eval{
  InSilicoSpectro::init();

  # Test 1
  my %spectrum;
  my $peptide = new InSilicoSpectro::InSilico::Peptide(sequence=>'HCMSKPSMLR', modif=>'::Cys_CAM::::::Oxidation:::');
  getFragmentMasses(pept=>$peptide, fragTypes=>['b','a','b-H2O*-NH3*','b++','y','y-H2O*-NH3*','y++','immo'], spectrum=>\%spectrum);
  my $theoSpectrum = new InSilicoSpectro::InSilico::MSMSTheoSpectrum(theoSpectrum=>\%spectrum, massType=>getMassType());
  my $len = $theoSpectrum->getPeptideLength();
  print "Fragments of ",$theoSpectrum->getPeptide()," (",modifToString($theoSpectrum->getModif(), $len),", ",$theoSpectrum->getPeptideMass()," Da):\n";
  foreach ($theoSpectrum->getTermIons()){
    print "$_\n";
  }
  foreach ($theoSpectrum->getInternIons()){
    print "$_\n";
  }
};
if ($@){
  carp($@);
}
