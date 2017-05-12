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

BEGIN{
    use File::Basename;
    push @INC, basename($0);
    use CGIUtils;
}

use strict;
use CGI qw(:standard);
use InSilicoSpectro;
use InSilicoSpectro::InSilico::CleavEnzyme;
use InSilicoSpectro::InSilico::MassCalculator;
use InSilicoSpectro::InSilico::MSMSOutput;

my $displayWidth = 60;
my $colMatch = '#ffdddd';

my $peptideSeq = param('peptideSeq');
my $massList = param('massList');
my $massIndex = param('massIndex');
my $intensityIndex = param('intensityIndex');
my $tol = param('tol');
my $minTol = param('minTol');
my $monoisotopic = param('monoisotopic');
my $matchType = param('matchType');
my $order = param('order');
my $fixedModif = param('fixedModif');
my @fragSel = param('fragSel');
my $intSel = param('intSel');

InSilicoSpectro::init();
setMassType(defined($monoisotopic) ? 0 : 1);
print header();

# Extracts modifications
$peptideSeq =~ s/\s//g;
my (@modif, $peptide);
my @seq = split(//, $peptideSeq);
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
    $peptide .= $seq[$i] if ($seq[$i] ne '-');
    $pos++,
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

# Modifications
my @fixedModif = split(/[\s,]/, $fixedModif);
my @modifVect;
locateModif($peptide, \@modif, \@fixedModif, undef, \@modifVect);
my $modifString = modifToString(\@modifVect, length($peptide));
my $displayPeptide = join('', annotatePept($peptide, \@modifVect, 2));

# Theoretical spectrum and match with experimental masses
my %spectrum;
getFragmentMasses(pept=>$peptide, modif=>(@modifVect > 0 ? \@modifVect : undef), fragTypes=>\@fragSel, spectrum=>\%spectrum);
if ($matchType eq 'closest'){
  matchSpectrumClosest(spectrum=>\%spectrum, expSpectrum=>\@massList, massIndex=>$massIndex);
}
elsif ($matchType eq 'mostIntense'){
  matchSpectrumGreedy(spectrum=>\%spectrum, expSpectrum=>\@massList, tol=>$tol, minTol=>$minTol, massIndex=>$massIndex, intensityIndex=>$intensityIndex);
}
else{
  my @order = split(/[\s,]+/, $order);
  foreach (@order){
    my @descr = getFragType($_);
    if (!defined($descr[0])){
      htmlError("Illegal frament type in order list[$_]");
    }
  }
  matchSpectrumGreedy(spectrum=>\%spectrum, expSpectrum=>\@massList, tol=>$tol, minTol=>$minTol, massIndex=>$massIndex, intensityIndex=>$intensityIndex, order=>\@order);
}

my $msms = new InSilicoSpectro::InSilico::MSMSOutput(spectrum=>\%spectrum, prec=>2, modifLvl=>1, expSpectrum=>\@massList, massIndex=>$massIndex, intensityIndex=>$intensityIndex, tol=>$tol, minTol=>$minTol, intSel=>$intSel);

my $css = htmlCSS(boldTitle=>1);
print <<end_of_html;
<html>

<head>

<title>fragmentator results</title>

<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf-8">
<meta name="description" content="Peptide fragmentation result">
<meta name="keywords" content="fragment, peptide, dissociation">
<style type="text/css">
$css
</style>

</head>

<body bgcolor=white>
<h2>Fragmentator results</h2>
<br>
<table border=0 cellspacing=5>
<caption><b>$displayPeptide</b>, mass=$spectrum{peptideMass} Da
end_of_html

# Terminal fragment masses
print $msms->htmlTerm(boldTitle=>1, colLineFunc=>\&chooseColorFrag, css=>1);
print "</table>\n";

# Internal fragment masses
my $intern;
foreach (@fragSel){
  if ($_ eq 'immo'){
    $intern = 1;
    last;
  }
}
if ($intern){
  print "<br><table border=0 cellspacing=5>\n";
  print "\n",$msms->htmlIntern(boldTitle=>1, css=>1);
  print "</table>\n";
}

# Match plot
if (length($massList) > 20){
  use File::Temp qw(tempfile);

#  You have to create a link and set Options FollowSymLinks or to allow access to the tmp directory for the browser
#  use File::Spec;
#  my $tmpdir = File::Spec->tmpdir();

  use File::Spec;
  my $tmpdir = $ENV{INSILICOSPECTRO_FULL_TMPDIR};
  my ($tmpFH, $tmpFname) = tempfile('matchplot-XXXXX', SUFFIX=>'.png', UNLINK=>0, DIR=>$tmpdir);
  $msms->plotSpectrumMatch(fhandle=>$tmpFH, format=>'png', fontChoice=>'default:Large', style=>'circle',changeColModifAA=>1, legend=>($intern ? 'bottom' : 'right'), plotIntern=>($intern ? 1 : undef));
  close($tmpFH);
  chmod(0644, $tmpFname);
  my $fname = $ENV{INSILICOSPECTRO_WEB_TMPDIR}."/".(split(/\//, $tmpFname))[-1];
  print "<br><img src=\"$fname\" alt=\"match image ($tmpdir, $tmpFname, $fname\" />\n";
}

print <<end_of_html;
</body>
</html>
end_of_html


sub htmlError
{
  my $msg = shift;
  print "$msg</body></html>\n";
  exit(0);

} # htmlError
