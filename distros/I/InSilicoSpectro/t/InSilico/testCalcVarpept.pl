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

=head1 testCalcVarpept.pl [configfile(s)]

This test/example program illustrates the computation of fixed/variable modifications either
localized or via general modification rules. Both MS/MS and PMF ways of reporting
modifications are examplified. In the case of PMF, the total mass delta of each modification
combination is reported after the modification string.

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
    # Test 1, in view of MS/MS
    my $peptide = 'KCGQVSTPTCK';
    my $modif =   ':::::::PHOS::(*)PHOS,Oxidation:::';
    my @modif = split(/:/, $modif);
    my $len = length($peptide);
    my @fixed = ('Cys_CAM');
    my @variable = ('PHOS','BIOT');

    print "MS/MS\nPeptide: $peptide\nLocalized modifications: $modif\n";
    print "Fixed modifications: ", join(',', @fixed), "\n";
    print "Variable modifications: ", join(',', @variable), "\n";
    print "\nModification combinations:\n";
    my @list = variablePeptide(pept=>$peptide, modif=>\@modif, varModif=>\@variable, fixedModif=>\@fixed);
    foreach (@list){
      print modifToString($_, $len),"\n";
    }
    print "There were ",scalar(@list)," combinations\n";
  }

  if ($test == 2){
    # Test 2, in view of PMF
    my $peptide = 'KCGQVSTPTCK';
    my $modif =   ':::::::PHOS::(*)PHOS,Oxidation:::';
    my @modif = split(/:/, $modif);
    my $len = length($peptide);
    my @fixed = ('Cys_CAM');
    my @variable = ('PHOS','BIOT');

    print "PMF\nPeptide: $peptide\nLocalized modifications: $modif\n";
    print "Fixed modifications: ", join(',', @fixed), "\n";
    print "Variable modifications: ", join(',', @variable), "\n";
    print "\nModification combinations:\n";
    my @list = variablePeptide(pept=>$peptide, modif=>\@modif, varModif=>\@variable, fixedModif=>\@fixed, pmf=>1);
    for (my $i = 0; $i < @list; $i += 2){
      print modifToString($list[$i]), " --> $list[$i+1] Da\n";
    }
    print "There were ",int(scalar(@list)/2)," combinations\n";
  }

  if ($test == 3){
    # Test 3, compatibility with the digestion routines
    my $protein = 'MCTMACTKGIPRKQWWCM';
    my $modif =   ':::::::::::::::::::(*)BIOT';
    print "Tryptic digestion of a protein with variable modifications
Protein:\n$protein\n$modif
fixed: CysCAM
variable: Oxidation_M\n";
    my @result = digestByRegExp(protein=>$protein, modif=>$modif, fixedModif=>['Cys_CAM'], varModif=>['Oxidation_M'], nmc=>1);
    for (my $i = 0; $i < @{$result[0]}; $i++){
      print "$result[$digestIndexPept][$i]\t$result[$digestIndexStart][$i]\t",
	"$result[$digestIndexEnd][$i]\t$result[$digestIndexNmc][$i]\t",
	  "$result[$digestIndexMass][$i]\t", modifToString($result[$digestIndexModif][$i]), "\n";
    }
  }

  if ($test == 4){
    # Test 4, the same for PMF
    my $protein = 'MCTMACTKGIPRKQWWCM';
    my $modif =   ':::::::::::::::::::(*)BIOT';
    print "The same example but for PMF:\n";
    my @result = digestByRegExp(protein=>$protein, modif=>$modif, fixedModif=>['Cys_CAM'], varModif=>['Oxidation_M'], nmc=>1, pmf=>1);
    for (my $i = 0; $i < @{$result[0]}; $i++){
      print "$result[$digestIndexPept][$i]\t$result[$digestIndexStart][$i]\t",
	"$result[$digestIndexEnd][$i]\t$result[$digestIndexNmc][$i]\t",
	  "$result[$digestIndexMass][$i]\t", modifToString($result[$digestIndexModif][$i]), "\n";
    }
  }
};
if ($@){
  carp($@);
}
