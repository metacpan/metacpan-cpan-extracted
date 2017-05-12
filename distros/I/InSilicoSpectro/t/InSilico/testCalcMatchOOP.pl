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
use InSilicoSpectro::Spectra::PeakDescriptor;
use InSilicoSpectro::Spectra::ExpSpectrum;
use InSilicoSpectro::InSilico::MSMSTheoSpectrum;

eval{
  InSilicoSpectro::init();
  my $test = shift;

  if ($test == 1){
    # Test 1, matchSpectrumCLosest. Note that we pre-compute the theoretical spectrum in this example,
    # which is not mandatory. See test 2 for the alternative choice of letting the match function
    # call getFragmentMasses behind the scene.
    my %spectrum;
    my $peptide = new InSilicoSpectro::InSilico::Peptide(sequence=>'HCMSKPQMLR', modif=>'::Cys_CAM::::::Oxidation:::');
    getFragmentMasses(pept=>$peptide, fragTypes=>['b','a','b-NH3*','b-H2O*','b++','y','y-NH3*','y-H2O*','y++','immo'], spectrum=>\%spectrum);
    # Artificial experimental spectrum
    my $pd = new InSilicoSpectro::Spectra::PeakDescriptor(['mass', 'intensity']);
    my $expSpectrum = new InSilicoSpectro::Spectra::ExpSpectrum(spectrum=>[[87,1000],[87.5, 100],[330.6,1000], [429, 800], [435, 200], [488, 900], [551, 750], [727, 200]], peakDescriptor=>$pd);
    matchSpectrumClosest(spectrum=>\%spectrum, expSpectrum=>$expSpectrum);
    my $theoSpectrum = new InSilicoSpectro::InSilico::MSMSTheoSpectrum(theoSpectrum=>\%spectrum, massType=>getMassType(), tol=>10000, minTol=>2);
    my $len = $theoSpectrum->getPeptideLength();
    print "matchSpectrumCLosest for $peptide (",modifToString($peptide->modif(),$len),")\nFragments:\n";
    foreach ($theoSpectrum->getTermIons()){
      print "$_\n";
    }
    foreach ($theoSpectrum->getInternIons()){
      print "$_\n";
    }
  }

  if ($test == 2){
    # Test 2, matchSpectrumGreedy. Note that we no longer pre-compute the theoretical spectrum in
    # this example to illustrate this alternative possibility.
    my %spectrum;
    my $peptide = new InSilicoSpectro::InSilico::Peptide(sequence=>'HCMSKPQMLR', modif=>'::Cys_CAM::::::Oxidation:::');
    my $pd = new InSilicoSpectro::Spectra::PeakDescriptor(['mass', 'intensity']);
    my $expSpectrum = new InSilicoSpectro::Spectra::ExpSpectrum(spectrum=>[[87,1000],[87.5, 100],[330.6,1000], [429, 800], [435, 200], [488, 900], [551, 750], [727, 200]], peakDescriptor=>$pd);
    matchSpectrumGreedy(pept=>$peptide,fragTypes=>['b','a','b-NH3*','b-H2O*','b++','y','y-NH3*','y-H2O*','y++','immo'], spectrum=>\%spectrum, expSpectrum=>$expSpectrum, tol=>10000, minTol=>2);
    my $theoSpectrum = new InSilicoSpectro::InSilico::MSMSTheoSpectrum(theoSpectrum=>\%spectrum, massType=>getMassType());
    my $len = $theoSpectrum->getPeptideLength();
    print "matchSpectrumGreedy for $peptide (",modifToString($peptide->modif(),$len),")\nNo order given => returns the most intense peak in the mass window; see the impact on the first y++\ntol = 10000 ppm, minTol = 2 Da\nFragments:\n";
    foreach ($theoSpectrum->getTermIons()){
      print "$_\n";
    }
    foreach ($theoSpectrum->getInternIons()){
      print "$_\n";
    }
  }

  if ($test == 3){
    # Test 3, matchSpectrumGreedy again! We use the real greedy match this time with an order given.
    my %spectrum;
    my $peptide = new InSilicoSpectro::InSilico::Peptide(sequence=>'HCMSKPQMLR', modif=>'::Cys_CAM::::::Oxidation:::');
    my $pd = new InSilicoSpectro::Spectra::PeakDescriptor(['mass', 'intensity']);
    my $expSpectrum = new InSilicoSpectro::Spectra::ExpSpectrum(spectrum=>[[87,1000],[87.5, 100],[330.6,1000], [429, 800], [435, 200], [488, 900], [551, 750], [727, 200]], peakDescriptor=>$pd);
    matchSpectrumGreedy(pept=>$peptide, fragTypes=>['b','a','b-NH3*','b-H2O*','b++','y','y-NH3*','y-H2O*','y++','immo'], spectrum=>\%spectrum, expSpectrum=>$expSpectrum, tol=>10000, minTol=>2, order=>['immo','y','b','y++','b-NH3*','b-H2O*','b++','y-NH3*','y-H2O*','z']);
    my $theoSpectrum = new InSilicoSpectro::InSilico::MSMSTheoSpectrum(theoSpectrum=>\%spectrum, massType=>getMassType());
    my $len = $theoSpectrum->getPeptideLength();
    print "matchSpectrumGreedy for $peptide (",modifToString($peptide->modif(),$len),")\nOrder given => each peak is used once only; see the impact on the first y++ and immo(L)\ntol = 10000 ppm, minTol = 2 Da\nFragments:\n";
    foreach ($theoSpectrum->getTermIons()){
      print "$_\n";
    }
    foreach ($theoSpectrum->getInternIons()){
      print "$_\n";
    }
  }
};
if ($@){
  carp($@);
}
