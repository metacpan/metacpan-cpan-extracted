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

use strict;
use CGI qw(:standard);

$|=1;

BEGIN{
  use File::Basename;
  push @INC, basename($0);
  use CGIUtils;
}

my $protSeq = param('protSeq');
my $massList = param('massList');
my $enzymeSel = param('enzymeSel');
my $massIndex = param('massIndex');
my $intensityIndex = param('intensityIndex');
my $tol = param('tol');
my $minTol = param('minTol');
my $nmc = param('nmc');
my $addProton = param('addProton');
my $minMass = param('minMass');
my $maxMass = param('maxMass');
my $minLength = param('minLength');
my $maxLength = param('maxLength');
my $enzymatic = param('enzymatic');
my $monoisotopic = param('monoisotopic');
my $matchedOnly = param('matchedOnly');
my $fixedModif = param('fixedModif');
my $varModif = param('varModif');
my $mostIntense = param('mostIntense');
my $pmf = param('pmf');

use InSilicoSpectro;
use InSilicoSpectro::InSilico::CleavEnzyme;
use InSilicoSpectro::InSilico::ModRes;
use InSilicoSpectro::InSilico::MassCalculator;
use InSilicoSpectro::InSilico::MSMSOutput;
use InSilicoSpectro::InSilico::AASequence;

my $displayWidth = 60;
my $colMatch = '#ffdddd';

InSilicoSpectro::init();
setMassType(defined($monoisotopic) ? 0 : 1);

# Determines sequence
$protSeq =~ s/\s//g;
my (@modif, $protein);
if ((length($protSeq) < 15) && (($protSeq =~ /[A-Z0-9]+_[A-Z0-9]+/) || ($protSeq =~ /\d+/))){
  # Assumes either an ID or an AC
  eval{
    require Bio::Perl;
    my $bpseq = Bio::Perl::get_sequence('swiss', $protSeq) || CORE::die("cannot access [$protSeq] on remote DB");
    my $seq = InSilicoSpectro::InSilico::AASequence->new($bpseq);
    $protein = $seq->sequence();
  };
  if ($@){
    htmlError($@);
  }
}
else{
  # Extracts modifications
  my @seq = split(//, $protSeq);
  my $pos = 0;
  for (my $i = 0; $i < @seq; $i++){
    if ($seq[$i] eq '{'){
      $i++;
      my $modif;
      for (; ($i < @seq) && ($seq[$i] ne '}'); $i++){
	$modif .= $seq[$i];
      }
      foreach (split(/,/, (index($modif, '(*)') == 0 ? substr($modif, 3) : $modif))){
	if (!defined(InSilicoSpectro::InSilico::ModRes::getFromDico($_))){
	  htmlError("Unknown modification [$_][$modif]");
	}
      }
      $modif[$pos] = $modif;
    }
    else{
      $protein .= $seq[$i] if ($seq[$i] ne '-');
      $pos++,
    }
  }
}

# Prepares mass list
$massList =~ s/\r//g;
my @massList;
if (length($massList) > 20){
  foreach (split(/\n/, $massList)){
    push(@massList, [split(/[\s,]/)]);
  }
  my $nCol = scalar(@{$massList[0]});
  if (($massIndex == $intensityIndex) || ($massIndex >= $nCol) || ($intensityIndex >= $nCol) || ($massIndex < 0) || ($intensityIndex < 0)){
    htmlError("Illegal indices for mass and intensity [$massIndex][$intensityIndex]");
  }
}

if (($tol <= 0) || ($minTol <= 0)){
  htmlError("Illegal tolerance values [$tol][$minTol]");
}
if (($nmc < 0) || ($nmc > 5)){
  htmlError("Illegal value for maximum number of missed cleavages [$nmc]");
}

# Modifications
my @fixedModif = split(/[\s,]+/, $fixedModif);
my @varModif = split(/[\s,]+/, $varModif);
my @modifVect;
locateModif($protein, \@modif, \@fixedModif, \@varModif, \@modifVect);
my $tmpDisplay = join('', annotatePept($protein, \@modifVect, 2));
my $displayProt;
for (my $i = 0; $i < length($tmpDisplay); $i+=$displayWidth){
  $displayProt .= "\n" if ($displayProt);
  $displayProt .= substr($tmpDisplay, $i, $displayWidth);
}

# Digests
my $enzyme = InSilicoSpectro::InSilico::CleavEnzyme::getFromDico($enzymeSel);
if (!defined($enzyme)){
  htmlError("Could not find enzyme [$enzymeSel]");
}
my @result;
if ($enzymatic eq 'fully'){
  @result = digestByRegExp(protein=>$protein, nmc=>$nmc, addProton=>$addProton, enzyme=>$enzyme, modif=>(@modifVect > 0 ? \@modifVect : undef), pmf=>($pmf?1:undef), minMass=>$minMass, maxMass=>$maxMass);
}
else{
  @result = nonSpecificDigestion(protein=>$protein, nmc=>$nmc, addProton=>$addProton, enzyme=>($enzymatic eq 'half' ? $enzyme : undef), modif=>(@modifVect > 0 ? \@modifVect : undef), pmf=>($pmf?1:undef), minMass=>$minMass, maxMass=>$maxMass, minLen=>$minLength, maxLen=>$maxLength);
}

# Match with experimental data
my @match;
if (defined(@massList)){
  @match = matchPMF(expSpectrum=>\@massList, digestResult=>\@result, tol=>(defined($mostIntense) ? $tol : undef), minTol=>$minTol, massIndex=>$massIndex, intensityIndex=>$intensityIndex);
}

print header();
print <<end_of_html;
<html>

<head>

<title>digestor results</title>

<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf-8">
<meta name="description" content="Protein digestion result">
<meta name="keywords" content="enzyme, protein, digestion">

</head>

<body bgcolor=white>
<h1>Digestor results</h1>
Protein sequence:<br>
<pre>$displayProt</pre>
<form name=digestResForm target=_blank action=fragmentatorHome.pl>
<input type=hidden name=peptide>
<input type=hidden name=modif>
<table border=1 cellspacing=0 cellpadding=5>
end_of_html

print "<tr><td align=left><b>Peptide</b></td><td align=right><b>Start</b></td><td align=right><b>Stop</b></td><td align=right><b>MC</b></td><td align=right><b>Mass</b></td><td align=left><b>Modifications</b></td>";
if (defined(@massList)){
  print "<td align=right><b>Error (ppm)</b></td>";
}
if (!$pmf){
  print "<td><b>Frag</b></td>";
}
print "</tr>\n";

my %peptideList;
if (@result){
  for (my $i = 0; $i < @{$result[0]}; $i++) {
    my ($matched, $error);
    if (defined($match[$i])) {
      my $theoMass = $result[$digestIndexMass][$i];
      my $expMass = $match[$i][$massIndex];
      $error = ($expMass-$theoMass)/($expMass+$theoMass)*2.0e6;
      if ((abs($error) <= $tol) || (abs($expMass-$theoMass) <= $minTol)) {
	$matched = 1;
      }
    }
    my $peptide = $result[$digestIndexPept][$i];
    my $modif = modifToString($result[$digestIndexModif][$i]);
    if ($matched) {
      print "<tr><td align=left bgcolor=$colMatch>$peptide</td><td align=right>$result[$digestIndexStart][$i]</td><td align=right>$result[$digestIndexEnd][$i]</td><td align=right>$result[$digestIndexNmc][$i]</td><td align=right>",sprintf("%.3f",$result[$digestIndexMass][$i]),"</td><td align=left>", ($modif || '&nbsp;'), "</td><td align=right bgcolor=$colMatch>",sprintf("%.3f",$error),"</td>";
      $peptideList{$peptide} = 1;
      if (!$pmf) {
	print "<td><input type=submit value=Frag onClick=\"document.digestResForm.peptide.value='$peptide'; document.digestResForm.modif.value='$modif'\"></td>";
      }
      print "</tr>\n";
    }
    elsif (!defined(@massList) || !$matchedOnly) {
      print "<tr><td align=left>$peptide</td><td align=right>$result[$digestIndexStart][$i]</td><td align=right>$result[$digestIndexEnd][$i]</td><td align=right>$result[$digestIndexNmc][$i]</td><td align=right>",sprintf("%.3f",$result[$digestIndexMass][$i]),"</td><td align=left>", ($modif || '&nbsp;'), "</td>";
      $peptideList{$peptide} = 1;
      if (defined(@massList)) {
	print "<td align=right>&nbsp;</td>";
      }
      if (!$pmf) {
	print "<td><input type=submit value=Frag onClick=\"document.digestResForm.peptide.value='$peptide'; document.digestResForm.modif.value='$modif'\"></td>";
      }
      print "</tr>\n";
    }
  }
} else {
  print "<font color='red'>none sequences could be generated (check param)</font>\n";
}

my $peptideList = join(":", sort(keys(%peptideList)));
print <<end_of_html;
</table>
</form>
<br>
<form name=retentionForm target=_blank action=cgiComputeRT.pl method=post>
<input type=hidden name=peptideList>
Peptide HPLC retention time estimations <input type=submit value=GO onClick=\"document.retentionForm.peptideList.value='$peptideList'\">
</form>
</body>
</html>
end_of_html


sub htmlError
{
  my $msg = shift;
  print "$msg</body></html>\n";
  exit(0);

} # htmlError
