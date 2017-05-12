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


=head1 testCalcFrag.pl

This test and example program illustrates the use of the method getFragmentMasses.
The way the fragment are output makes no attempt to improve user readability, it
directly reflects the data structure returned by getFragmentMasses (see its documentation
via perldoc MassCalculator.pm). User friendly outputs are the responsability of the
module MSMSOutput.pm, see the corresponding examples.

=cut

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}print @INC;
use Cwd;
use strict;
use Carp;
use InSilicoSpectro;
use InSilicoSpectro::InSilico::MassCalculator;

eval{
  InSilicoSpectro::init();
  my $test = shift;

  if ($test == 1){
    # Test 1
    my %spectrum;
    my $peptide = 'HCMSKPSMLR';
    my $modif = '::Cys_CAM::::::Oxidation:::';
    getFragmentMasses(pept=>$peptide, modif=>$modif, fragTypes=>['b','a','b-H2O*-NH3*','b++','y','y-H2O*-NH3*','y++','immo'], spectrum=>\%spectrum);
    print "Fragments of $peptide ($modif, $spectrum{peptideMass} Da):\n";
    my $len = length($peptide);

    # N-/C-terminal fragments
    foreach my $frag (keys(%{$spectrum{mass}{term}})){
      for (my $i = 0; $i < @{$spectrum{ionType}{$frag}}; $i++){
	print $spectrum{ionType}{$frag}[$i];
	for (my $j = $i*$len; $j < ($i+1)*$len; $j++){
	  print "\t", $spectrum{mass}{term}{$frag}[$j]+0.0;
	}
	print "\n";
      }
    }
    # Internal fragments (immonium only so far)
    foreach my $frag (keys(%{$spectrum{mass}{intern}})){
      print $spectrum{ionType}{$frag}[0];
      foreach my $aa (keys(%{$spectrum{mass}{intern}{$frag}})){
	print "\t$aa\t$spectrum{mass}{intern}{$frag}{$aa}";
      }
      print "\n";
    }
  }

  if ($test == 2){
    # Test 2, the same by specifying the modifs via a vector
    my %spectrum;
    my $peptide = 'HCMSKPSMLR';
    my $modif = '::Cys_CAM::::::Oxidation:::';
    my @modif = split(/:/, $modif);
    getFragmentMasses(pept=>$peptide, modif=>\@modif, fragTypes=>['b','a','b-H2O*-NH3*','b++','y','y-H2O*-NH3*','y++','immo'], spectrum=>\%spectrum);
    print "Same test but modifs as a vector (only outputs the terminal fragments):\n";
    my $len = length($peptide);

    # N-/C-terminal fragments
    foreach my $frag (keys(%{$spectrum{mass}{term}})){
      for (my $i = 0; $i < @{$spectrum{ionType}{$frag}}; $i++){
	print $spectrum{ionType}{$frag}[$i];
	for (my $j = $i*$len; $j < ($i+1)*$len; $j++){
	  print "\t", $spectrum{mass}{term}{$frag}[$j]+0.0;
	}
	print "\n";
      }
    }
  }
};
if ($@){
  carp($@);
}
