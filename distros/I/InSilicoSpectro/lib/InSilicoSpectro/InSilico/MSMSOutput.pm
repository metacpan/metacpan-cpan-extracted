package InSilicoSpectro::InSilico::MSMSOutput;

# Mass spectrometry Perl module for displaying results of mass computations

# Copyright (C) 2005 Jacques Colinge

# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.

# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Contact:
#  Prof. Jacques Colinge
#  Upper Austria University of Applied Science at Hagenberg
#  Hauptstrasse 117
#  A-4232 Hagenberg, Austria
#  http://www.fhs-hagenberg.ac.at

require Exporter;

our (@ISA, @EXPORT, @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT = qw(normalizeIntensities annotatePept chooseColorLineNum chooseColorFrag htmlCSS plotLegendOnly );
@EXPORT_OK = ();

use strict;
use Carp;
use InSilicoSpectro::InSilico::MassCalculator;
our $okGD;
eval{
  #require fails for autoload results  (bug #4)
  use GD;
  $okGD=1;
};
our %htmlize = ('<'=>'&lt;', '>'=>'&gt;', '&'=>'&amp;', '"'=>'&quot;', "'"=>'&apos;');
our ($tmpim, $tmpWhite);

return 1;


=head1 NAME

MSMSOutput - An object implementing common display/output methods for masses

=head1 SYNOPSIS

use MSMSOutput;

=head1 DESCRIPTION

MSMSOutput Perl object is intended to support common display and
output methods for masses as obtained by mass spectrometry-related
computations.

It is released under the LGPL license (see source code).

=head1 ATTRIBUTES

=over 4

=item spectrum

A reference to a hash such as computed by MassCalculator::getFragmentMasses or
an object of class MSMSTheoSpectrum.

=item expSpectrum

A reference to an experimental spectrum such as required by
MassCalculator::matchClosest or an object of class ExpSpectrum.
When this parameter is specified the constructor
will assume that the hash spectrum contains data about
the match with this experimental spectrum.

=item massIndex

The mass index in the experimental peak vectors, default 0. If expSpectrum
parameter is an ExpSpectrum object this index is read from the object directly.

=item intensityIndex

The intensity index in the experimental peak vectors, default 1. If expSpectrum
parameter is an ExpSpectrum object this index is read from the object directly.

=item tol

Relative mass error tolerance; this parameter is optional. When not
specified, the matched masses found by the match algorithm are
all preserved. When specified, the new tolerance is applied.

This parameter is mainly useful for match obtained via matchSpectrumClosest
that does not apply any mass tolerance.

=item minTol

Absolute mass error, default value 0.2 Da. This parameter is used
only in case tol parameter is specified, see above.

=item intSel

This parameter controls how the peak intensities are normalized,
see function normalizeIntensities.

Parameter intSel is used provided expSpectrum was set.

=item prec

The number of digits after the decimal points for the masses.
Default precision is 3 digits.

=item modifLvl

Controls how the modifications are highlighted in the vector
splitPept defined below, see also function annotatePept.

=item cmp

This parameter is a reference to a comparison function used for
sorting fragment names. If cmp is not set, the function
cmpFragTypes is used instead.

=back

=head1 METHODS

=head2 new(%h|$MSMSOutput)

Constructor. %h is a hash of attribute=>value pairs and $MSMSOutput is a
InSilicoSpectro::InSilico::MSMSOutput object, from which the attributes are
copied.

To prepare for actual output - through specialized methods - the constructor builds
a dedicated data structure. In case users want to create new methods via inheritance or
code modification, we describe hereafter this data structure:

  my $table = new InSilicoSpectro::InSilico::MSMSOutput(...);

  $table->{peptideMass} is the precursor peptide mass.
  $table->{peptide} is the precursor peptide sequence.
  $table->{modif} is the precursor peptide modification string.
  $table->{splitPept} is a reference to a vector of the same length
                      as the peptide sequence that contains each
                      amino acid with annotated modifications (see
                      parameter modifLvl above).
  $table->{intSel} is the value of the intSel parameter.

  $table->{mass}{term} contains the terminal fragments.
  $table->{mass}{intern} contains the internal fragments.

  $table->{mass}{term}[i][0] contains the name of the ith fragment type.
  $table->{mass}{term}[i][j] contains the mass of the jth fragment of type i.

  $table->{mass}{intern}[i][0] contains the name of the ith fragment type
  $table->{mass}{intern}[i][j,j+1] contains a description of the internal
                                   fragment followed by its mass, j>0.

  $table->{match} has the same structure as $table->{mass} but it
                  contains the matched experimental masses. How the
                  masses are matched depends on the match function
                  that was called.

  $table->{intens} has the same structure as $table->{match} but it
                   contains the normalized intensities of the matched 
                   experimental peaks.

See also the code of the method tabSepSpectrum for a simple example of
how this data structure can be used.

=cut
sub new
{
  my $pkg = shift;

  my $class = ref($pkg) || $pkg;
  my $table;

  if (ref($_[0]) && $_[0]->isa('InSilicoSpectro::InSilico::MSMSOutput')){
    # Copy constructor
    $table = {};
    %$table = %{$_[0]};
    bless($table, $class);
    return $table
  }

  # Regular constructor
  $table = {};
  bless($table, $class);

  my (%h) = @_;
  my ($theo, $prec, $modifLvl, $cmp, $spec, $intSel, $tol, $minTol, $massIndex, $intensityIndex) = ($h{spectrum}, $h{prec}, $h{modifLvl}, $h{cmp}, $h{expSpectrum}, $h{intSel}, $h{tol}, $h{minTol}, $h{massIndex}, $h{intensityIndex});
  $prec = $prec || 3;
  my $format = '%.'.$prec.'f';
  $cmp = $cmp || \&cmpFragTypes;
  $intSel = $intSel || 'order';
  $minTol = $minTol || 0.2;
  $massIndex = $massIndex || 0;
  $intensityIndex = $intensityIndex || 1;

  # Determines experimental spectrum type
  my $expSpectrum;
  if (ref($spec) && (ref($spec) ne 'ARRAY') && $spec->isa('InSilicoSpectro::Spectra::ExpSpectrum')){
    $expSpectrum = $spec->spectrum();
    $massIndex = $spec->peakDescriptor()->getFieldIndex('mass');
    $intensityIndex = $spec->peakDescriptor()->getFieldIndex('intensity');
    if (!defined($intensityIndex)){
      $intensityIndex = $spec->peakDescriptor()->getFieldIndex('height');
    }
  }
  else{
    $expSpectrum = $spec;
  }

  # Determines theoretical spectrum type
  my $spectrum;
  if (ref($theo) && (ref($theo) ne 'HASH') && $theo->isa('InSilicoSpectro::InSilico::MSMSTheoSpectrum')){
    $spectrum = $theo->theoSpectrum();

    # Gets peptide sequence
    my $peptide = $theo->{theoSpectrum}{peptide};
    if (ref($peptide) && $peptide->isa('InSilicoSpectro::InSilico::Peptide')){
      $table->{peptide} = $peptide->sequence();
    }
    else{
      $table->{peptide} = $peptide;
    }
  }
  elsif (ref($theo) eq 'HASH'){
    $spectrum = $theo;
    $table->{peptide} = $spectrum->{peptide};
  }
  else{
    croak("Illegal data type for theoretical spectrum [$theo]");
  }

  # Preparation and title
  $table->{modif} = $spectrum->{modif};
  $table->{peptideMass} = sprintf($format, $spectrum->{peptideMass});
  @{$table->{splitPept}} = annotatePept($spectrum->{peptide}, $spectrum->{modif}, $modifLvl);
  $table->{intSel} = $intSel;
  $table->{modifLvl} = $modifLvl;
  $table->{numExpPeaks} = defined($expSpectrum) ? scalar(@$expSpectrum) : 0;
  my $len = length($table->{peptide});
  my $normInt = {};
  normalizeIntensities($intSel, $expSpectrum, $normInt, $massIndex, $intensityIndex) if (defined($expSpectrum));
  $table->{normInt} = $normInt;

  # N-/C-term fragments
  my $fragNum = 0;
  foreach my $frag (sort $cmp keys(%{$spectrum->{mass}{term}})) {
    my $series = (getFragType($frag))[0];
    for (my $i = 0; $i < @{$spectrum->{ionType}{$frag}}; $i++) {
      # Fragment type name
      push(@{$table->{mass}{term}[$fragNum]}, $frag);#$spectrum->{ionType}{$frag}[$i]);
      if (defined($expSpectrum)){
	push(@{$table->{match}{term}[$fragNum]}, $frag);#$spectrum->{ionType}{$frag}[$i]);
	push(@{$table->{intens}{term}[$fragNum]}, $frag);#$spectrum->{ionType}{$frag}[$i]);
      }

      if ((getSeries($series))[0] eq 'N') {
	# N-term fragments, leave the original order
	for (my $j = $i*$len; $j < ($i+1)*$len; $j++) {
	  if (defined((my $theoMass = $spectrum->{mass}{term}{$frag}[$j]))){
	    push(@{$table->{mass}{term}[$fragNum]}, sprintf($format, $theoMass));
	    if (defined($expSpectrum)){
	      my $noMatch = 1;
	      if (defined($spectrum->{match}{term}{$frag}[$j])){
		# Found a match, checks precision
		my $expMass = $spectrum->{match}{term}{$frag}[$j][0];
		if (!defined($tol) || (abs($theoMass-$expMass)/($theoMass+$expMass)*2e+6 <= $tol) || (abs($theoMass-$expMass) <= $minTol)){
		  # Precision ok or no precision required
		  push(@{$table->{match}{term}[$fragNum]}, sprintf($format, $expMass));
		  push(@{$table->{intens}{term}[$fragNum]}, sprintf("%.2f", $normInt->{$spectrum->{match}{term}{$frag}[$j][0]}));
		  $noMatch = 0;
		}
	      }
	      if ($noMatch){
		# No match, just maintain identical indices by adding undefs
		push(@{$table->{match}{term}[$fragNum]}, undef);
		push(@{$table->{intens}{term}[$fragNum]}, undef);
	      }
	    }
	  }
	  else{
	    # Impossible mass (loss)
	    push(@{$table->{mass}{term}[$fragNum]}, undef);
	    if (defined($expSpectrum)){
	      # Maintain identical indices by adding undefs
	      push(@{$table->{match}{term}[$fragNum]}, undef);
	      push(@{$table->{intens}{term}[$fragNum]}, undef);
	    }
	  }
	}
      }
      else {
	# C-term fragments, reverse the original order
	for (my $j = ($i+1)*$len-1; $j >= $i*$len; $j--) {
	  if (defined((my $theoMass = $spectrum->{mass}{term}{$frag}[$j]))){
	    push(@{$table->{mass}{term}[$fragNum]}, sprintf($format, $theoMass));
	    if (defined($expSpectrum)){
	      my $noMatch = 1;
	      if (defined($spectrum->{match}{term}{$frag}[$j])){
		# Found a match, checks precision
		my $expMass = $spectrum->{match}{term}{$frag}[$j][0];
		if (!defined($tol) || (abs($theoMass-$expMass)/($theoMass+$expMass)*2e+6 <= $tol) || (abs($theoMass-$expMass) <= $minTol)){
		  # Precision ok or no precision required
		  push(@{$table->{match}{term}[$fragNum]}, sprintf($format, $expMass));
		  push(@{$table->{intens}{term}[$fragNum]}, sprintf("%.2f", $normInt->{$spectrum->{match}{term}{$frag}[$j][0]}));
		  $noMatch = 0;
		}
	      }
	      if ($noMatch){
		# No match, just maintain identical indices by adding undefs
		push(@{$table->{match}{term}[$fragNum]}, undef);
		push(@{$table->{intens}{term}[$fragNum]}, undef);
	      }
	    }
	  }
	  else{
	    # Impossible mass (loss)
	    push(@{$table->{mass}{term}[$fragNum]}, undef);
	    if (defined($expSpectrum)){
	      # Maintain identical indices by adding undefs
	      push(@{$table->{match}{term}[$fragNum]}, undef);
	      push(@{$table->{intens}{term}[$fragNum]}, undef);
	    }
	  }
	}
      }
      $fragNum++;
    }
  }

  # Internal fragments
  $fragNum = 0;
  foreach my $frag (sort cmpFragTypes keys(%{$spectrum->{mass}{intern}})) {
    push(@{$table->{mass}{intern}[$fragNum]}, $spectrum->{ionType}{$frag}[0]);
    if (defined($expSpectrum)){
      # Name of the fragment
      push(@{$table->{match}{intern}[$fragNum]}, $spectrum->{ionType}{$frag}[0]);
      push(@{$table->{intens}{intern}[$fragNum]}, $spectrum->{ionType}{$frag}[0]);
    }
    foreach my $aa (sort keys(%{$spectrum->{mass}{intern}{$frag}})) {
      my $theoMass = $spectrum->{mass}{intern}{$frag}{$aa};
      push(@{$table->{mass}{intern}[$fragNum]}, $aa, sprintf($format, $theoMass));
      if (defined($expSpectrum)){
	my $noMatch = 1;
	if (defined($spectrum->{match}{intern}{$frag}{$aa})){
	  # Found a match, checks its precision
	  my $expMass = $spectrum->{match}{intern}{$frag}{$aa}[0];
	  if (!defined($tol) || (abs($theoMass-$expMass)/($theoMass+$expMass)*2e+6 <= $tol) || (abs($theoMass-$expMass) <= $minTol)){
	    # Precision ok or no precision required
	    push(@{$table->{match}{intern}[$fragNum]}, $aa, sprintf($format, $expMass));
	    push(@{$table->{intens}{intern}[$fragNum]}, $aa, sprintf("%.2f", $normInt->{$spectrum->{match}{intern}{$frag}{$aa}[0]}));
	    $noMatch = 0;
	  }
	}
	if ($noMatch){
	  # Maintain identical indices by adding undefs
	  push(@{$table->{match}{intern}[$fragNum]}, undef, undef);
	  push(@{$table->{intens}{intern}[$fragNum]}, undef, undef);
	}
      }
    }
    $fragNum++;
  }

  return $table;

} # new


=head2 tabSepSpectrum($nColIntern)

This method returns a string containing a tab-separated tabular
representation of the theoretical spectrum.
Matched masses, if present, are ignored.

As it is certainly more appropriate to instantiate the object with modifLvl
set to 1 (or 0) before calling this method, we also include
in the output table a string giving the peptide modifications
as obtained with modifLvl set to 2. Peptide mass is included as
well.

The string computed by tabSepSpectrum is appropriate for loading in
a spread sheet or is usable as an intermediary format for a
custom output format. For the latter reason, we try to make it
simple to parse and, in particular, we add a 'TERMINAL' tag
at the beginning of the N-/C-terminal fragment masses and an
'INTERNAL' tag at the beginning the internal ones. Moreover,
if match data are available, the matched theoretical masses
are followed by the matched experimental masses and intensities
in parentheses (should be easy to read and parse via elementary
regular expressions).

The only parameter is:

=over 4

=item $nColIntern

Number of groups of 3 columns in the second table for the internal
fragments. Default is 2.

=back

Example:

  my $msms = new InSilicoSpectro::InSilico::MSMSOutput(...);
  print $msms->tabSepSpectrum();

=cut
sub tabSepSpectrum
{
  my ($table, $nColIntern) = @_;
  $nColIntern = $nColIntern || 2;

  # Title
  my $string = join('', annotatePept($table->{peptide}, $table->{modif}, 2))."\n$table->{peptideMass}\n";

  # Terminal fragments
  $string .= "TERMINAL\n";
  $string .= "\t".join("\t", @{$table->{splitPept}})."\n";
  for (my $i = 0; $i < @{$table->{mass}{term}}; $i++){
    # One fragment type
    $string .= $table->{mass}{term}[$i][0];
    for (my $j = 1; $j < @{$table->{mass}{term}[$i]}; $j++){
      $string .= "\t$table->{mass}{term}[$i][$j]";
      if (defined($table->{match}{term}[$i][$j])){
	$string .= "($table->{match}{term}[$i][$j],$table->{intens}{term}[$i][$j])";
      }
    }
    $string .= "\n";
  }

  # Internal fragments, first list them
  my @tmp;
  for (my $i = 0; $i < @{$table->{mass}{intern}}; $i++){
    for (my $j = 1; $j < @{$table->{mass}{intern}[$i]}; $j+=2){
      push(@tmp, "$table->{mass}{intern}[$i][0]\t$table->{mass}{intern}[$i][$j]\t$table->{mass}{intern}[$i][$j+1]".(defined($table->{match}{intern}[$i][$j+1]) ? "($table->{match}{intern}[$i][$j+1],$table->{intens}{intern}[$i][$j+1])" : ''));
    }
  }
  # Groups internal fragments into the desired number of columns
  $string .= "INTERNAL\n" if (@tmp > 0);
  for (my $i = 1; $i <= @tmp; $i++){
    $string .= $tmp[$i-1];
    if ($i < @tmp){
      if ($i % $nColIntern == 0){
	$string .= "\n";
      }
      else{
	$string .= "\t";
      }
    }
  }
  $string .= "\n";

  return $string;

} # tabSepSpectrum


=head2 latexSpectrum($nColIntern)

This method returns a simple latex table in a string containing a
tabular representation of the tabular structure generated by tabSpectrum.
This table should be fairly easy to edit afterwards to meet specific
style requirements. Matched masses, if present, are ignored.

Internal fragments (only immonium ions for the time being) are
output in a separated table since their number is different from
the peptide length.

The only parameter is:

=over 4

=item $nColIntern

Number of groups of 3 columns in the second table for the internal
fragments. Default is 2.

=back

Example:

  my $msms = new InSilicoSpectro::InSilico::MSMSOutput(...);
  print $msms->latexSpectrum(3);

=cut
sub latexSpectrum
{
  my ($table, $nColIntern) = @_;
  $nColIntern = $nColIntern || 2;

  my $len = length($table->{peptide});
  my $string;

  # Title
  $string .= "\\begin{tabular}{|l|".('r|'x$len)."}\\hline\n";
  $string .= "Ion types";
  for (my $i = 0; $i < @{$table->{splitPept}}; $i++){
    my $tmp = $table->{splitPept}[$i];
    $tmp =~ s/([\$&%#_\{\}])/\\$1/g;
    $string .= " & $tmp";
  }
  $string .= " \\\\ \\hline\n";

  # Terminal fragments
  for (my $i = 0; $i < @{$table->{mass}{term}}; $i++){
    my $tmp = $table->{mass}{term}[$i][0];
    $tmp =~ s/([\$&%#_\{\}])/\\$1/g;
    $string .= $tmp;
    for (my $j = 1; $j < @{$table->{mass}{term}[$i]}; $j++){
      $string .= " & $table->{mass}{term}[$i][$j]";
    }
    $string .= " \\\\ \\hline\n";
  }
  $string .= "\\end{tabular}\n";

  # Internal fragments, first list them
  $string .= "\\begin{tabular}{|".('l|c|r|'x$nColIntern)."}\\hline\n";
  $string .= 'Ion types & Residues & Mass'.(' & Ion types & Residues & Mass'x($nColIntern-1))." \\\\ \\hline\n";
  my @tmp;
  for (my $i = 0; $i < @{$table->{mass}{intern}}; $i++){
    for (my $j = 1; $j < @{$table->{mass}{intern}[$i]}; $j+=2){
      my ($tmp1, $tmp2) = ($table->{mass}{intern}[$i][0], $table->{mass}{intern}[$i][$j]);
      $tmp1 =~ s/([\$&%#_\{\}])/\\$1/g;
      $tmp2 =~ s/([\$&%#_\{\}])/\\$1/g;
      push(@tmp, "$tmp1 & $tmp2 & $table->{mass}{intern}[$i][$j+1]");
    }
  }
  # Groups internal fragments into the desired number of columns
  for (my $i = 1; $i <= @tmp; $i++){
    $string .= $tmp[$i-1];
    if ($i % $nColIntern == 0){
      $string .= " \\\\ \\hline\n";
    }
    else{
      $string .= ' & ';
    }
  }
  # Finishes the last row
  my $n = scalar(@tmp);
  if ($n % $nColIntern != 0){
    my $remain = $nColIntern-($n%$nColIntern);
    for (my $i = 0; $i < $remain-1; $i++){
      $string .= ' & & & ';
    }
    $string .= " & & \\\\ \\hline\n";
  }
  $string .= "\\end{tabular}\n";

  return $string;

} # latexSpectrum


=head2 htmlTerm(%h)

This method returns a string containing the lines of an HTML table
representing a tabular structure such as generated by tabSpectrum; only
the N-/C-terminal fragments are considered, see the sister function
htmlIntern for the internal fragments.

Since this method is susceptible to be used for generating HTML
pages automatically, we give the user some flexibility to change
the aspect of the output table (manual editing is not an option).
Moreover, the <table> tag is not included in the returned string
such that you can choose the table styles you want.

The named parameters are:

=over 4

=item colLineFunc

A reference to a function aimed at changing the line colors
in the table to make it more readable. This package export
two functions for this purpose: chooseColorLineNum and
chooseColorFrag (see their respective descriptions).

You can define your own function if you need another logic.
Such a function has four parameters: fragment type for the
current line, fragment type of the previous line, a reference
to color 1 and another to color 2 to exchange them.

The default function is chooseColorFrag.

=item css

If css is defined then CSS are used instead of old fashioned in situ
color and font specifications. See function htmlCSS.

=item lineCol1, lineCol2

The two colors used for the lines, default colors are
'#DDFFFF' and '#EEEEEE'.

=item boldTitle

Peptide sequence in bold if set to any value.

=item bgTitle

Background color for the peptide sequence, default '#CCFFCC'.

=item boldFrag

Fragment names in bold if set to any value.

=item bgFrag

Background color for the fragment names, default '#FFFFBB'.

=back

Example :

  my $msms = new InSilicoSpectro::InSilico::MSMSOutput(...);
  print "<html><head></head><body><table border=0 cellspacing=5>\n";
  print "\n",$msms->htmlTerm(boldTitle=>1, bgFrag=>'#FFFFBB', bgTitle=>'#99CCFF',
                             colLineFunc=>\&chooseColorFrag);
  print "</table></html>\n";

=cut
sub htmlTerm
{
  my $table = shift;
  my (%h) = @_;
  my ($colLineFunc, $bgTitle, $boldTitle, $bgFrag, $boldFrag, $lineCol1, $lineCol2, $css) = ($h{colLineFunc}, $h{bgTitle}, $h{boldTitle}, $h{bgFrag}, $h{boldFrag}, $h{lineCol1}, $h{lineCol2}, $h{css});

  $colLineFunc = $colLineFunc || \&chooseColorFrag;
  my $bBoldTitle = defined($boldTitle) ? '<b>' : '';
  my $eBoldTitle = defined($boldTitle) ? '</b>' : '';
  my $bBoldFrag = defined($boldFrag) ? '<b>' : '';
  my $eBoldFrag = defined($boldFrag) ? '</b>' : '';
  $lineCol1 = $lineCol1 || '#DDFFFF';
  $lineCol2 = $lineCol2 || '#EEEEEE';
  $bgFrag = $bgFrag || '#FFFFBB';
  $bgTitle = $bgTitle || '#CCFFCC';

  my $currentColor = defined($css) ? 'class="massOutputLineCol1"' : $lineCol1;
  my $oldColor = defined($css) ? 'class="massOutputLineCol2"' : $lineCol2;
  my $string;
  my $len = length($table->{peptide});

  # Column titles
  if (defined($css)){
    $string .= "<tr>\n  <td class=\"massOutputColTitleFrag\">Ion types</td>";
  }
  else{
    $string .= "<tr>\n  <td align=\"left\" bgcolor=\"$bgFrag\">$bBoldTitle Ion types$eBoldTitle</td>";
  }
  for (my $i = 0; $i < @{$table->{splitPept}}; $i++){
    my $tmp = $table->{splitPept}[$i];
    $tmp =~ s/([<>&'"])/$htmlize{$1}/g;
    if (defined($css)){
      $string .= "<td class=\"massOutputColTitle\">$tmp</td>";
    }
    else{
      $string .= "<td align=\"center\" bgcolor=\"$bgTitle\">$bBoldTitle$tmp$eBoldTitle</td>";
    }
  }
  $string .= "\n</tr>\n";
  my $prevFrag;

  # Terminal fragments
  for (my $i = 0; $i < @{$table->{mass}{term}}; $i++){
    my $tmp = $table->{mass}{term}[$i][0];
    $tmp =~ s/([<>&'"])/$htmlize{$1}/g;
    $string .= "<tr>\n";
    if (defined($css)){
      $string .= "  <td class=\"massOutputFragName\">$tmp</td>";
    }
    else{
      $string .= "  <td align=\"left\" bgcolor=\"$bgFrag\">$bBoldFrag$tmp$eBoldFrag</td>";
    }
    for (my $j = 1; $j < @{$table->{mass}{term}[$i]}; $j++){
      &$colLineFunc($table->{mass}{term}[$i][0], $prevFrag, \$currentColor, \$oldColor);
      $prevFrag = $table->{mass}{term}[$i][0];
      if (defined($css)){
	$string .= "<td $currentColor>".(defined($table->{mass}{term}[$i][$j]) ? $table->{mass}{term}[$i][$j] : '&nbsp;')."</td>";
      }
      else{
	$string .= "<td align=\"right\" bgcolor=\"$currentColor\">".(defined($table->{mass}{term}[$i][$j]) ? $table->{mass}{term}[$i][$j] : '&nbsp;')."</td>";
      }
    }
    $string .= "\n</tr>\n";
  }

  return $string;

} # htmlTerm


=head2 htmlIntern(%h)

This method returns a string containing the lines of an HTML table
representing a tabular structure such as generated by tabSpectrum; only
internal fragments are considered, see the sister function
htmlTerm for the N-/C-terminal fragments.

Since this method is susceptible to be used for generating HTML
pages automatically, we give the user some flexibility to change
the aspect of the output table (manual editing is not an option).
Moreover, the <table> tag is not included in the returned string
such that you can choose the table styles you want.

The named parameters are:

=over 4

=item css

If css is defined then CSS are used instead of old fashioned in situ
color and font specifications. See function htmlCSS.

=item bgIntern

The color used for the lines, default '#EEEEEE'.

=item boldTitle

Column titles in bold if set to any value.

=item bgTitle

Background color for the column titles, default '#CCFFCC'.

=item boldFrag

Fragment names in bold if set to any value.

=item bgFrag

Background color for the fragment names, default '#FFFFBB'.

=item nColIntern

Number of groups of 3 columns in the second table for the internal
fragments. Default is 2.

=back

Example:

  my $msms = new InSilicoSpectro::InSilico::MSMSOutput(...);
  print "<table border=0 cellspacing=5>\n";
  print "\n",$msms->htmlIntern(boldTitle=>1);
  print "</table>\n";

=cut
sub htmlIntern
{
  my $table = shift;
  my (%h) = @_;
  my ($bgTitle, $boldTitle, $bgFrag, $boldFrag, $bgIntern, $nColIntern, $css) = ($h{bgTitle}, $h{boldTitle}, $h{bgFrag}, $h{boldFrag}, $h{bgIntern}, $h{nColIntern}, $h{css});

  my $bBoldTitle = defined($boldTitle) ? '<b>' : '';
  my $eBoldTitle = defined($boldTitle) ? '</b>' : '';
  my $bBoldFrag = defined($boldFrag) ? '<b>' : '';
  my $eBoldFrag = defined($boldFrag) ? '</b>' : '';
  $bgIntern = $bgIntern || '#EEEEEE';
  $nColIntern = $nColIntern || 2;
  $bgFrag = $bgFrag || '#FFFFBB';
  $bgTitle = $bgTitle || '#CCFFCC';

  my $string;
  my $len = length($table->{peptide});

  # Column titles
  if (defined($css)){
    $string .= "<tr>\n  ".("<td class=\"massOutputColTitleFrag\">Ion types</td><td class=\"massOutputColTitle\">Residues</td><td class=\"massOutputColTitle\">Mass</td>"x$nColIntern)."\n</tr>\n";
  }
  else{
    $string .= "<tr>\n  ".("<td align=\"left\" bgcolor=\"$bgFrag\">$bBoldTitle Ion types$eBoldTitle</td><td align=\"center\" bgcolor=\"$bgTitle\">$bBoldTitle Residues$eBoldTitle</td><td align=\"center\" bgcolor=\"$bgTitle\">$bBoldTitle Mass$eBoldTitle</td>"x$nColIntern)."\n</tr>\n";
  }

  # Internal fragments, list them first
  my @tmp;
  for (my $i = 0; $i < @{$table->{mass}{intern}}; $i++){
    for (my $j = 1; $j < @{$table->{mass}{intern}[$i]}; $j+=2){
      my ($tmp1, $tmp2) = ($table->{mass}{intern}[$i][0], $table->{mass}{intern}[$i][$j]);
      $tmp1 =~ s/([<>&'"])/$htmlize{$1}/g;
      $tmp2 =~ s/([<>&'"])/$htmlize{$1}/g;
      if (defined($css)){
	push(@tmp, "<td class=\"massOutputFragName\">$tmp1</td><td class=\"massOutputInternCenter\">$tmp2</td><td class=\"massOutputInternRight\">$table->{mass}{intern}[$i][$j+1]</td>");
      }
      else{
	push(@tmp, "<td align=\"left\" bgcolor=\"$bgFrag\">$bBoldFrag$tmp1$eBoldFrag</td><td align=\"center\" bgcolor=\"$bgIntern\">$tmp2</td><td align=\"right\" bgcolor=\"$bgIntern\">$table->{mass}{intern}[$i][$j+1]</td>");
      }
    }
  }

  # Groups them into the desired number of columns
  for (my $i = 1; $i <= @tmp; $i++){
    if ($i % $nColIntern == 1){
      $string .= "<tr>\n  ";
    }
    $string .= $tmp[$i-1];
    if ($i % $nColIntern == 0){
      $string .= "\n</tr>\n";
    }
  }

  # Finishes the last row
  my $n = scalar(@tmp);
  if ($n % $nColIntern != 0){
    my $remain = $nColIntern-($n%$nColIntern);
    for (my $i = 0; $i < $remain; $i++){
      if (defined($css)){
	$string .= "<td class=\"massOutputFragName\">&nbsp;</td><td class=\"massOutputInternCenter\">&nbsp;</td><td class=\"massOutputInternRight\">&nbsp;</td>";
      }
      else{
	$string .= "<td align=\"left\" bgcolor=\"$bgFrag\">&nbsp;</td><td align=\"center\" bgcolor=\"$bgIntern\">&nbsp;</td><td align=\"right\" bgcolor=\"$bgIntern\">&nbsp;</td>";
      }
    }
    $string .= "\n</tr>\n";
  }

  return $string;

} # htmlIntern


sub selectColor
{
  my ($thres, $intensity) = @_;

  my $n = scalar(@$thres);
  if ($n < 1){
    return 0;
  }

  if ($intensity < $thres->[1]){
    return 0;
  }
  elsif ($intensity >= $thres->[$n-1]){
    return $n-1;
  }
  else{
    for (my $i = 2; $i < $n-1; $i++){
      if ($intensity < $thres->[$i]){
	return $i-1;
      }
    }
    return $n-2;
  }

} # selectColor


sub max {$_[0] < $_[1] ? $_[1] : $_[0]}


=head2 plotSpectrumMatch(%h)

This method generates images to represent matches between theoretical
and experimental spectra. Such images are intended to be used in user
interface, typically web interfaces. To fit rather diverse requirements,
a great number of parameters can be set to change colors and aspects
of the plots.

The named parameters are:

=over 4

=item fname

The file name of the generated image.

=item fhandle

An open file handle for writing the generated image. It has priority over
parameter fname and the file handle will be set in binmode.

=item format

The graphic file format. If not specified, the function will return the
image object for further processing (see GD documentation). The supported
file formats are the ones of GD.

=item fontChoice

The size of the graphics is controlled via the choice of the font. The
fontChoics parameter is a string 'class:size', where class selects
the type of font and size its size.

The GD native fonts are selected by setting class equal to 'default'. The
size the 'default' class must be one of 'Tiny', 'Small', 'MediumBold',
'Large', or 'Giant'. Default font is 'default:Large'.

Alternatively, it is possible give the name of a file containing the
definition of a TrueType font for the class (absolute path) and size
is the point size.

=item inCellBorder

Number of pixels between lines and text, default 1.

=item style

Two styles are supported for the match graphics: 'circle' and 'square'.
Default is 'circle' except when modifLvl was 2 in tabSpectrum, where it
is 'square'.

=item plotIntern

If this parameter is set to any value, and at least one internal fragment
mass exists, the internal fragments are represented in the graphics.

=item nColIntern

Number of column to display internal fragments, default is 2.

=item colorScale

This parameter is used for defining a list of intensities thresholds and
corresponding colors used when highlighting the table cells to indicate
fragment matches. Thresholds must be in increasing order of intensities.

colorScale is a reference to a vector of values, each threshold is associated
with 8 values in the following order:

=over 4

=item threshold value

=item red intensity (cell color)

=item green intensity (cell color)

=item blue intensity (cell color)

=item legend text

=item red intensity (legend text color)

=item green intensity (legend text color)

=item blue intensity (legend text color)

=back

These eight data are repeated for each threshold and the number of threshold
is not limited. The threshold values must be adapted to intensity normalization
(see function tabSpectrum).

By default, plotSpectrumMatch generates a color scale that adapts to the
normalization and contains 5 bins: blue (less intense), red, orange, yellow,
green (most intense).

=item legend

When this parameter is set to 'right', a legend is added at the right of the
graphics. When it is set to 'bottom', a legend is added under the graphics.

The legend is made of the color scale and a count number of matched peaks versus
number of experimental peaks in each intensity bin. This count informs on the
quality of the match. It is important to note that it is not uncommon for an
experimental peak to match several theoretical masses and therefore the count,
which considers each mass once, may be slightly different from what is read
from the graphics. The present two different point of views: theoretical and
experimental masses point of views.

=item changeColModifAA

Except when tabSpectrum was called with modifLvl equal to 2, plotSpectrumMatch
displays one character per amino acid only, i.e. the asterisk indicating the
presence of a modification is suppressed. When changeColModifAA is set to any
value, plotSpectrumMatch display the modified amino acids in another color.
If not set, the modified amino acids are over-lined.

=item modifAAColor

A reference to a vector of three values (R, G, B) used to defined the color for
modified amino acids, default blue.

=item bgColor

A reference to a vector of three values (R, G, B) used to defined the graphics
background color, default white.

=item textColor

A reference to a vector of three values (R, G, B) used to defined the text
color, default black.

=item lineColor

A reference to a vector of three values (R, G, B) used to defined the line
color, default black.

=back

Example:

  my $msms = new InSilicoSpectro::InSilico::MSMSOutput(spectrum=>\%spectrum, prec=>2, modifLvl=>1,
                               expSpectrum=>\@peaks, intSel=>'order', tol=>$tol, minTol=>$minTol);
  $msms->plotSpectrumMatch(fname=>$peptide, format=>'png', fontChoice=>'default:Large',
                           changeColModifAA=>1, legend=>'bottom');

=cut
sub plotSpectrumMatch
{
  croak "cannot call graphic method when GD module coul not be loaded" unless $okGD;

  unless (defined $tmpim){
    $tmpim = new GD::Image(1000, 200);
    $tmpWhite = $tmpim->colorAllocate(255,255,255);
  }

  my $table = shift;
  my (%h) = @_;
  my ($fname, $fhandle, $fontChoice, $colorScale, $format, $inCellBorder, $bgColor, $textColor, $lineColor, $modifAAColor, $changeColModifAA, $style, $legend, $nColIntern, $plotIntern) = ($h{fname}, $h{fhandle}, $h{fontChoice}, $h{colorScale}, $h{format}, $h{inCellBorder}, $h{bgColor}, $h{textColor}, $h{lineColor}, $h{modifAAColor}, $h{changeColModifAA}, $h{style}, $h{legend}, $h{nColIntern}, $h{plotIntern});

  if (defined($format)){
    if (($format ne 'png') && ($format ne 'xbm') && ($format ne 'gif') && ($format ne 'gdf') && ($format ne 'bmp') && ($format ne 'sgi') && ($format ne 'pcx') && ($format ne 'jpeg') && ($format ne 'tiff')){
      croak("Wrong file format [$format]");
    }
  }

  $fontChoice = $fontChoice || 'default:Large';
  $inCellBorder = $inCellBorder || 1;
  $nColIntern = $nColIntern || 2;
  $style = $style || 'circle';
  if (($style eq 'circle') && ($table->{modifLvl} == 2)){
    # Would be too ugly
    $style = 'square';
  }
  $plotIntern = undef if (!defined($table->{mass}{intern}));

  # Determines font size
  my ($fontWidth, $fontHeight, $font, $fontName, $fontPoint, $ttHShift, $ttVShift);
  my ($class, $size) = split(/:/, $fontChoice);
  if ($class eq 'default'){
    if ($size eq 'Tiny'){
      $fontWidth = gdTinyFont->width;
      $fontHeight = gdTinyFont->height;
      eval '$font = gdTinyFont';
    }
    elsif ($size eq 'Small'){
      $fontWidth = gdSmallFont->width;
      $fontHeight = gdSmallFont->height;
      eval '$font = gdSmallFont';
    }
    elsif ($size eq 'MediumBold'){
      $fontWidth = gdMediumBoldFont->width;
      $fontHeight = gdMediumBoldFont->height;
      eval '$font = gdMediumBoldFont';
    }
    elsif ($size eq 'Large'){
      $fontWidth = gdLargeFont->width;
      $fontHeight = gdLargeFont->height;
      eval '$font = gdLargeFont';
    }
    elsif ($size eq 'Giant'){
      $fontWidth = gdGiantFont->width;
      $fontHeight = gdGiantFont->height;
      eval '$font = gdGiantFont';
    }
    else{
      croak("Unknown size [$size] for font class [$class]");
    }
  }
  else{
    if (-e $class){
      $fontName = $class;
      $fontPoint = $size;
      my @coord;
      foreach (split(//, 'ACDEFGHIKLMNPQRSTVWYabcbxyz*#°')){
	@coord = $tmpim->stringFT($tmpWhite, $fontName, $fontPoint, 0, 10, 180, $_);
	if ($fontWidth < $coord[2]-$coord[0]){
	  $fontWidth = $coord[2]-$coord[0];
	}
      }
      @coord = $tmpim->stringFT($tmpWhite, $fontName, $fontPoint, 0, 10, 180, 'AFGHKMPQRSWYbyz*#°');
      $fontHeight = $coord[1]-$coord[7];
      $ttHShift = 10-$coord[0];
      $ttVShift = 180-$coord[1];
    }
    else{
      croak("Unknown font class [$class]");
    }
  }

  # Computes image size and line positions -----------------------------

  # Terminal fragments
  my $cellHeight = $fontHeight+2*$inCellBorder+1;
  $ttVShift += $cellHeight;
  if (($style eq 'circle') && ($cellHeight % 2 == 1)){
    # Must be even to center circles
    $cellHeight++;
  }
  my ($fragLength, $nFrag, @fragNames);
  for (my $i = 0; $i < @{$table->{mass}{term}}; $i++){
    $nFrag++;
    push(@fragNames, $table->{mass}{term}[$i][0]);
    if (length($fragNames[-1]) > $fragLength){
      $fragLength = length($fragNames[-1]);
    }
  }
  my $fragWidth = $fragLength*$fontWidth+2*$inCellBorder+1;
  my @vLines = (0, $fragWidth);
  my (@aa, @modified);
  my $nativeFontWidth = $fontWidth;
  if (($style eq 'circle') && ($fontWidth % 2 == 0)){
    # Must be odd to center circles
    $fontWidth++;
  }
  for (my $i = 0; $i < @{$table->{splitPept}}; $i++){
    if ($table->{modifLvl} == 2){
      # Leaves the amino acids as they are (with modification names explicitely included)
      push(@aa, $table->{splitPept}[$i]);
      push(@modified, 0);
      push(@vLines, $vLines[-1]+length($aa[-1])*$fontWidth+2*$inCellBorder+1);
    }
    else{
      # Maintain a 1-character size
      my $aa = $table->{splitPept}[$i];
      if (index($aa, '*') != -1){
	# modified
	$aa =~ s/\*//g;
	push(@aa, $aa);
	if (defined($changeColModifAA)){
	  push(@modified, 1);
	}
	else{
	  push(@modified, 2);
	}
      }
      else{
	# Not modified
	push(@aa, $aa);
	push(@modified, 0);
      }
      push(@vLines, $vLines[-1]+$fontWidth+2*$inCellBorder+1);
    }
  }
  my @hLines = (0);
  for (my $i = 0; $i <= $nFrag; $i++){
    push(@hLines, $hLines[-1]+$cellHeight);
  }

  # Legend box
  my ($legendHeight, $legendWidth, @legend, @intThres, @countPeaks, @countMatched);
  my ($maxCountLen, @countLegend, $countStartPos, $maxLegLen);
  if (defined($legend)){
    # Prepares legend text
    if (defined($colorScale)){
      # User defined scale
      for (my $i = 0; $i < @$colorScale; $i += 8){
	push(@intThres, $colorScale->[$i]);
	push(@legend, $colorScale->[$i+4]);
      }
    }
    elsif ($table->{intSel} eq 'order'){
      @intThres = (0, 0.3, 0.5, 0.7, 0.9);
      @legend = ('0 %', '30 %', '50 %', '70 %', '90 %');
    }
    elsif ($table->{intSel} eq 'relative'){
      @intThres = (0, 0.1, 0.2, 0.3, 0.5);
      @legend = ('0 %', '10 %', '20 %', '30 %', '50 %');
    }
    elsif ($table->{intSel} eq 'log'){
      @intThres = (0, 4.6, 6.2, 7.6, 9.2);
      @legend = ('1', '100', '500', '2000', '10000');
    }
    elsif ($table->{intSel} eq 'original'){
      @intThres = (0, 100, 500, 2000, 10000);
      @legend = ('0', '100', '500', '2000', '10000');
    }
    else{
      croak("Unknown intSel value [$table->{intSel}]");
    }

    # Counts peaks
    foreach my $intens (values(%{$table->{normInt}})){
      $countPeaks[selectColor(\@intThres, $intens)]++;
    }
    # Counts matched peaks (once)
    my %already;
    for (my $i = 0; $i < @{$table->{mass}{term}}; $i++){
      for (my $j = 1; $j < @{$table->{mass}{term}[$i]}; $j++){
	if (defined((my $expMass = $table->{match}{term}[$i][$j]))){
	  if (!$already{$expMass}){
	    $countMatched[selectColor(\@intThres, $table->{intens}{term}[$i][$j])]++;
	  }
	  $already{$expMass} = 1;
	}
      }
    }
    if (defined($plotIntern)){
      # Internal fragments
      for (my $i = 0; $i < @{$table->{mass}{intern}}; $i++){
	for (my $j = 1; $j < @{$table->{mass}{intern}[$i]}; $j+=2){
	  if (defined((my $expMass = $table->{match}{intern}[$i][$j+1]))){
	    if (!$already{$expMass}){
	      $countMatched[selectColor(\@intThres, $table->{intens}{intern}[$i][$j+1])]++;
	    }
	    $already{$expMass} = 1;
	  }
	}
      }
    }

    for (my $i = 0; $i < @intThres; $i++){
      push(@countLegend, ($countMatched[$i]+0).'/'.($countPeaks[$i]+0));
      $maxCountLen = length($countLegend[-1]) if (length($countLegend[-1]) > $maxCountLen);
    }

    $legendHeight = scalar(@legend)*$cellHeight+1;
    if (defined($font)){
      foreach (@legend){
	$maxLegLen = length($_) if (length($_) > $maxLegLen);
      }
      $legendWidth = ($maxLegLen+$maxCountLen)*$nativeFontWidth+4*$inCellBorder+3;
      $countStartPos = $maxLegLen*$nativeFontWidth+2*$inCellBorder+1;
    }
    else{
      my (@coord, $lWidth, $countWidth);
      foreach (@legend){
	@coord = $tmpim->stringFT($tmpWhite, $fontName, $fontPoint, 0, 10, 180, $_);
	if ($lWidth < $coord[2]-$coord[0]){
	  $lWidth = $coord[2]-$coord[0];
	}
      }
      foreach (@countLegend){
	@coord = $tmpim->stringFT($tmpWhite, $fontName, $fontPoint, 0, 10, 180, $_);
	if ($countWidth < $coord[2]-$coord[0]){
	  $countWidth = $coord[2]-$coord[0];
	}
      }
      $legendWidth = $lWidth+$countWidth+4*$inCellBorder+3;
      $countStartPos = $lWidth+2*$inCellBorder+1;
    }
  }

  my ($internWidth, $internHeight, @internHPos, @internVPos, @internList);
  if (defined($plotIntern)){
    # Internal fragments
    for (my $i = 0; $i < @{$table->{mass}{intern}}; $i++){
      for (my $j = 1; $j < @{$table->{mass}{intern}[$i]}; $j+=2){
	push(@internList, [$table->{mass}{intern}[$i][0], $table->{mass}{intern}[$i][$j], defined($table->{match}{intern}[$i][$j+1]) ? $table->{intens}{intern}[$i][$j+1] : undef]);
      }
    }
    my ($maxFrag, $maxAA);
    for (my $i = 0; $i < @internList; $i++){
      $maxFrag = length($internList[$i][0]) if (length($internList[$i][0]) > $maxFrag);
      $maxAA = length($internList[$i][1]) if (length($internList[$i][1]) > $maxAA);
    }
    @internHPos = (0);
    for (my $i = 0; $i < $nColIntern; $i++){
      push(@internHPos, $internHPos[-1]+$maxFrag*$fontWidth+2*$inCellBorder+1);
      push(@internHPos, $internHPos[-1]+$maxAA*$fontWidth+2*$inCellBorder+1);
    }
    @internVPos = ($hLines[-1]+2*$inCellBorder);
    for (my $i = 0; $i < int(scalar(@internList)/$nColIntern); $i++){
      push(@internVPos, $internVPos[-1]+$cellHeight);
    }
    push(@internVPos, $internVPos[-1]+$cellHeight) unless (scalar(@internList) % $nColIntern == 0);
  }

  # Determines size
  my $imageWidth = $vLines[-1]+1;
  my $imageHeight = $hLines[-1]+1;
  if ($legend eq 'right'){
    $imageWidth += $legendWidth+2*$inCellBorder;
    if (defined($plotIntern)){
      $imageHeight = $internVPos[-1]+1;
      $imageWidth = $internHPos[-1]+1 if ($internHPos[-1]+1 > $imageWidth);
    }
  }
  elsif ($legend eq 'bottom'){
    if (defined($plotIntern)){
      if ($internHPos[-1]+2*$inCellBorder+$legendWidth+1 > $imageWidth){
	# Enlarge image because of overlap
	$imageWidth = $internHPos[-1]+2*$inCellBorder+$legendWidth+1;
      }
      $imageHeight = max($imageHeight+$legendHeight+2*$inCellBorder-1, $internVPos[-1]+1);
    }
    else{
      $imageHeight += $legendHeight+2*$inCellBorder-1;
    }
  }
  elsif (defined($plotIntern)){
    $imageHeight = $internVPos[-1]+1;
  }

  # Creates the graphic image and allocates colors
  my $im = new GD::Image($imageWidth, $imageHeight);
  my $white = $im->colorAllocate(255,255,255);
  my $black = $im->colorAllocate(0,0,0);
  my $blue= $im->colorAllocate(0,72,223);
  my $red = $im->colorAllocate(255,16,0);
  my $green = $im->colorAllocate(19,232,0);
  my $yellow = $im->colorAllocate(255,255,80);
  my $orange = $im->colorAllocate(255,180,0);

  $bgColor = defined($bgColor) ? $im->colorAllocate(@$bgColor) : $white;
  $lineColor = defined($lineColor) ? $im->colorAllocate(@$lineColor) : $black;
  $textColor = defined($textColor) ? $im->colorAllocate(@$textColor) : $black;
  $modifAAColor = defined($modifAAColor) ? $im->colorAllocate(@$modifAAColor) : $blue;

  # Prepares the color scale
  my (@color, @legendColor);
  if (defined($colorScale)){
    # User defined scale
    for (my $i = 0; $i < @$colorScale; $i += 8){
      push(@color, $im->colorAllocate($colorScale->[$i+1], $colorScale->[$i+2], $colorScale->[$i+3]));
      push(@legendColor, $im->colorAllocate($colorScale->[$i+5], $colorScale->[$i+6], $colorScale->[$i+7]));
    }
  }
  elsif ($table->{intSel} eq 'order'){
    @color = ($blue, $red, $orange, $yellow, $green);
    @legendColor = ($white, $white, $black, $black, $black);
  }
  elsif ($table->{intSel} eq 'relative'){
    @color = ($blue, $red, $orange, $yellow, $green);
    @legendColor = ($white, $white, $black, $black, $black);
  }
  elsif ($table->{intSel} eq 'log'){
    @color = ($blue, $red, $orange, $yellow, $green);
    @legendColor = ($white, $white, $black, $black, $black);
  }
  elsif ($table->{intSel} eq 'original'){
    @color = ($blue, $red, $orange, $yellow, $green);
    @legendColor = ($white, $white, $black, $black, $black);
  }
  else{
    croak("Unknown intSel value [$table->{intSel}]");
  }

  # Plots the horizontal lines and fragment names
  $im->filledRectangle(0, 0, $imageWidth-1, $imageHeight-1, $bgColor);
  for (my $i = 0; $i < @hLines; $i++){
    $im->line(0, $hLines[$i], $vLines[-1], $hLines[$i], $lineColor);
  }
  for (my $i = 0; $i < @fragNames; $i++){
    if (defined($font)){
      $im->string($font, $inCellBorder+1, $hLines[$i+1]+$inCellBorder+1, $fragNames[$i], $textColor);
    }
    else{
      $im->stringFT($textColor, $fontName, $fontPoint, 0, $inCellBorder+1+$ttHShift, $hLines[$i+1]+$inCellBorder+1+$ttVShift, $fragNames[$i]);
    }
  }

  # Plots the peptide sequence
  for (my $i = 0; $i < @aa; $i++){
    if ($modified[$i] == 0){
      # Plots as is
      if (defined($font)){
	$im->string($font, $vLines[$i+1]+$inCellBorder+1, $inCellBorder+1, $aa[$i], $textColor);
      }
      else{
	$im->stringFT($textColor, $fontName, $fontPoint, 0, $vLines[$i+1]+$inCellBorder+1+$ttHShift, $inCellBorder+1+$ttVShift, $aa[$i]);
      }
    }
    elsif ($modified[$i] == 1){
      # Change color
      if (defined($font)){
	$im->string($font, $vLines[$i+1]+$inCellBorder+1, $inCellBorder+1, $aa[$i], $modifAAColor);
      }
      else{
	$im->stringFT($modifAAColor, $fontName, $fontPoint, 0, $vLines[$i+1]+$inCellBorder+1+$ttHShift, $inCellBorder+1+$ttVShift, $aa[$i]);
      }
    }
    else{
      # Overlines
      if (defined($font)){
	$im->string($font, $vLines[$i+1]+$inCellBorder+1, $inCellBorder+1, $aa[$i], $textColor);
      }
      else{
	$im->stringFT($textColor, $fontName, $fontPoint, 0, $vLines[$i+1]+$inCellBorder+1+$ttHShift, $inCellBorder+1+$ttVShift, $aa[$i]);
      }
      $im->line($vLines[$i+1]+$inCellBorder+1, 2, $vLines[$i+2]-$inCellBorder-1, 2, $textColor);
      $im->line($vLines[$i+1]+$inCellBorder+1, 3, $vLines[$i+2]-$inCellBorder-1, 3, $textColor);
    }
  }

  my $height = $cellHeight;
  my $vRadius = 0.5*$height;
  my $width = $vLines[2]-$vLines[1]-2*$inCellBorder;
  if ($width > $hLines[2]-$hLines[1]-2*$inCellBorder){
    $width = $hLines[2]-$hLines[1]-2*$inCellBorder;
  }
  my $hRadius = 0.5*$width;

  if ($style eq 'circle'){
    $im->line($vLines[1], $hLines[1], $vLines[1], $hLines[-1], $lineColor);
    $im->line($vLines[0], 0, $vLines[0], $hLines[-1], $lineColor);
    $im->line($vLines[-1], 0, $vLines[-1], $hLines[-1], $lineColor);
    for (my $i = 0; $i < @{$table->{mass}{term}}; $i++){
      for (my $j = 1; $j < @{$table->{mass}{term}[$i]}; $j++){
	if (defined($table->{mass}{term}[$i][$j])){
	  # Draw circle
	  if (defined($table->{intens}{term}[$i][$j])){
	    # Match, coloured circle
	    $im->filledEllipse($vLines[$j]+$hRadius, $hLines[$i+1]+$vRadius, $width, $width, $color[selectColor(\@intThres, $table->{intens}{term}[$i][$j])]);
	    $im->ellipse($vLines[$j]+$hRadius, $hLines[$i+1]+$vRadius, $width, $width, $lineColor);
	  }
	  else{
	    # No match, empty circle
	    $im->ellipse($vLines[$j]+$hRadius, $hLines[$i+1]+$vRadius, $width, $width, $lineColor);
	  }
	}
	else{
	  # Impossible mass, draw a point
	  $im->rectangle($vLines[$j]+$hRadius, $hLines[$i+1]+$vRadius, $vLines[$j]+$hRadius+1, $hLines[$i+1]+$vRadius+1, $lineColor);
	}
      }
    }
  }
  elsif ($style eq 'square'){
    for (my $i = 1; $i < @vLines-1; $i++){
      $im->line($vLines[$i], $hLines[1], $vLines[$i], $hLines[-1], $lineColor);
    }
    $im->line($vLines[0], 0, $vLines[0], $hLines[-1], $lineColor);
    $im->line($vLines[-1], 0, $vLines[-1], $hLines[-1], $lineColor);
    for (my $i = 0; $i < @{$table->{mass}{term}}; $i++){
      for (my $j = 1; $j < @{$table->{mass}{term}[$i]}; $j++){
	if (defined($table->{mass}{term}[$i][$j])){
	  # Existing mass
	  if (defined($table->{intens}{term}[$i][$j])){
	    # Match, fill the cell with color
	    $im->filledRectangle($vLines[$j]+1, $hLines[$i+1]+1, $vLines[$j+1]-1, $hLines[$i+2]-1, $color[selectColor(\@intThres, $table->{intens}{term}[$i][$j])]);
	  }
	}
	else{
	  # Impossible mass, draw a little slash
	  $im->line($vLines[$j]+$hRadius-2, $hLines[$i+1]+$vRadius-2, $vLines[$j]+$hRadius+3, $hLines[$i+1]+$vRadius+3, $lineColor);
	}
      }
    }
  }
  else{
    croak("Unknown style [$style]");
  }

  if (defined($legend)){
    my ($legLeft, $legTop) = ($legend eq 'right') ? ($vLines[-1]+2*$inCellBorder, $hLines[-1]-$legendHeight+1) : ($imageWidth-1-$legendWidth, $hLines[-1]+2*$inCellBorder);
    my $countRight = $legLeft+$legendWidth-$inCellBorder;
    my $legRight = $legLeft+$countStartPos-$inCellBorder;
    $im->rectangle($legLeft, $legTop, $legLeft+$legendWidth, $legTop+$legendHeight-1, $lineColor);
    for (my $i = 1; $i < @legend; $i++){
      $im->line($legLeft, $legTop+$i*$cellHeight, $legLeft+$legendWidth, $legTop+$i*$cellHeight, $lineColor);
    }
    my $n = scalar(@legend)-1;
    my @coord;
    for (my $i = 0; $i < @legend; $i++){
      $im->filledRectangle($legLeft+1, $legTop+$i*$cellHeight+1, $legLeft+$countStartPos, $legTop+($i+1)*$cellHeight-1, $color[$n-$i]);
      if(defined($font)){
	$im->string($font, $legRight-length($legend[$n-$i])*$nativeFontWidth, $legTop+$i*$cellHeight+$inCellBorder+1, $legend[$n-$i], $legendColor[$n-$i]);
	$im->string($font, $countRight-length($countLegend[$n-$i])*$nativeFontWidth, $legTop+$i*$cellHeight+$inCellBorder+1, $countLegend[$n-$i], $textColor);
      }
      else{
	@coord = $tmpim->stringFT($tmpWhite, $fontName, $fontPoint, 0, $inCellBorder+1+$ttHShift, $inCellBorder+1+$ttVShift, $legend[$n-$i]);
	my $length = $coord[2]-$coord[0];
	$im->stringFT($legendColor[$n-$i], $fontName, $fontPoint, 0, $legRight-$length, $legTop+$i*$cellHeight+$inCellBorder+1+$ttVShift, $legend[$n-$i]);
	@coord = $tmpim->stringFT($tmpWhite, $fontName, $fontPoint, 0, $inCellBorder+1+$ttHShift, $inCellBorder+1+$ttVShift, $countLegend[$n-$i]);
	$length = $coord[2]-$coord[0];
	$im->stringFT($textColor, $fontName, $fontPoint, 0, $countRight-$length, $legTop+$i*$cellHeight+$inCellBorder+1+$ttVShift, $countLegend[$n-$i]);
      }
    }
    $im->line($legLeft+$countStartPos, $legTop, $legLeft+$countStartPos, $legTop+$legendHeight-1, $lineColor);
  }

  if (defined($plotIntern)){
    # Draws lines
    for (my $i = 0; $i < @internVPos; $i++){
      $im->line(0, $internVPos[$i], $internHPos[-1], $internVPos[$i], $lineColor);
    }
    for (my $i = 0; $i < @internHPos; $i++){
      $im->line($internHPos[$i], $internVPos[0], $internHPos[$i], $internVPos[-1], $lineColor);
    }

    # Adds text and color
    my $line = 0;
    for (my $i = 0; $i < @internList; $i += $nColIntern, $line++){
      my $col = 0;
      for (my $j = 0; ($i+$j < @internList) && ($j < $nColIntern); $j++, $col += 2){
	if (defined($font)){
	  $im->string($font, $internHPos[$col]+$inCellBorder+1, $internVPos[$line]+$inCellBorder+1, $internList[$i+$j][0], $textColor);
	}
	else{
	  $im->stringFT($textColor, $fontName, $fontPoint, 0, $internHPos[$col]+$inCellBorder+1+$ttHShift, $internVPos[$line]+$inCellBorder+1+$ttVShift, $internList[$i+$j][0]);
	}
	if (defined($internList[$i+$j][2])){
	  my $index = selectColor(\@intThres, $internList[$i+$j][2]);
	  $im->filledRectangle($internHPos[$col+1]+1, $internVPos[$line]+1, $internHPos[$col+2]-1, $internVPos[$line+1]-1, $color[$index]);
	  if (defined($font)){
	    $im->string($font, $internHPos[$col+1]+$inCellBorder+1, $internVPos[$line]+$inCellBorder+1, $internList[$i+$j][1], $legendColor[$index]);
	  }
	  else{
	    $im->stringFT($legendColor[$index], $fontName, $fontPoint, 0, $internHPos[$col+1]+$inCellBorder+1+$ttHShift, $internVPos[$line]+$inCellBorder+1+$ttVShift, $internList[$i+$j][1]);
	  }
	}
	else{
	  if (defined($font)){
	    $im->string($font, $internHPos[$col+1]+$inCellBorder+1, $internVPos[$line]+$inCellBorder+1, $internList[$i+$j][1], $textColor);
	  }
	  else{
	    $im->stringFT($textColor, $fontName, $fontPoint, 0, $internHPos[$col+1]+$inCellBorder+1+$ttHShift, $internVPos[$line]+$inCellBorder+1+$ttVShift, $internList[$i+$j][1]);
	  }
	}
      }
    }
  }

  if (defined($format)){
    # Creates file
    if ($fhandle){
      binmode $fhandle;
      print $fhandle $im->$format;
    }
    else{
      $fname =~ s/\.$format$//;
      open(FGD, ">$fname.$format") || croak("Cannot open file [$fname.$format]: $!");
      binmode FGD;
      print FGD $im->$format;
      close(FGD);
    }
  }
  else{
    # Returns the image for further processing
    return $im;
  }
} # plotSpectrumMatch


=head1 FUNCTIONS

=head2 cmpFragTypes

This function can be used in a sort of fragment type names. Fragment
type names are assumed to follow the rule:

=over 4

=item internal fragments

They are named after their generic name, only immonium ions
are supported so far and they are named 'immo'.

=item N-/C-terminal fragments

They must comply with the pattern

  ion&charge - loss1 -loss2 - ...

For instance, singly charged b ions are simply named 'b' and
their doubly and triply counterparts are names 'b++' and
'b+++'. This is the ion&charge part of the pattern above.

The losses may occur once or several times, multiple losses
are indicated in parentheses preceeded by multiplicity.
Examples are:

  b-H2O
  b-3(H2O)
  b++-H2O-NH3
  b++-3(H2O)-NH3
  y-H2O-2(H3PO4)-NH3

=back

The order on fragment type names is defined as follows: (1) immonium
ions always come after N-/C-terminal fragments; (2) N-/C-terminal
fragment types are compared by doing a sequence of comparisons
which continues as long as the compared values are equal. The first
comparison is on the ion type (a,b,y,...) followed by a comparison
on the charge. If ion types and charges are equal, comparisons
are made on the losses. The fragment that has less loss types is
considered smaller. If the two fragment types have the same number
of loss types then the losses are sorted lexicographically and the
first ones are compared on their name, if the names are the same then
the comparison is on the multiplicity, if the multiplicities are
the same then the second losses are compared, etc.

Asterisks that are used for signaling multiple possible losses are
ignored in the comparisons.

Since this function is defined in package MSMSOutput and it is used in
other packages with function sort (and predefined variables $a and $b),
we had to use prototypes ($$). Therefore it can no longer be exported
by the package MSMSOutput and you have to call it via MSMSOutput::cmpFragTypes.

Example:

foreach (sort MSMSOutput::cmpFragTypes ('y','b','y++','a','b-NH3','b-2(NH3)','b++-10(NH3)','b-H2O-NH3','immo(Y)', 'b++','y-NH3*','y-H2O*','z')){
  print $_,"\n";
}

=cut
sub cmpFragTypes ($$)
{
  my ($fragA, $fragB) = @_;

  # Presence of an immonium ion
  my $immoA = index($fragA, 'immo') != -1;
  my $immoB = index($fragB, 'immo') != -1;
  if ($immoA && $immoB){
    return 0;
  }
  elsif ($immoA && !$immoB){
    return 1;
  }
  elsif (!$immoA && $immoB){
    return -1;
  }

  # Only N-/C-terminal fragments

  # Extracts ion types and charge, compare them
  my ($ionA, @partA) = split(/\-/, $fragA);
  my ($ionB, @partB) = split(/\-/, $fragB);
  $ionA =~ /(\++)/;
  my $chargeA = length($1) || 1;
  $ionA =~ s/\+//g;
  $ionB =~ /(\++)/;
  my $chargeB = length($1) || 1;
  $ionB =~ s/\+//g;
  my $comp = ($ionA cmp $ionB) || ($chargeA <=> $chargeB);
  return $comp if ($comp);

  # Compares the number of losses
  $comp = @partA <=> @partB;
  return $comp if ($comp);

  # Prepares the losses for comparison
  my @lossA;
  foreach my $loss (@partA){
    $loss =~ s/\*//g;
    if ($loss =~ /(\d+)\((\w+)\)/){
      # Multiple losses
      push(@lossA, [$2, $1]);
    }
    else{
      # Single loss
      push(@lossA, [$loss, 1]);
    }
  }
  @lossA = sort {$a->[0] cmp $b->[0]} @lossA;
  my @lossB;
  foreach my $loss (@partB){
    $loss =~ s/\*//g;
    if ($loss =~ /(\d+)\((\w+)\)/){
      # Multiple losses
      push(@lossB, [$2, $1]);
    }
    else{
      # Single loss
      push(@lossB, [$loss, 1]);
    }
  }
  @lossB = sort {$a->[0] cmp $b->[0]} @lossB;

  # Compares the losses
  for (my $i = 0; $i < @lossA; $i++){
    $comp = ($lossA[$i][0] cmp $lossB[$i][0]) || ($lossA[$i][1] <=> $lossB[$i][1]);
    return $comp if ($comp);
  }

  return 0;

} # cmpFragTypes


=head2 annotatePept($pept, $modif, $modifLvl)

Returns a vector whose cells contain each amino acid of
the peptide sequence annotated with their eventual modifi-
cations.

This function is exported for allowing users to prepare
peptide sequences for display purposes. The parameters are:

=over 4

=item $pept

The peptide sequence.

=item $modif

The modification string or the modification vector.

=item $modifLvl

Controls how the modifications are highlighted in the returned
vector.

If not set or set to 0, this parameter causes the modified amino
acids not to be indicated. If set to 1, the modified amino acids
are marked by an asterisk. If set to 2, the modified amino acids
are followed by the name of the modification between curly
brackets.

=back

Example:

print join('', annotatePept('ACCTK', '::Cys_CAM:Cys_CAM:::', 2)), "\n";

=cut
sub annotatePept
{
  my ($pept, $modif, $modifLvl) = @_;

  # Prepares data and set the peptide letters as an initial value for the result
  my $len = length($pept);
  my @pept = split(//, $pept);
  my @modif = (ref($modif) eq 'ARRAY') ? @$modif : split(/:/, $modif);
  my @splitPept = @pept;

  # N-term
  if (length($modif[0]) > 0){
    # N-term
    if ($modifLvl == 1){
      $splitPept[0] = '*-'.$splitPept[0];
    }
    elsif ($modifLvl == 2){
      $splitPept[0] = "{$modif[0]}-".$splitPept[0];
    }
  }

  # Amino acids
  for (my $i = 0; $i < @pept; $i++){
    if (length($modif[$i+1]) > 0){
      if ($modifLvl == 1){
	$splitPept[$i] .= '*';
      }
      elsif ($modifLvl == 2){
	$splitPept[$i] .= "{$modif[$i+1]}";
      }
    }
  }

  # C-term
  if (length($modif[$len+1]) > 0){
    if ($modifLvl == 1){
      $splitPept[$len-1] .= '-*';
    }
    elsif ($modifLvl == 2){
      $splitPept[$len-1] .= "-{$modif[$len+1]}";
    }
  }

  return @splitPept;

} # annotatePept


=head2 normalizeIntensities($inSel, $expSpectrum, $normInt, [$massIndex, [$intensityIndex]])

Normalizes experimental peaks intensities. The parameters
are:

=over 4

=item $intSel

This parameter controls how the peak intensities are normalized.
Default choice is 'order' for relative order; other possible
choices are 'relative' for relative intensity, 'original' for
no normalization, and 'log' for logarithmic transform.

=item $expSpectrum

The experimental spectrum.

=item $normInt

A reference to a hash that will contain the normalized
intensities (keys are the original intensities).

=item massIndex

The mass index in the experimental peak vectors, default 0. If expSpectrum
parameter is an ExpSpectrum object this index is read from the object directly.

=item intensityIndex

The intensity index in the experimental peak vectors, default 1. If expSpectrum
parameter is an ExpSpectrum object this index is read from the object directly.

=back

=cut
sub normalizeIntensities
{
  my ($intSel, $spec, $normInt, $massIndex, $intensityIndex) = @_;

  $massIndex = $massIndex || 0;
  $intensityIndex = $intensityIndex || 1;

  # Determines experimental spectrum type
  my $expSpectrum;
  if (ref($spec) && (ref($spec) ne 'ARRAY') && $spec->isa('InSilicoSpectro::Spectra::ExpSpectrum')){
    $expSpectrum = $spec->spectrum();
    $massIndex = $spec->peakDescriptor()->getFieldIndex('mass');
    $intensityIndex = $spec->peakDescriptor()->getFieldIndex('intensity');
    if (!defined($intensityIndex)){
      $intensityIndex = $spec->peakDescriptor()->getFieldIndex('height');
    }
  }
  else{
    $expSpectrum = $spec;
  }

  # Normalizes

  if ($intSel eq 'original'){
    for (my $i = 0; $i < @$expSpectrum; $i++){
      $normInt->{$expSpectrum->[$i][$massIndex]} = $expSpectrum->[$i][$intensityIndex];
    }
  }
  elsif ($intSel eq 'log'){
    for (my $i = 0; $i < @$expSpectrum; $i++){
      $normInt->{$expSpectrum->[$i][$massIndex]} = ($expSpectrum->[$i][$intensityIndex] > 1) ? log($expSpectrum->[$i][$intensityIndex]) : 0;
    }
  }
  elsif ($intSel eq 'relative'){
    my $maxIntensity = -9999;
    for (my $i = 0; $i < @$expSpectrum; $i++){
      if ($expSpectrum->[$i][$intensityIndex] > $maxIntensity){
	$maxIntensity = $expSpectrum->[$i][$intensityIndex];
      }
    }
    for (my $i = 0; $i < @$expSpectrum; $i++){
      $normInt->{$expSpectrum->[$i][$massIndex]} = $expSpectrum->[$i][$intensityIndex]/$maxIntensity;
    }
  }
  elsif ($intSel eq 'order'){
    if (@$expSpectrum > 1){
      # Sorts first to know the order
      my (@sortedInt, %backHash, %already);
      for (my $i = 0; $i < @$expSpectrum; $i++){
	push(@sortedInt, $expSpectrum->[$i][$intensityIndex]) unless($already{$expSpectrum->[$i][$intensityIndex]}); # Each intensity is added once
	push(@{$backHash{$expSpectrum->[$i][$intensityIndex]}}, $expSpectrum->[$i][$massIndex]); # List of the masses sharing the same intensity
	$already{$expSpectrum->[$i][$intensityIndex]} = 1;
      }
      @sortedInt = sort {$a <=> $b} @sortedInt;

      # Uses the order to compute the relative order
      my $n = scalar(@sortedInt)-1;
      for (my $i = 0; $i < @sortedInt; $i++){
	# For each unique intensity we associated it to all the masses that shared this intensity
	for (my $j = 0; $j < @{$backHash{$sortedInt[$i]}}; $j++){
	  $normInt->{$backHash{$sortedInt[$i]}[$j]} = $i/$n;
	}
      }
    }
    elsif (@$expSpectrum == 1){
      $normInt->{$expSpectrum->[0][$massIndex]} = 1;
    }
  }
  else{
    croak("Unknown intensity normalization [$intSel]");
  }

} # normalizeIntensities


=head2 htmlCSS(%h)

This function returns a string that can be used for defining a CSS, which
is then used by the tables created by functions htmlTerm and htmlIntern.
To give you more flexibility, we do not include the <style> tags in the
string such that you can add the styles returned
by htmlCSS where you like.

Alternatively, you can choose not to use this function and define totally different
styles!

The named parameters are:

=over 4

=item lineCol1, lineCol2

The two colors used for the lines, default colors are
'#DDFFFF' and '#EEEEEE'.

=item boldTitle

Peptide sequence in bold if set to any value.

=item bgTitle

Background color for the peptide sequence, default '#CCFFCC'.

=item boldFrag

Fragment names in bold if set to any value.

=item bgFrag

Background color for the fragment names, default '#FFFFBB'.

=item bgIntern

The color used for the lines in the internal fragments table,
default '#EEEEEE'.

=back

Example :

  my $msms = new InSilicoSpectro::InSilico::MSMSOutput(...);
  print "<html>\n<head>\n<style type=\"text/css\">\n";
  print InSilicoSpectro::InSilico::MSMSOutput::htmlCSS(boldTitle=>1);
  print "</style>\n</head>\n<body><table border=0 cellspacing=5>\n";
  print "\n",$msms->htmlTerm(css=>1);
  print "</table><br><br><table border=0 cellspacing=5>\n";
  print "\n",$msms->htmlIntern(css=>1);
  print "</table></html>\n";

=cut
sub htmlCSS
{
  my (%h) = @_;
  my ($bgTitle, $boldTitle, $bgFrag, $boldFrag, $lineCol1, $lineCol2, $bgIntern) = ($h{bgTitle}, $h{boldTitle}, $h{bgFrag}, $h{boldFrag}, $h{lineCol1}, $h{lineCol2}, $h{bgIntern});

  $lineCol1 = $lineCol1 || '#DDFFFF';
  $lineCol2 = $lineCol2 || '#EEEEEE';
  $bgFrag = $bgFrag || '#FFFFBB';
  $bgTitle = $bgTitle || '#CCFFCC';
  $bgIntern = $bgIntern || '#EEEEEE';

  my $string;

  $string .= "td.massOutputColTitleFrag {text-align: left; background-color: $bgFrag";
  $string .= '; font-weight: bold' if (defined($boldTitle));
  $string .= "}\n";

  $string .= "td.massOutputColTitle {text-align: center; background-color: $bgTitle";
  $string .= '; font-weight: bold' if (defined($boldTitle));
  $string .= "}\n";

  $string .= "td.massOutputFragName {text-align: left; background-color: $bgFrag";
  $string .= '; font-weight: bold' if (defined($boldFrag));
  $string .= "}\n";

  $string .= "td.massOutputLineCol1 {text-align: right; background-color: $lineCol1}\n";
  $string .= "td.massOutputLineCol2 {text-align: right; background-color: $lineCol2}\n";
  $string .= "td.massOutputInternCenter {text-align: center; background-color: $bgIntern}\n";
  $string .= "td.massOutputInternRight {text-align: right; background-color: $bgIntern}\n";

  return $string;

} # htmlCSS


=head2 chooseColorLineNum

Function for HTML output that alternates the line colors for every line.

=cut
sub chooseColorLineNum
{
  my ($frag, $prevFrag, $current, $old) = @_;

  # Exchanges each time
  my $tmp = $$current;
  $$current = $$old;
  $$old = $tmp;

} # chooseColorLineNum


=head2 chooseColorFrag

Function for HTML output that changes the line color when the type of fragment
changes; b-H2O and b-2(H2O) are considered the same type by this function.

=cut
sub chooseColorFrag
{
  my ($frag, $prevFrag, $current, $old) = @_;

  my $change = 0;

  # Presence of an innomium ion
  my $immoA = index($frag, 'immo') != -1;
  my $immoB = index($prevFrag, 'immo') != -1;
  if ($immoA && !$immoB){
    $change = 1;
  }
  elsif (!$immoA && $immoB){
    $change = 1;
  }
  elsif (!$immoA && !$immoB){
    # Extracts ion types and charge, compare them
    my ($ionA, @partA) = split(/\-/, $frag);
    my ($ionB, @partB) = split(/\-/, $prevFrag);
    $ionA =~ /(\++)/;
    my $chargeA = length($1) || 1;
    $ionA =~ s/\+//g;
    $ionB =~ /(\++)/;
    my $chargeB = length($1) || 1;
    $ionB =~ s/\+//g;
    if (($ionA cmp $ionB) || ($chargeA <=> $chargeB)){
      $change = 1;
    }
    elsif (@partA <=> @partB){
      # Different number of losses
      $change = 1;
    }
    else{
      # Prepares the losses for comparison
      my @lossA;
      foreach my $loss (@partA){
	$loss =~ s/\*//g;
	if ($loss =~ /(\d+)\((\w+)\)/){
	  # Multiple losses
	  push(@lossA, [$2, $1]);
	}
	else{
	  # Single loss
	  push(@lossA, [$loss, 1]);
	}
      }
      @lossA = sort {$a->[0] cmp $b->[0]} @lossA;
      my @lossB;
      foreach my $loss (@partB){
	$loss =~ s/\*//g;
	if ($loss =~ /(\d+)\((\w+)\)/){
	  # Multiple losses
	  push(@lossB, [$2, $1]);
	}
	else{
	  # Single loss
	  push(@lossB, [$loss, 1]);
	}
      }
      @lossB = sort {$a->[0] cmp $b->[0]} @lossB;

      # Compares the losses by ignoring multiplicity (we parse it just in case)
      for (my $i = 0; $i < @lossA; $i++){
	if ($lossA[$i][0] cmp $lossB[$i][0]){
	  $change = 1;
	  last;
	}
      }
    }
  }

  if ($change){
    my $tmp = $$current;
    $$current = $$old;
    $$old = $tmp;
  }

} # chooseColorFrag


=head2 plotLegendOnly(%h)

This function plots the color scale only and should be used
if you don not want to display it for each match plot. Note
that the legend generated by PlotSpectrumMatch contains extra
information that is specific to the match, i.e. the count of
matched peaks per intensity bin. This information is not
reported if you decide to save space and only display the
color scale once.

The named parameters are (see plotSpectrumMatch for detailed
explanations):

=over 4

=item fname

The file name of the generated image.

=item fhandle

An open file handle for writing the generated image. It has priority over
parameter fname and the file handle will be set in binmode.

=item format

The graphic file format.

=item fontChoice

The size of the graphics is controlled via the choice of the font.

=item inCellBorder

Number of pixels between lines and text, default 1.

=item colorScale

This parameter is used for defining a list of intensities thresholds and
corresponding colors used when highlighting the table cells to indicate
fragment matches.

=item lineColor

A reference to a vector of three values (R, G, B) used to defined the line
color, default black.

=item intSel

In case no user-defined color scale is provided, a default color
scale is used instead. To properly adjust this scale to the intensity
normalization method it is important to indicate via parameter intSel
which is this normalization. Possible values are listed in function
normalizeIntensities.

=back

=cut
sub plotLegendOnly
{
  my (%h) = @_;
  my ($fname, $fhandle, $fontChoice, $intSel, $colorScale, $format, $inCellBorder, $lineColor) = ($h{fname}, $h{fhandle}, $h{fontChoice}, $h{intSel}, $h{colorScale}, $h{format}, $h{inCellBorder}, $h{lineColor});

  if (defined($format)){
    if (($format ne 'png') && ($format ne 'xbm') && ($format ne 'gif') && ($format ne 'gdf') && ($format ne 'bmp') && ($format ne 'sgi') && ($format ne 'pcx') && ($format ne 'jpeg') && ($format ne 'tiff')){
      croak("Wrong file format [$format]");
    }
  }

  $fontChoice = $fontChoice || 'default:Large';
  $inCellBorder = $inCellBorder || 1;

  # Determines font size
  my ($fontWidth, $fontHeight, $font, $fontName, $fontPoint, $ttHShift, $ttVShift);
  my ($class, $size) = split(/:/, $fontChoice);
  if ($class eq 'default'){
    if ($size eq 'Tiny'){
      $fontWidth = gdTinyFont->width;
      $fontHeight = gdTinyFont->height;
      eval '$font = gdTinyFont';
    }
    elsif ($size eq 'Small'){
      $fontWidth = gdSmallFont->width;
      $fontHeight = gdSmallFont->height;
      eval '$font = gdSmallFont';
    }
    elsif ($size eq 'MediumBold'){
      $fontWidth = gdMediumBoldFont->width;
      $fontHeight = gdMediumBoldFont->height;
      eval '$font = gdMediumBoldFont';
    }
    elsif ($size eq 'Large'){
      $fontWidth = gdLargeFont->width;
      $fontHeight = gdLargeFont->height;
      eval '$font = gdLargeFont';
    }
    elsif ($size eq 'Giant'){
      $fontWidth = gdGiantFont->width;
      $fontHeight = gdGiantFont->height;
      eval '$font = gdGiantFont';
    }
    else{
      croak("Unknown size [$size] for font class [$class]");
    }
  }
  else{
    if (-e $class){
      $fontName = $class;
      $fontPoint = $size;
      my @coord = $tmpim->stringFT($tmpWhite, $fontName, $fontPoint, 0, 10, 180, 'AFGHKMPQRSWYbyz*#°');
      $fontHeight = $coord[1]-$coord[7];
      $ttHShift = 10-$coord[0];
      $ttVShift = 180-$coord[1];
    }
    else{
      croak("Unknown font class [$class]");
    }
  }

  # Computes image size
  my $cellHeight = $fontHeight+2*$inCellBorder+1;
  $ttVShift += $cellHeight;
  my ($legendHeight, $legendWidth, @legend, @intThres);

  if (defined($colorScale)){
    # User defined scale
    for (my $i = 0; $i < @$colorScale; $i += 8){
      push(@intThres, $colorScale->[$i]);
      push(@legend, $colorScale->[$i+4]);
    }
  }
  elsif ($intSel eq 'order'){
    @intThres = (0, 0.3, 0.5, 0.7, 0.9);
    @legend = ('0 %', '30 %', '50 %', '70 %', '90 %');
  }
  elsif ($intSel eq 'relative'){
    @intThres = (0, 0.1, 0.2, 0.3, 0.5);
    @legend = ('0 %', '10 %', '20 %', '30 %', '50 %');
  }
  elsif ($intSel eq 'log'){
    @intThres = (0, 4.6, 6.2, 7.6, 9.2);
    @legend = ('1', '100', '500', '2000', '10000');
  }
  elsif ($intSel eq 'original'){
    @intThres = (0, 100, 500, 2000, 10000);
    @legend = ('0', '100', '500', '2000', '10000');
  }
  else{
    croak("Unknown intSel value [$intSel]");
  }

  $legendHeight = scalar(@legend)*$cellHeight+1;
  if (defined($font)){
    my $maxLen;
    foreach (@legend){
      $maxLen = length($_) if (length($_) > $maxLen);
    }
    $legendWidth = $maxLen*$fontWidth+2*$inCellBorder+2;
  }
  else{
    my @coord;
    foreach (@legend){
      @coord = $tmpim->stringFT($tmpWhite, $fontName, $fontPoint, 0, 10, 180, $_);
      if ($legendWidth < $coord[2]-$coord[0]){
	$legendWidth = $coord[2]-$coord[0];
      }
    }
    $legendWidth += 2*$inCellBorder+2;
  }

  # Creates the graphic image and allocates colors
  my $im = new GD::Image($legendWidth, $legendHeight);
  my $white = $im->colorAllocate(255,255,255);
  my $black = $im->colorAllocate(0,0,0);
  my $blue= $im->colorAllocate(0,72,223);
  my $red = $im->colorAllocate(255,16,0);
  my $green = $im->colorAllocate(19,232,0);
  my $yellow = $im->colorAllocate(255,255,80);
  my $orange = $im->colorAllocate(255,180,0);

  $lineColor = defined($lineColor) ? $im->colorAllocate(@$lineColor) : $black;

  # Prepares the color scale
  my (@color, @legendColor);
  if (defined($colorScale)){
    # User defined scale
    for (my $i = 0; $i < @$colorScale; $i += 8){
      push(@color, $im->colorAllocate($colorScale->[$i+1], $colorScale->[$i+2], $colorScale->[$i+3]));
      push(@legendColor, $im->colorAllocate($colorScale->[$i+5], $colorScale->[$i+6], $colorScale->[$i+7]));
    }
  }
  elsif ($intSel eq 'order'){
    @color = ($blue, $red, $orange, $yellow, $green);
    @legendColor = ($white, $white, $black, $black, $black);
  }
  elsif ($intSel eq 'relative'){
    @color = ($blue, $red, $orange, $yellow, $green);
    @legendColor = ($white, $white, $black, $black, $black);
  }
  elsif ($intSel eq 'log'){
    @color = ($blue, $red, $orange, $yellow, $green);
    @legendColor = ($white, $white, $black, $black, $black);
  }
  elsif ($intSel eq 'original'){
    @color = ($blue, $red, $orange, $yellow, $green);
    @legendColor = ($white, $white, $black, $black, $black);
  }
  else{
    croak("Unknown intSel value [$intSel]");
  }

  $im->rectangle(0, 0, $legendWidth-1, $legendHeight-1, $lineColor);
  for (my $i = 1; $i < @legend; $i++){
    $im->line(0, $i*$cellHeight, $legendWidth-1, $i*$cellHeight, $lineColor);
  }
  my $n = scalar(@legend)-1;
  my @coord;
  for (my $i = 0; $i < @legend; $i++){
    $im->filledRectangle(1, $i*$cellHeight+1, $legendWidth-2, ($i+1)*$cellHeight-1, $color[$n-$i]);
    if (defined($font)){
      $im->string($font, $legendWidth-$inCellBorder-1-length($legend[$n-$i])*$fontWidth, $i*$cellHeight+$inCellBorder+1, $legend[$n-$i], $legendColor[$n-$i]);
    }
    else{
      @coord = $tmpim->stringFT($tmpWhite, $fontName, $fontPoint, 0, $inCellBorder+1+$ttHShift, $inCellBorder+1+$ttVShift, $legend[$n-$i]);
      my $length = $coord[2]-$coord[0];
      $im->stringFT($legendColor[$n-$i], $fontName, $fontPoint, 0, $legendWidth-$inCellBorder-2-$length+$ttHShift, $i*$cellHeight+$inCellBorder+1+$ttVShift, $legend[$n-$i]);
    }
  }

  if (defined($format)){
    # Creates file
    if ($fhandle){
      binmode $fhandle;
      print $fhandle $im->$format;
    }
    else{
      $fname =~ s/\.$format$//;
      open(FGD, ">$fname.$format")|| croak("Cannot open file [$fname.$format]: $!");
      binmode FGD;
      print FGD $im->$format;
      close(FGD);
    }
  }
  else{
    # Returns the image for further processing
    return $im;
  }

} # plotLegendOnly


=head1 EXAMPLES

See programs starting with testMSMSOut in folder InSilicoSpectro/InSilico/test/.

=head1 AUTHORS

Jacques Colinge, Upper Austria University of Applied Science at Hagenberg

=cut
