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

This test and example program illustrates the use of the digestion functions.
It also illustrates how fixed modifications can be set either at predifined
locations or via the general rule that comes with a modification.

Depending on the example, the returned peptides are accompagnied by either precisely
located modifications (for MS/MS) or by a count of the modifications (for PMF).

How to manage with variable modifications is examplified elsewhere.

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
    # Test 1, protein sequence with localized fixed modifications, tryptic digestion
    my $protein = 'MCTMACTKGIPRKQWWEMMKPCKADFCV';
    my $modif =   '::Cys_CAM::Oxidation::::::::::::::Oxidation:::::::::::';
    print "Protein:\n$protein\n$modif\n\nTryptic digestion with up to 2 missed cleavages:\n";
    my @result = digestByRegExp(protein=>$protein, modif=>$modif, methionine=>1, nmc=>2);
    for (my $i = 0; $i < @{$result[0]}; $i++){
      print "$result[$digestIndexPept][$i]\t$result[$digestIndexStart][$i]\t",
	"$result[$digestIndexEnd][$i]\t$result[$digestIndexNmc][$i]\t",
          "$result[$digestIndexMass][$i]\t", modifToString($result[$digestIndexModif][$i]), "\n";
    }
  }

  if ($test == 2){
    # Test 2, trypsin regexp given by a string
    my $protein = 'MCTMAPCTKGIPRKQWWEMMKPCKADFCV';
    my $modif =   '::Cys_CAM::Oxidation:::::::::::::::Oxidation:::::::::::';
    print "Protein:\n$protein\n$modif\n\nTrypsin/P regexp given by a string:\n";
    my @result = digestByRegExp(protein=>$protein, modif=>$modif, methionine=>1, nmc=>1, enzyme=>'(?<=[KR])|(?=P)', minMass=>0);
    for (my $i = 0; $i < @{$result[0]}; $i++){
      print "$result[$digestIndexPept][$i]\t$result[$digestIndexStart][$i]\t",
	    "$result[$digestIndexEnd][$i]\t$result[$digestIndexNmc][$i]\t",
            "$result[$digestIndexMass][$i]\t", modifToString($result[$digestIndexModif][$i]), "\n";
    }
  }

  if ($test == 3){
    # Test 3, protein sequence with localized fixed modifications, half-tryptic digestion, modifications are counted only (PMF)
    my $protein = 'MCTMACTKGIPRKQWWCM';
    my $modif =   '::Cys_CAM::Oxidation::::::::::::::Oxidation:';
    print "Protein:\n$protein\n$modif\n\nHalf-tryptic digestion:\n";
    my @result = nonSpecificDigestion(protein=>$protein, modif=>$modif, enzyme=>$trypsinRegex, pmf=>1);
    for (my $i = 0; $i < @{$result[0]}; $i++){
      print "$result[$digestIndexPept][$i]\t$result[$digestIndexStart][$i]\t",
            "$result[$digestIndexEnd][$i]\t$result[$digestIndexNmc][$i]\t",
	    "$result[$digestIndexMass][$i]\t", modifToString($result[$digestIndexModif][$i]), "\n";
    }
  }

  if ($test == 4){
    # Test 4, protein sequence with localized fixed modifications, non-specific digestion
    my $protein = 'MCTMACTKGIPRKQWWCM';
    my $modif =   '::Cys_CAM::Oxidation::::::::::::::Oxidation:';
    print "Protein:\n$protein\n$modif\n\nNon-specific digestion:\n";
    my @result = nonSpecificDigestion(protein=>$protein, modif=>$modif);
    for (my $i = 0; $i < @{$result[0]}; $i++){
      print "$result[$digestIndexPept][$i]\t$result[$digestIndexStart][$i]\t",
            "$result[$digestIndexEnd][$i]\t$result[$digestIndexNmc][$i]\t",
	    "$result[$digestIndexMass][$i]\t", modifToString($result[$digestIndexModif][$i]), "\n";
    }
  }

  if ($test == 5){
    # Test 5, protein sequence with fixed modifications, tryptic digestion
    my $protein = 'MKWVHHMTFISLLLLFSSAYSRGVFRRDTHKSEIAHRFKDLGEEHFKGLVLIAFSQYLQQCPFDEHVKLVNELTEFAKTCVADESHAGCEKSLHTLFGDELCKVASLRETYGDMADCCEKQEPERNECFLSHKDDSPDLPKLKPDPNTLCDEFKADEKKFWGKYLYEIARRHPYFYAPELLYYANKYNGVFQECCQAEDKGACLLPKIETMREKVLASSARQRLRCASIQKFGERALKAWSVARLSQKFPKAEFVEVTKLVTDLTKVHKECCHGDLLECADDRADLAKYICDNQDTISSKLKECCDKPLLEKSHCIAEVEKDAIPENLPPLTADFAEDKDVCKNYQEAKDAFLGSFLYEYSRRHPEYAVSVLLRLAKEYEATLEECCAKDDPHACYSTVFDKLKHLVDEPQNLIKQNCDQFEKLGEYGFQNALIVRYTRKVPQVSTPTLVEVSRSLGKVGTRCCTKPESERMPCTEDYLSLILNRLCVLHEKTPVSEKVTKCCTESLVNRRPCFSALTPDETYVPKAFDEKLFTFHADICTLPDTEKQIKKQTALVELLKHKPKATEEQLKTVMENFVAFVDKCCAADDKEACFAVEGPKLVVSTQTALAK';
    # We localize the fixed modifications by using the function locateModif
    my (@modif, @modifVect);
    $modif[length($protein)+1] = 'BIOT';
    locateModif($protein, \@modif, ['Cys_CAM','Oxidation_M'], ['Oxidation','DEAM_Q'], \@modifVect);
    print "Protein:\n$protein\n",join(',',@modifVect),"\n\nTryptic digestion, up to 1 missed cleavage:\n";
    my @result = digestByRegExp(protein=>$protein, modif=>\@modifVect, nmc=>1, pmf=>1);
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
