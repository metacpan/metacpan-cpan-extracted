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
use InSilicoSpectro::InSilico::MassCalculator;
use InSilicoSpectro::InSilico::MSMSOutput;

my $peptide = param('peptide');
my $modif = param('modif');
my $peptideSeq = join('', annotatePept($peptide, $modif, 2));

InSilicoSpectro::init();
print header();
print <<end_of_html;
<html>

<head>

<title>fragmentator home page</title>

<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf-8">
<meta name="description" content="Simple web page for digesting protein sequences">
<meta name="keywords" content="fragment, protein, dissociation">

</head>

<body bgcolor=white>
<h2>Fragmentator</h2>

<a href="#fraghelp">Help</a><br>
<form name=fragForm target=_blank method=post action=fragmentator.pl>
<table bgcolor=#dddddd border=1 cellspacing=0 cellpadding=5>
<tr>
<td align=left valign=top>
<b>Peptide sequence</b><br><input type=text name=peptideSeq size=50 value=\"$peptideSeq\"<br>
  <table border=0>
  <tr><td>Fixed modifications</td><td><input type=text name=fixedModif size=20></td></tr>
  <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
  <tr><td><a href="modifList.pl" target=_blank>Available modifications</a></td><td>&nbsp;</td></tr>
  </table>
</td>
<td align=center valign=top><b>Fragment types</b><br>
  <select name=fragSel multiple=yes size=6>
end_of_html

  my (@fragList, %common);
  %common = (a=>1, b=>1, 'b++'=>1, 'b-NH3'=>1, 'b-H2O'=>1, y=>1, 'y++'=>1, 'y-NH3'=>1, 'y-H2O'=>1);
  foreach (sort InSilicoSpectro::InSilico::MSMSOutput::cmpFragTypes InSilicoSpectro::InSilico::MassCalculator::getFragTypeList()){
    if ($common{$_}){
      print "    <option value=\"$_\" selected=1>$_</option>\n";
    }
    else{
      push(@fragList, "    <option value=\"$_\">$_</option>\n");
    }
  }
  print @fragList;

print <<end_of_html;
  </select>
</td>
</tr>

<tr>
<td align=left valign=top><b>Fragment mass list</b><br><textarea cols=50 rows=15 name=massList></textarea></td>
<td align=center valign=bottom>
  <table border=0>
  <tr><td>Mass index</td><td><input type=text name=massIndex value=0 size=5></td></tr>
  <tr><td>Intensity index</td><td><input type=text name=intensityIndex value=1 size=5></td></tr>
  <tr><td>Monoisotopic mass</td><td><input type=checkbox name=monoisotopic checked></td></tr>
  <tr><td>Relative tolerance</td><td><input type=text name=tol value=300 size=5> ppm</td></tr>
  <tr><td>Absolute tolerance</td><td><input type=text name=minTol value=0.1 size=5> Da</td></tr>
  <tr><td colspan=2>Match type:<br>
                    Closest <input type=radio name=matchType checked value=closest> Most intense <input type=radio name=matchType value=mostIntense> Order <input type=radio name=matchType value=greedy></td></tr>
  <tr><td colspan=2>Order list <input type=text size=20 name=order></td></tr>
  <tr><td colspan=2>Intensity normalization:<br>
                    No <input type=radio name=intSel value=original> Log <input type=radio name=intSel value=log> Relative <input type=radio name=intSel value= relative> Order <input type=radio name=intSel value=order checked>
  </td></tr>
  </table>
</td>
</tr>

<tr>
<td colspan=2 align=center>
<input type=submit value="Break Me">
<td>
</tr>
</table>
</form>
<hr>
<a name="fraghelp"><h3>Help</h3></a>

<p>Fragmentator form lets you enter a peptide sequence and fragment it. In addition you can
match the resulting fragment masses with experimental data</p>

<p>In top left quarter you enter the peptide sequence. You can
insert modifications at specific locations by typing their name between curly brackets. For
instance <pre>{CAM_nterm}EFVE{(*)CARB,GGLU}VTKLVTDLTKVH{(*)Oxidation}KECCHGDK-{BIOT}</pre>
means fixed CAM_nterm at N-terminus, variable CARB or GGLU on the second E, variable
Oxidation on H, and fixed BIOT on the C-terminus. Modifications are inserted after the amino
acid letter, or at the first place for N-terminal modifications, or after an extra minus sign
for C-terminal modifications.</p>

<p>Global fixed and variable modification names can be entered in the
two other text fields. These modification names must be separated by comas or
spaces and the modifications are globally searched against the sequence to locate them. For
instance fixed Cys_CAM would cause all the cysteines to be modified. The list of available
modifications cat be displayed by clicking on the hyperlink.</p>

<p>In the top right quarter you select the fragmentation types.</p>

<p>If you want to match the fragment theoretical masses with experimental data, you can enter
an experimental mass list in the lower left quarter. It must be a space/coma separated list
with one line per experimental peak.</p>

<p>By default the first column is the mass and the second one
is the intensity, but you can change that in the lower right quarter (mass/intensity index).
The maximum mass error is controlled by two parameters: tol and minTol. For a peak to be
matched the relative error (in ppm) must be smaller or equal to tol or the absolute error
(in Da) must be smaller or equal to minTol.</p>

<p>Match type. Three radio buttons allow you to choose the match policy. "Closest" means that the
closest experimental mass is selected for each theoretical mass, whithin mass tolerance
naturally. "Most intense" means that the most intense peak in the mass error window is
selected. Finally, "Order" means that experimental masses are only used once and to match
the fragment types in the order entered in the text field below. The latter text field must
contain a list of fragment type names separated by comas or spaces.</p>

<p>Intensity normalization. In case you match experimental data with theoretical data, a graphic
plot of the matched fragments is produced. In order to report the intensity of the matched fragments
a color scale is used. Fragment peak intensities can be normalized in different ways: "No" means
no normalization or linear scale, "Log" means logarithmic scale, "Relative" means relative intensity,
and "Order" means relative rank.</p>

</body>
</html>
end_of_html
