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
use InSilicoSpectro::InSilico::AASequence;
use InSilicoSpectro::InSilico::CleavEnzyme;
use InSilicoSpectro::Spectra::ExpSpectrum;
use InSilicoSpectro::Spectra::PeakDescriptor;
use InSilicoSpectro::InSilico::Peptide;
use InSilicoSpectro::InSilico::PMFMatch;

eval{
  InSilicoSpectro::init();
  my $test = shift;

  if ($test == 1){
    # Test 1, match a BSA mass list (in meuh.pkl) with BSA theoretical spectrum. Tolerance given.
    my $tol = 250;
    my $proteinSeq = 'MKWVTFISLLLLFSSAYSRGVFRRDTHKSEIAHRFKDLGEEHFKGLVLIAFSQYLQQCPFDEHVKLVNELTEFAKTCVADESHAGCEKSLHTLFGDELCKVASLRETYGDMADCCEKQEPERNECFLSHKDDSPDLPKLKPDPNTLCDEFKADEKKFWGKYLYEIARRHPYFYAPELLYYANKYNGVFQECCQAEDKGACLLPKIETMREKVLASSARQRLRCASIQKFGERALKAWSVARLSQKFPKAEFVEVTKLVTDLTKVHKECCHGDLLECADDRADLAKYICDNQDTISSKLKECCDKPLLEKSHCIAEVEKDAIPENLPPLTADFAEDKDVCKNYQEAKDAFLGSFLYEYSRRHPEYAVSVLLRLAKEYEATLEECCAKDDPHACYSTVFDKLKHLVDEPQNLIKQNCDQFEKLGEYGFQNALIVRYTRKVPQVSTPTLVEVSRSLGKVGTRCCTKPESERMPCTEDYLSLILNRLCVLHEKTPVSEKVTKCCTESLVNRRPCFSALTPDETYVPKAFDEKLFTFHADICTLPDTEKQIKKQTALVELLKHKPKATEEQLKTVMENFVAFVDKCCAADDKEACFAVEGPKLVVSTQTALA';
    my @modif;
    locateModif($proteinSeq, undef, ['Cys_CAM'], undef, \@modif);
    my $protein = new InSilicoSpectro::InSilico::AASequence(sequence=>$proteinSeq, modif=>\@modif, AC=>'123', ID=>'BSA');
    my @result = digestByRegExp(protein=>$protein, nmc=>1, addProton=>1, enzyme=>InSilicoSpectro::InSilico::CleavEnzyme::getFromDico('Trypsin'));

    my @spectrum;
    open(P, './meuh.pkl');
    while (<P>){
      chomp;
      my ($mass, $height) = split(/[\s,]+/);
      push(@spectrum, [$mass, $height]);
    }
    close(P);
    my $pd = new InSilicoSpectro::Spectra::PeakDescriptor(['mass', 'intensity']);
    my $spectrum = new InSilicoSpectro::Spectra::ExpSpectrum(spectrum=>\@spectrum, peakDescriptor=>$pd);
    my $massIndex = $pd->getFieldIndex('mass');
    my $intensityIndex = $pd->getFieldIndex('intensity');

    print "Match with BSA, tol=$tol ppm, minTol=0.1 Da (most intense peak in the mass window):\n";
    my $match = new InSilicoSpectro::InSilico::PMFMatch(match=>[matchPMF(expSpectrum=>$spectrum, digestResult=>\@result, sorted=>1, tol=>$tol)], expSpectrum=>$spectrum, digestResult=>\@result);
    foreach ($match->getMatchedPeaks()){
      print join("\t", $_->[$pmfMatchRelErrorIndex], $_->[$pmfMatchPeptideIndex], $_->[$pmfMatchPeptideIndex]->getMass(), $_->[$pmfMatchPeakIndex][$massIndex], $_->[$pmfMatchPeptideIndex]->nmc()),"\n";
    }
    print "The unmatched peaks were:\n";
    foreach ($match->getUnmatchedPeaks()){
      print "$_->[$massIndex], $_->[$intensityIndex]\n";
    }
    print "The unmatched peptides were:\n";
    foreach ($match->getUnmatchedPeptides()){
      print join("\t", $_, $_->getMass(), $_->start(), $_->end(), $_->nmc()),"\n";
    }
  }

  if ($test == 2){
    # Test 2, match a BSA mass list (in meuh.pkl) with BSA theoretical spectrum. No tolerance given.
    my $tol = 250;
    my $proteinSeq = 'MKWVTFISLLLLFSSAYSRGVFRRDTHKSEIAHRFKDLGEEHFKGLVLIAFSQYLQQCPFDEHVKLVNELTEFAKTCVADESHAGCEKSLHTLFGDELCKVASLRETYGDMADCCEKQEPERNECFLSHKDDSPDLPKLKPDPNTLCDEFKADEKKFWGKYLYEIARRHPYFYAPELLYYANKYNGVFQECCQAEDKGACLLPKIETMREKVLASSARQRLRCASIQKFGERALKAWSVARLSQKFPKAEFVEVTKLVTDLTKVHKECCHGDLLECADDRADLAKYICDNQDTISSKLKECCDKPLLEKSHCIAEVEKDAIPENLPPLTADFAEDKDVCKNYQEAKDAFLGSFLYEYSRRHPEYAVSVLLRLAKEYEATLEECCAKDDPHACYSTVFDKLKHLVDEPQNLIKQNCDQFEKLGEYGFQNALIVRYTRKVPQVSTPTLVEVSRSLGKVGTRCCTKPESERMPCTEDYLSLILNRLCVLHEKTPVSEKVTKCCTESLVNRRPCFSALTPDETYVPKAFDEKLFTFHADICTLPDTEKQIKKQTALVELLKHKPKATEEQLKTVMENFVAFVDKCCAADDKEACFAVEGPKLVVSTQTALA';
    my @modif;
    locateModif($proteinSeq, undef, ['Cys_CAM'], undef, \@modif);
    my $protein = new InSilicoSpectro::InSilico::AASequence(sequence=>$proteinSeq, modif=>\@modif, AC=>'123', ID=>'BSA');
    my @result = digestByRegExp(protein=>$protein, nmc=>1, addProton=>1, enzyme=>InSilicoSpectro::InSilico::CleavEnzyme::getFromDico('Trypsin'));

    my @spectrum;
    open(P, './meuh.pkl');
    while (<P>){
      chomp;
      my ($mass, $height) = split(/[\s,]+/);
      push(@spectrum, [$mass, $height]);
    }
    close(P);
    my $pd = new InSilicoSpectro::Spectra::PeakDescriptor(['mass', 'intensity']);
    my $spectrum = new InSilicoSpectro::Spectra::ExpSpectrum(spectrum=>\@spectrum, peakDescriptor=>$pd);
    my $massIndex = $pd->getFieldIndex('mass');
    my $intensityIndex = $pd->getFieldIndex('intensity');

    my $match = new InSilicoSpectro::InSilico::PMFMatch(match=>[matchPMF(expSpectrum=>$spectrum, digestResult=>\@result, sorted=>1)], expSpectrum=>$spectrum, digestResult=>\@result);
    print '-'x 40, "\n\nMatch with BSA, no tolerance (returns closest peak), we use 1000 ppm and 0.1 Da a posteriori:\n";
    foreach ($match->getMatchedPeaks(1000)){
      print join("\t", $_->[$pmfMatchRelErrorIndex], $_->[$pmfMatchPeptideIndex], $_->[$pmfMatchPeptideIndex]->getMass(), $_->[$pmfMatchPeakIndex][$massIndex], $_->[$pmfMatchPeptideIndex]->nmc()),"\n";
    }
    print "The unmatched peaks were:\n";
    foreach ($match->getUnmatchedPeaks(1000)){
      print "$_->[$massIndex], $_->[$intensityIndex]\n";
    }
    print "The unmatched peptides were:\n";
    foreach ($match->getUnmatchedPeptides(1000)){
      print join("\t", $_, $_->getMass(), $_->start(), $_->end(), $_->nmc()),"\n";
    }
  }
};
if ($@){
  carp($@);
}
