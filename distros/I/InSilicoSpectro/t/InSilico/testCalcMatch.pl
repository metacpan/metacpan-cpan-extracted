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


=head1 testCalcMatch.pl

This test and example program illustrates the use of the methods matchSpectrumClosest and
matchSpectrumGreedy.

The way the fragment are output makes no attempt to improve user readability, it
directly reflects the data structure returned by getFragmentMasses and the match
methods (see their documentations via perldoc MassCalculator.pm). User friendly
outputs are the responsability of the module MSMSOutput.pm, see the corresponding
examples.

=cut

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}

use strict;
use Carp;
use InSilicoSpectro;
use InSilicoSpectro::InSilico::MassCalculator;

eval{
  InSilicoSpectro::init();
  my $test = shift;

  if ($test == 1){
    # Test 1, matchSpectrumCLosest. Note that we pre-compute the theoretical spectrum in this example,
    # which is not mandatory. See test 2 for the alternative choice of letting the match function
    # call getFragmentMasses behind the scene.
    my %spectrum;
    my $peptide = 'HCMSKPQMLR';
    my $modif = '::Cys_CAM::::::Oxidation:::';
    getFragmentMasses(pept=>$peptide, modif=>$modif, fragTypes=>['b','a','b-NH3*','b-H2O*','b++','y','y-NH3*','y-H2O*','y++','immo'], spectrum=>\%spectrum);
    # Artificial experimental spectrum
    my @exp = ([87,1000],[87.5, 100],[330.6,1000], [429, 800], [435, 200], [488, 900], [551, 750], [727, 200]);
    matchSpectrumClosest(spectrum=>\%spectrum, expSpectrum=>\@exp);
    print "matchSpectrumCLosest for $peptide ($modif).\nFragments:\n";
    my $len = length($peptide);
    # N-/C-terminal fragments
    foreach my $frag (keys(%{$spectrum{mass}{term}})){
      for (my $i = 0; $i < @{$spectrum{ionType}{$frag}}; $i++){
	print $spectrum{ionType}{$frag}[$i];
	for (my $j = $i*$len; $j < ($i+1)*$len; $j++){
	  print "\t", $spectrum{mass}{term}{$frag}[$j]+0.0;
	  if (defined($spectrum{match}{term}{$frag}[$j])){
	    print "-matched($spectrum{match}{term}{$frag}[$j][0])";
	  }
	}
	print "\n";
      }
    }
    # Internal fragments (immonium only so far)
    foreach my $frag (keys(%{$spectrum{mass}{intern}})){
      print $spectrum{ionType}{$frag}[0];
      foreach my $aa (keys(%{$spectrum{mass}{intern}{$frag}})){
	print "\t$aa\t$spectrum{mass}{intern}{$frag}{$aa}";
	if (defined($spectrum{match}{intern}{$frag}{$aa})){
	  print "-matched($spectrum{match}{intern}{$frag}{$aa}[0])";
	}
      }
      print "\n";
    }
  }

  if ($test == 2){
    # Test 2, matchSpectrumGreedy. Note that we no longer pre-compute the theoretical spectrum in
    # this example to illustrate this alternative possibility.
    my %spectrum;
    my $peptide = 'HCMSKPQMLR';
    my $modif = '::Cys_CAM::::::Oxidation:::';
    my @exp = ([87,1000],[87.5, 100],[330.6,1000], [429, 800], [435, 200], [488, 900], [551, 750], [727, 200]);
    matchSpectrumGreedy(pept=>$peptide, modif=>$modif, fragTypes=>['b','a','b-NH3*','b-H2O*','b++','y','y-NH3*','y-H2O*','y++','immo'], spectrum=>\%spectrum, expSpectrum=>\@exp, tol=>10000, minTol=>2);
    print "matchSpectrumGreedy for $peptide ($modif).\nNo order given => returns the most intense peak in the mass window; see the impact on the first y++.\ntol = 10000 ppm, minTol = 2 Da.\nFragments:\n";
    my $len = length($peptide);
    # N-/C-terminal fragments
    foreach my $frag (keys(%{$spectrum{mass}{term}})){
      for (my $i = 0; $i < @{$spectrum{ionType}{$frag}}; $i++){
	print $spectrum{ionType}{$frag}[$i];
	for (my $j = $i*$len; $j < ($i+1)*$len; $j++){
	  print "\t", $spectrum{mass}{term}{$frag}[$j]+0.0;
	  if (defined($spectrum{match}{term}{$frag}[$j])){
	    print "-matched($spectrum{match}{term}{$frag}[$j][0])";
	  }
	}
	print "\n";
      }
    }
    # Internal fragments (immonium only so far)
    foreach my $frag (keys(%{$spectrum{mass}{intern}})){
      print $spectrum{ionType}{$frag}[0];
      foreach my $aa (keys(%{$spectrum{mass}{intern}{$frag}})){
	print "\t$aa\t$spectrum{mass}{intern}{$frag}{$aa}";
	if (defined($spectrum{match}{intern}{$frag}{$aa})){
	  print "-matched($spectrum{match}{intern}{$frag}{$aa}[0])";
	}
      }
      print "\n";
    }
  }

  if ($test == 3){
    # Test 3, matchSpectrumGreedy again! We use the real greedy match this time with an order given.
    my %spectrum;
    my $peptide = 'HCMSKPQMLR';
    my $modif = '::Cys_CAM::::::Oxidation:::';
    my @exp = ([87,1000],[87.5, 100],[330.6,1000], [429, 800], [435, 200], [488, 900], [551, 750], [727, 200]);
    matchSpectrumGreedy(pept=>$peptide, modif=>$modif, fragTypes=>['b','a','b-NH3*','b-H2O*','b++','y','y-NH3*','y-H2O*','y++','immo'], spectrum=>\%spectrum, expSpectrum=>\@exp, tol=>10000, minTol=>2, order=>['immo','y','b','y++','b-NH3*','b-H2O*','b++','y-NH3*','y-H2O*','z']);
    print "matchSpectrumGreedy for $peptide ($modif).\nOrder given => each peak is used once only; see the impact on the first y++ and immo(L).\ntol = 10000 ppm, minTol = 2 Da.\nFragments:\n";
    my $len = length($peptide);
    # N-/C-terminal fragments
    foreach my $frag (keys(%{$spectrum{mass}{term}})){
      for (my $i = 0; $i < @{$spectrum{ionType}{$frag}}; $i++){
	print $spectrum{ionType}{$frag}[$i];
	for (my $j = $i*$len; $j < ($i+1)*$len; $j++){
	  print "\t", $spectrum{mass}{term}{$frag}[$j]+0.0;
	  if (defined($spectrum{match}{term}{$frag}[$j])){
	    print "-matched($spectrum{match}{term}{$frag}[$j][0])";
	  }
	}
	print "\n";
      }
    }
    # Internal fragments (immonium only so far)
    foreach my $frag (keys(%{$spectrum{mass}{intern}})){
      print $spectrum{ionType}{$frag}[0];
      foreach my $aa (keys(%{$spectrum{mass}{intern}{$frag}})){
	print "\t$aa\t$spectrum{mass}{intern}{$frag}{$aa}";
	if (defined($spectrum{match}{intern}{$frag}{$aa})){
	  print "-matched($spectrum{match}{intern}{$frag}{$aa}[0])";
	}
      }
      print "\n";
    }
  }
};
if ($@){
  carp($@);
}
