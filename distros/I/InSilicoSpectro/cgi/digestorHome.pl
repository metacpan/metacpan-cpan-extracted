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
  use CGIUtils;
}

use strict;
use CGI qw(:standard);
use InSilicoSpectro;
use InSilicoSpectro::InSilico::CleavEnzyme;

InSilicoSpectro::init();
print header();
print <<end_of_html;
<html>

<head>

<title>digestor home page</title>

<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf-8">
<meta name="description" content="Simple web page for digesting protein sequences">
<meta name="keywords" content="enzyme, protein, digestion">

</head>

<body bgcolor=white>
<h2>Digestor</h2>

<a href="#dighelp">Help</a><br>
<form name=digestForm method=post target=_blank action=digestor.pl>
<table bgcolor=#dddddd border=1 cellspacing=0 cellpadding=5>
<tr>
<td align=left valign=top>
<b>Protein sequence or SwissProt AC/ID</b><br><textarea cols=50 rows=15 name=protSeq></textarea><br>
  <table border=0>
  <tr><td>Fixed modifications</td><td><input type=text name=fixedModif size=18></td></tr>
  <tr><td>Variable modifications</td><td><input type=text name=varModif size=18></td></tr>
  <tr><td><a href="modifList.pl" target=_blank>Available modifications</a></td><td>&nbsp;</td></tr>
  </table>
</td>
<td align=center valign=top><b>Enzyme selection</b><br>
  <select name=enzymeSel>
end_of_html

  foreach (InSilicoSpectro::InSilico::CleavEnzyme::getList()){
    my $name = $_->name();
    print "    <option value=\"$name\"", ($name eq 'Trypsin' ? ' selected=1' : ''), ">$name</option>\n";
  }

print <<end_of_html;
  </select><br><br>
  <table border=0>
  <tr><td>Missed cleavages</td><td><input type=text name="nmc" size=2 value=1></td></tr>
  <tr><td>Monoisotopic mass</td><td><input type=checkbox name=monoisotopic checked></td></tr>
  <tr><td>Fully enzymatic</td><td><input type=radio name=enzymatic value=fully checked></td></tr>
  <tr><td>Half enzymatic</td><td><input type=radio name=enzymatic value=half></td></tr>
  <tr><td>Non specific</td><td><input type=radio name=enzymatic value=no></td></tr>
  <tr><td>Min mass</td><td><input type=text name="minMass" size=5 value=700> Da</td></tr>
  <tr><td>Max mass</td><td><input type=text name="maxMass" size=5 value=3500> Da</td></tr>
  <tr><td>Min length</td><td><input type=text name="minLength" size=5 value=5> aa</td></tr>
  <tr><td>Max length</td><td><input type=text name="maxLength" size=5 value=50> aa</td></tr>
  </table>
</td>
</tr>

<tr>
<td align=left valign=top><b>Peptide mass list</b><br><textarea cols=50 rows=15 name=massList></textarea></td>
<td align=center valign=bottom>
  <table border=0>
  <tr><td>Mass index</td><td><input type=text name=massIndex value=0 size=5></td></tr>
  <tr><td>Intensity index</td><td><input type=text name=intensityIndex value=1 size=5></td></tr>
  <tr><td>Relative tolerance</td><td><input type=text name=tol value=100 size=5> ppm</td></tr>
  <tr><td>Absolute tolerance</td><td><input type=text name=minTol value=0.1 size=5> Da</td></tr>
  <tr><td>Most intense peak</td><td><input type=checkbox name=mostIntense checked></td></tr>
  <tr><td>Proton mass</td><td><input type=checkbox name=addProton checked></td></tr>
  <tr><td>Show matched only</td><td><input type=checkbox name=matchedOnly></td></tr>
  </table>
</td>
</tr>

<tr>
<td colspan=2 align=center>
<input type=hidden name=pmf>
<input type=button value="PMF" onClick="document.digestForm.pmf.value=1;submit()">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
<input type=button value="MS/MS" onClick="document.digestForm.pmf.value=0;submit()">
<td>
</tr>
</table>
</form>
<hr>
<a name="dighelp"><h3>Help</h3></a>

<p>Digestor form lets you enter a protein sequence and digest it. In addition you can
match the resulting peptide masses with experimental data</p>

<p>In top left quarter you enter the protein sequence. In the text area you can either
paste a protein sequence or type a SwissProt ID or AC. In case you paste a sequence, you can
insert modifications at specific locations by typing their name between curly brackets. For
instance <pre>{CAM_nterm}EFVE{(*)CARB,GGLU}VTKLVTDLTKVH{(*)Oxidation}KECCHGDK-{BIOT}</pre>
means fixed CAM_nterm at N-terminus, variable CARB or GGLU on the second E, variable
Oxidation on H, and fixed BIOT on the C-terminus. Modifications are inserted after the amino
acid letter, or at the first place for N-terminal modifications, or after an extra minus sign
for C-terminal modifications.</p>

<p>Global fixed and variable modification names can be entered in the
two text fields under the text area. These modification names must be separated by comas or
spaces and the modifications are globally searched against the sequence to locate them. For
instance fixed Cys_CAM would cause all the cysteines to be modified. The list of available
modifications cat be displayed by clicking on the hyperlink.</p>

<p>In the top right quarter you select the enzyme. The scroll list contains the available
enzymes and the maximum number of missed cleavages can be specified in the text box under.
By checking the monoisotopic mass checkbox you tell the system to compute peptide monoisotopic masses.
When not clicked, the system uses average masses. A series of three radio buttons lets you select
the type of digestion: fully enzymatic, half enzymatic (only one end of the peptides needs to be
at a cleavage site, or non specific (no enzyme, all possible subsequences). Minimum and
maximum peptide masses and lengths can be set.</p>

<p>If you want to match the peptide theoretical masses with experimental data, you can enter
an experimental mass list in the lower left quarter. It must be a space/coma separated list
with one line per experimental peak.</p>

<p>By default the first column is the mass and the second one
is the intensity, but you can change that in the lower right quarter (mass/intensity index).
The maximum mass error is controlled by two parameters: tol and minTol. For a peak to be
matched the relative error (in ppm) must be smaller or equal to tol or the absolute error
(in Da) must be smaller or equal to minTol.</p>

<p>By checking the most intense peak checkbox you tell the system to match experimental and
theoretical data by taking the most intense peak in the mass error window instead of the
closest peak. Select show matched only to display the matched
peptides only. The proton mass checkbox is used to tell the system to add one proton mass
to every theoretical peptide mass.</p>

<p>If you click the PMF button the modifications will be counted only (no possible fragmentation
spectrum computation afterwards). If you click the MS/MS button the modifications are localized.</p>

</body>
</html>
end_of_html
