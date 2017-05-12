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


=head1 testCalcPMFMatch.pl [configfile(s)]

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
    # Test 1, match a BSA mass list (in meuh.pkl) with BSA theoretical spectrum. Tolerance given.
    my $tol = 250;
    my $protein = 'MKWVTFISLLLLFSSAYSRGVFRRDTHKSEIAHRFKDLGEEHFKGLVLIAFSQYLQQCPFDEHVKLVNELTEFAKTCVADESHAGCEKSLHTLFGDELCKVASLRETYGDMADCCEKQEPERNECFLSHKDDSPDLPKLKPDPNTLCDEFKADEKKFWGKYLYEIARRHPYFYAPELLYYANKYNGVFQECCQAEDKGACLLPKIETMREKVLASSARQRLRCASIQKFGERALKAWSVARLSQKFPKAEFVEVTKLVTDLTKVHKECCHGDLLECADDRADLAKYICDNQDTISSKLKECCDKPLLEKSHCIAEVEKDAIPENLPPLTADFAEDKDVCKNYQEAKDAFLGSFLYEYSRRHPEYAVSVLLRLAKEYEATLEECCAKDDPHACYSTVFDKLKHLVDEPQNLIKQNCDQFEKLGEYGFQNALIVRYTRKVPQVSTPTLVEVSRSLGKVGTRCCTKPESERMPCTEDYLSLILNRLCVLHEKTPVSEKVTKCCTESLVNRRPCFSALTPDETYVPKAFDEKLFTFHADICTLPDTEKQIKKQTALVELLKHKPKATEEQLKTVMENFVAFVDKCCAADDKEACFAVEGPKLVVSTQTALA';
    my @modif;
    locateModif($protein, undef, ['Cys_CAM'], undef, \@modif);
    my @result = digestByRegExp(protein=>$protein, modif=>\@modif, nmc=>1, addProton=>1);
    my @spectrum;
    open(P, './meuh.pkl');
    while (<P>){
      chomp;
      my ($mass, $height) = split(/[\s,]+/);
      push(@spectrum, [$mass, $height]);
    }
    close(P);

    print "Match with BSA, tol=$tol ppm, minTol=0.1 Da (most intense peak in the mass window):\n";
    my @match = matchPMF(expSpectrum=>\@spectrum, digestResult=>\@result, sorted=>1, tol=>$tol);
    for (my $i = 0; $i < @match; $i++){
      if (defined($match[$i])){
	my $theoMass = $result[$digestIndexMass][$i];
	my $expMass = $match[$i][0];
	my $error = ($expMass-$theoMass)/($expMass+$theoMass)*2.0e6;
	print "$error\t$result[$digestIndexPept][$i]\t$theoMass\t$expMass\t$result[$digestIndexNmc][$i]\n";

      }
    }
  }

  if ($test == 2){
    # Test 2, match a BSA mass list (in meuh.pkl) with BSA theoretical spectrum. No tolerance given.
    my $tol = 250;
    my $protein = 'MKWVTFISLLLLFSSAYSRGVFRRDTHKSEIAHRFKDLGEEHFKGLVLIAFSQYLQQCPFDEHVKLVNELTEFAKTCVADESHAGCEKSLHTLFGDELCKVASLRETYGDMADCCEKQEPERNECFLSHKDDSPDLPKLKPDPNTLCDEFKADEKKFWGKYLYEIARRHPYFYAPELLYYANKYNGVFQECCQAEDKGACLLPKIETMREKVLASSARQRLRCASIQKFGERALKAWSVARLSQKFPKAEFVEVTKLVTDLTKVHKECCHGDLLECADDRADLAKYICDNQDTISSKLKECCDKPLLEKSHCIAEVEKDAIPENLPPLTADFAEDKDVCKNYQEAKDAFLGSFLYEYSRRHPEYAVSVLLRLAKEYEATLEECCAKDDPHACYSTVFDKLKHLVDEPQNLIKQNCDQFEKLGEYGFQNALIVRYTRKVPQVSTPTLVEVSRSLGKVGTRCCTKPESERMPCTEDYLSLILNRLCVLHEKTPVSEKVTKCCTESLVNRRPCFSALTPDETYVPKAFDEKLFTFHADICTLPDTEKQIKKQTALVELLKHKPKATEEQLKTVMENFVAFVDKCCAADDKEACFAVEGPKLVVSTQTALA';
    my @modif;
    locateModif($protein, undef, ['Cys_CAM'], undef, \@modif);
    my @result = digestByRegExp(protein=>$protein, modif=>\@modif, nmc=>1, addProton=>1);
    my @spectrum;
    open(P, './meuh.pkl');
    while (<P>){
      chomp;
      my ($mass, $height) = split(/[\s,]+/);
      push(@spectrum, [$mass, $height]);
    }
    close(P);

    my @match = matchPMF(expSpectrum=>\@spectrum, digestResult=>\@result, sorted=>1);
    print "Match with BSA, no tolerance (returns closest peak), we use 1000 ppm a posteriori:\n";
    for (my $i = 0; $i < @{$result[$digestIndexMass]}; $i++){
      my $theoMass = $result[$digestIndexMass][$i];
      my $expMass = $match[$i][0];
      if ((abs(my $error = ($expMass-$theoMass)/($expMass+$theoMass)*2.0e6)) <= 1000){
	print "$error\t$result[$digestIndexPept][$i]\t$theoMass\t$expMass\t$result[$digestIndexNmc][$i]\n";
      }
    }
  }

  if ($test == 3){
    # Test 3, match a BSA mass list (in meuh.pkl) with BSA theoretical spectrum. Half tryptic digestion.
    my $tol = 250;
    my $protein = 'MKWVTFISLLLLFSSAYSRGVFRRDTHKSEIAHRFKDLGEEHFKGLVLIAFSQYLQQCPFDEHVKLVNELTEFAKTCVADESHAGCEKSLHTLFGDELCKVASLRETYGDMADCCEKQEPERNECFLSHKDDSPDLPKLKPDPNTLCDEFKADEKKFWGKYLYEIARRHPYFYAPELLYYANKYNGVFQECCQAEDKGACLLPKIETMREKVLASSARQRLRCASIQKFGERALKAWSVARLSQKFPKAEFVEVTKLVTDLTKVHKECCHGDLLECADDRADLAKYICDNQDTISSKLKECCDKPLLEKSHCIAEVEKDAIPENLPPLTADFAEDKDVCKNYQEAKDAFLGSFLYEYSRRHPEYAVSVLLRLAKEYEATLEECCAKDDPHACYSTVFDKLKHLVDEPQNLIKQNCDQFEKLGEYGFQNALIVRYTRKVPQVSTPTLVEVSRSLGKVGTRCCTKPESERMPCTEDYLSLILNRLCVLHEKTPVSEKVTKCCTESLVNRRPCFSALTPDETYVPKAFDEKLFTFHADICTLPDTEKQIKKQTALVELLKHKPKATEEQLKTVMENFVAFVDKCCAADDKEACFAVEGPKLVVSTQTALA';
    my @modif;
    locateModif($protein, undef, ['Cys_CAM'], undef, \@modif);
    my @result = nonSpecificDigestion(protein=>$protein, modif=>\@modif, enzyme=>$trypsinRegex, minMass=>800, addProton=>1);
    my @spectrum;
    open(P, './meuh.pkl');
    while (<P>){
      chomp;
      my ($mass, $height) = split(/[\s,]+/);
      push(@spectrum, [$mass, $height]);
    }
    close(P);

    my @match = matchPMF(expSpectrum=>\@spectrum, digestResult=>\@result, sorted=>1, tol=>$tol);
    print "Match with BSA, tol=$tol ppm, minTol=0.1 Da (most intense peak in the mass window)\nHalf tryptic digestion\n";
    for (my $i = 0; $i < @{$result[$digestIndexMass]}; $i++){
      my $theoMass = $result[$digestIndexMass][$i];
      my $expMass = $match[$i][0];
      if ((abs(my $error = ($expMass-$theoMass)/($expMass+$theoMass)*2.0e6)) <= 1000){
	print "$error\t$result[$digestIndexPept][$i]\t$theoMass\t$expMass\t$result[$digestIndexNmc][$i]\n";
      }
    }
  }
};
if ($@){
  carp($@);
}
