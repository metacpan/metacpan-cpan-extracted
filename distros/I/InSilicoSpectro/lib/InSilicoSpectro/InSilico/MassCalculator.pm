package  InSilicoSpectro::InSilico::MassCalculator;

# Mass spectrometry Perl module for mass computations

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
@EXPORT = qw(readConfigurationFiles getMass setMass setMassType getMassType massFromComposition setModif modifToString getPeptideMass getCorrectCharge digestByRegExp nonSpecificDigestion $digestIndexPept $digestIndexStart $digestIndexEnd $digestIndexNmc $digestIndexMass $digestIndexModif $trypsinRegex $dibasicRegex matchPMF variablePeptide locateModif getSeries setSeries getLoss setLoss getFragType setFragType getFragTypeList setImmonium getImmonium getImmoniumMass getFragmentMasses matchSpectrumClosest matchSpectrumGreedy cmpFragTypes $invalidElementCall);
@EXPORT_OK = ();

use strict;
use XML::Twig;
use Carp;
use InSilicoSpectro::Utils::io;
use InSilicoSpectro::InSilico::CleavEnzyme;
use InSilicoSpectro::InSilico::ModRes;
use InSilicoSpectro::InSilico::AASequence;
use InSilicoSpectro::InSilico::Peptide;
use InSilicoSpectro::Spectra::PeakDescriptor;
use InSilicoSpectro::Spectra::ExpSpectrum;

=head1 NAME

MassCalculator - Implements common mass computations in mass spectrometry

=head1 SYNOPSIS

  use InSilicoSpectro::InSilico::MassCalculator;
  InSilicoSpectro::InSilico::MassCalculator::init('insilicodef.xml');

=head1 DESCRIPTION

MassCalculator Perl library is intended to support common mass
spectrometry-related computations that must be routinely performed by
bioinformaticians dealing with mass spectrometry data.

To accommodate as many as possible user requirements, we decided to both
support a classical procedural programming model and an object oriented
model. Per se MassCalculator is not designed as an object oriented code
but we provide a series of elementary classes for modeling proteins,
peptides, enzymes, etc. which MassCalculator is compatible with. Moreover,
the latter classes are rather simple and neutral in their design  such that
they should fit, after further derivations eventually, a large range of
code design.

We decided not to use Perl object oriented programming to stay with
relatively naive and simple code and to allow everybody to decide how to
include it in its own project. Nonetheless, MassCalculator is able to
deal with Perl objects we provide additionally to represent protein
sequences, peptides, enzymes, mass lists, and fragmentation spectra,
see their respective documentations.

MassCalculator is released under the LGPL license (see source code).

=head1 Configuration file and init function

One XML configuration file is necessary for MassCalculator.pm to work.
It contains definitions of chemical elements, amino acids, fragmentation
types, enzymes, etc.

These configuration files are read by the function init, which must be
called before the other functions are used. It is possible to provide
function init with another, or several others, file name(s).

=cut


# ----------------------------------------------------------------
# Reads basic definitions and stores them
# ----------------------------------------------------------------

our $MassCalcHome = $ENV{MassCalcHome} || '.';
# Type of mass (monoisotopic=0, average=1)
our $massType = 0;
# N-/C-Terminal mass corrections for peptides
our ($cTerm, $nTerm);
# Masses of amino acids, modifications, and atoms
our %elMass;
# Description of fragment types
our (%fragType, %series, %loss, $immoDelta, %immoAA);

# Predefined regular expressions for representing enzymes
our $trypsinRegex = qr/(?<=[KR])(?=[^P])/;
our $dibasicRegex = qr/(?<=[KR])(?=[KR])/;

# Indices for accessing digestion results
our $digestIndexPept = 0;
our $digestIndexStart = 1;
our $digestIndexEnd = 2;
our $digestIndexNmc = 3;
our $digestIndexMass = 4;
our $digestIndexModif = 5;

our $isInit;


#$invalidElementCall is the subroutine to be called when getElMass encounter an invalid element (either undef, carp, warn, confess...)
our $invalidElementCall=\&croak;

return 1;


=head2 init([$filename])

Opens the given file, or file ${phenyx.config.cleavenzymes} if no parameter was given, and stores
all the modif in the dictionary.

=cut
sub init
{
  # Init once only in case several modules use this one
  my @files=@_;
  return if ($isInit);

  undef(%elMass);
  undef(%fragType);
  undef(%series);
  undef(%loss);
  my $twig = XML::Twig->new(twig_handlers=>{oneElement => \&twigAddElement,
					    oneMolecule => \&twigAddMolecule,
					    oneAminoAcid => \&twigAddAminoAcid,
					    oneSeries => \&twigAddSeries,
					    oneLoss => \&twigAddLoss,
					    oneFragType => \&twigAddFragType,
					    oneInternFragType => \&twigAddInternFragType,
					    #oneModRes => \&twigAddModRes,
					    pretty_print=>'indented'});


 #read all the modres already defined and set a handler to register new one afterwards
  foreach(InSilicoSpectro::InSilico::ModRes::getList()){
    setModif($_);
  }
  InSilicoSpectro::InSilico::ModRes::registerModResHandler(\&InSilicoSpectro::InSilico::MassCalculator::setModif);

  if (@files){
    foreach (@files){
      #warn "reading MassCalculator.pm def from $_\n";
      $twig->parsefile($_) || croak("Cannot parse [$_]: $!");
    }
  }
  else{
    eval{
      require Phenyx::Config::GlobalParam;
      InSilicoSpectro::Utils::io::croakIt "no [phenyx.config.insilicodef] is set" unless defined Phenyx::Config::GlobalParam::get('phenyx.config.insilicodef');
      foreach (split /,/, Phenyx::Config::GlobalParam::get('phenyx.config.insilicodef')){
	print STDERR __PACKAGE__." opening [$_]\n" if ($InSilicoSpectro::Utils::io::VERBOSE);
	$twig->parsefile($_) || croak("Cannot parse [$_]: $!");
      }
    };
    if ($@){
      croak "not possible to open default config files: $@";
    }
  }

  $cTerm = getMass('el_H')+getMass('el_O');
  $nTerm = getMass('el_H');

  # Adds extra common molecules
  setMass('mol_CO', 'CO');
  setMass('mol_H3PO4', 'H3PO4');
  setMass('mol_HPO3', 'HPO3');
  setMass('mol_H5', 'H5');

  $isInit = 1;

} # init


# -----------------------------------------------------------------------------
# Gets and sets masses
# -----------------------------------------------------------------------------


=head2 massFromComposition($formula)

Computes monoisotopic and average masses from an atomic composition given
in $formula. Monoisotopic and average masses are returned as a vector of 2
elements. Negative numbers are possible to accommodate with losses or certain
modifications.

Example:

  print join(',', massFromComposition('HPO3')), "\n";

=cut
sub massFromComposition
{
  my ($formula) = @_;

  my $mono = 0;
  my $avg = 0;
  $formula =~ s/\s+//g;
  while ($formula =~ /([A-Z][a-z\+]?)([\-\d]*)/g){
    my $num = $2 || 1;
    $mono += $num*$elMass{"el_$1"}[0];
    $avg += $num*$elMass{"el_$1"}[1];
  }

  return ($mono, $avg);

} # massFromComposition


=head1 Basic mass functions

=head2 getMass($el, $mt)

Returns the mass, either monoisotopic or average mass depending on the
current setting or the parameter $mt, of elements, amino acids, modifications
and molecules.

=over 4

=item $el

Contains the name of the "object" whose mass is to return. $el must start with
el_ for elements (el_Na, el_H), with aa_ for amino acids (aa_Y, aa_T), with 
mol_ for molecules (mol_H2O), and mod_ for modifications (mod_Oxidation).

=item $mt

Contains the mass type (0=monoisotopic, 1=average). When this argument is not
provided (most common function use), the current setting of mass type is used.

=back

=cut
sub getMass
{
  # Returns the mass of the given element/molecule, according to $massType or to the second argument if defined
  my ($el, $mt) = @_;

  $mt = $massType if(!defined($mt));
   defined($elMass{$el}) || ( $invalidElementCall && $invalidElementCall->("Unknown element/molecule in getMass: [$el]"));
  $elMass{$el}[$mt];

} # getMass


=head2 setMass($symbol, $formula)

This function allows the user to set new molecule, element, amino acid, and modification
masses dynamically.

=over 4

=item $symbol

Contains the identifier of the new object with the appropriate prefix (el_, aa_,
mol_, or mod_).

=item $formula

Contains the atomic composition (it is used for computing monoisotopic and average
masses). Negative numbers of atoms are possible to deal with modifications.

Examples:

setMass('mol_NH3', 'NH3');

setMass('mol_H2O', 'H2O');

=back

=cut
sub setMass
{
  my ($symbol, $formula) = @_;
  croak("Already defined mass for [$symbol]") if (defined($elMass{$symbol}));

  my ($mono, $avg) = massFromComposition($formula);
  $elMass{$symbol} = [$mono, $avg];

} # setMass


=head2 setMassType($type)

Sets the current mass type. C<$type> must be equal to 0 (monoisotopic) or 1 (average).

=cut
sub setMassType
{
  my ($type) = @_;

  croak("Unknown mass type: [$type]") if (($type != 0) && ($type != 1));
  $massType = $type;

} # setMassType


=head2 getMassType

Returns the current mass type.

=cut
sub getMassType
{
  return $massType;

} # getMassType


=head2 setModif($mr)

add a InSilico::ModRes object 


=cut

sub setModif
{
  my $mr=shift;
  my $name=$mr->get('name');

  $elMass{"mod_$name"} = [$mr->{delta_monoisotopic}, $mr->{delta_average}];

} # setModif




# -----------------------------------------------------------
# Peptide functions
# -----------------------------------------------------------

=head1 Peptide-related functions

This section groups all the functions that are directly related to peptides, i.e.
peptide mass computation and protein digestion. 

=head2 Modifications

To properly deal with modified
proteins (and hence peptides) and compute their mass and MS/MS spectra, in case
of peptides, we introduce a convention that allows to localize modifications in
protein/peptide sequences.

A protein/peptide sequence is a sequence of amino acids 

  a_1 a_2 a_3 a_4 ... a_n.

The corresponding modifications are represented either as a string or as a
vector.

=head2 String representation

The string takes the form

  m_0:m_1:m_2:m_3:m_4: ... :m_n:m_(n+1),

where m_0 is the N-terminal site modification, m_i is a_i modification, and 
m_(n+1) is the C-terminal site modification. For instance, a peptide

  DEMSCGHTK

might be modified according to

  ACET_nterm:::Oxidation::Cys_CAM::Oxidation:::

which means that there is an N-terminal acetylation, the methionine and the
histidine are oxidized, and the cysteine is carboxyamidomethylated; no
C-terminal modification. We see that in this notation empty positions between
colons are possible to denote the absence of modification. The modification
identifiers come from the configuration file.

In the above string notation it is possible to define variable modifications,
see function variablePeptide.

=head2 Vector representation

Alternatively, modifications can be localized by using a vector of strings.
The length of the vector is len(peptide)+2 and element at index 0 corresponds
to the N-terminus, index len(peptide)+1 to the C-terminus and the indices
between 1 and len(peptide) correspond to the amino acids. The strings of this
vector follow the same rule as the strings between ':' in the modification
string, i.e. the contain the name of the modification or nothing, or they
define variable modifications, see function variablePeptide.

=head2 The PMF case

In PMF only the peptide masses matter and it is not necessary to know the
location of the modifications. We only need to know their numbers. Hence,
when dealing with PMF computations we introduce a third convention for
modification description. We use a vector that contains the number of
occurrences and the modifications alternatively:

  num1, modif1, num2, modif2, ...

=head2 modifToString($modif, [$len])

In order to display modification strings/vectors conveniently, we provide
a unique function modifToString that accepts all three formats and display the
modifications in $modif as a string using an appropriate style. If the parameter
$len (peptide length) is also given, then modifToString complements the length
if the returned string if necessary (MS/MS only).

=cut
sub modifToString
{
  my ($modif, $len) = @_;

  if (ref($modif) eq 'ARRAY'){
    if ((length($modif->[0]) > 0) && ($modif->[0] eq int($modif->[0]))){
      # First element is an integer => list of modifs for PMF
      my $string;
      for (my $i = 0; $i < @$modif; $i+=2){
	$string .= ', ' if (length($string) > 0);
	$string .= "$modif->[$i]x($modif->[$i+1])";
      }
      return $string;
    }
    else{
      # Localized modifs for MS/MS
      my @extra;
      if (defined($len)){
	croak("Modification vector too long") if (@$modif > $len+2);
	for (my $i = 0; $i < $len+2-@$modif; $i++){
	  push(@extra, '');
	}
      }
      return join(':', @$modif, @extra);
    }
  }
  else{
    # String for localized modifs (MS/MS)
    my $extra;
    if (defined($len)){
      my $nModif = 0;
      foreach (split(//, $modif)){
	$nModif++ if ($_ eq ':');
      }
      croak("The string of modifications does not have the correct length") if ($nModif > $len+1);
      $extra = ':'x($len+1-$nModif);
    }
    return $modif.$extra;
  }

} # modifToString


=head2 getPeptideMass(%h)

This function computes the (uncharged) mass of a peptide. The parameters are
passed as a reference to a hash to permit named parameters. The named parameters
are:

=over 4

=item pept

The peptide sequence. If it contains B, Z or X then getPeptideMass
returns -1.

=item modif

A reference to a vector containing the names of the modifications of the peptide.
If modif is not specified, the peptide is assumed unmodified. Empty names or
undefined names are considered as no modification.

=item termGain

Mass delta to add to the amino acid masses in case the usual plus water
rule does not apply, e.g. when using trypsin to introduce two 18O molecules
at the C-terminus.

=back

Example:

  my $peptide = 'QCTIPADFK';
  my @modif = ('Cys_CAM');
  print "$peptide mass is ", getPeptideMass(pept=>$peptide, modif=>\@modif), "\n";

=cut
sub getPeptideMass
{
  my (%h) = @_;
  my ($pept, $modif, $termGain) = ($h{pept}, $h{modif}, $h{termGain});
  croak("No peptide given in getPeptideMass") unless (defined($pept));

#  if ((index($pept, 'B') == -1) && (index($pept, 'Z') == -1) && (index($pept, 'X') == -1)){
  my %hEls;
  unless ($pept=~/InSilicoSpectro::InSilico::AASequence::qrValidAASeq/){
    if (defined($modif)){
      foreach (@$modif){
	$hEls{"mod_$_"}++ if ($_);
      }
    }
    foreach (split(//, $pept)){
      $hEls{"aa_$_"}++;
    }
    my $m = $termGain || $nTerm+$cTerm;
    foreach (keys %hEls){
      $m+=$hEls{$_}*getMass($_);
    }
    return $m;
  }
  else{
    # No defined mass
    warn "no mass for peptide [$pept]";
    return -1.0;
  }

} # getPeptideMass


=head2 getCorrectCharge($mTheo, $mExp, $delta, $maxCharge)

Returns the appropriate charge and theoretical mass over charge ratio (m/z)
for a given experimental m/z ratio and theoretical mass (charge not known).
The result is a vector (charge, m/z) and charges between 1 and C<$maxCharge>
are tested.

=over 4

=item $mTheo

Theoretical mass.

=item $mExp

Experimental m/z ratio.

=item $delta

Mass tolerance for comparing C<$mTheo> and C<$mExp> multiplied by the charge.

=item $maxCharge

Maximum charge to test for (minimum is 1).

=back

=cut
sub getCorrectCharge
{
  my ($mTheo, $mExp, $delta, $maxCharge) = @_;

  # Mass tolerance in Da
  $delta = $delta || 5;

  # Maximum charge
  $maxCharge = $maxCharge || 5;

  for (my $z = 1; $z <= $maxCharge; $z++){
    my $theoMoz = ($mTheo+$z*getMass('el_H+'))/$z;
    return ($z, $theoMoz) if (abs($theoMoz-$mExp) < $delta);
  }
  return (0,0);

} # getCorrectCharge


=head2 digestByRegExp(%h)

Generic digestion function where the enzyme is specified as a Perl regular
expression or a  InSilicoSpectro::InSilico::CleavEnzyme object. The maximum number of missed
cleavages per peptide can be set
arbitrarily and the result of the digestion is either (1) a data structure
that lists all the peptides with their masses, modifications, and start/stop
positions; or (2) a vector of InSilicoSpectro::InSilico::Peptide objects. The choice
depends on the type of the parameter protein, see hereafter. A mass window can
be specified.

The named parameters are:

=over 4

=item protein

The protein sequence. This sequence can be provided as a string or as an object
of class InSilicoSpectro::InSilico::AASequence. In the latter case, if no modif parameter
is given, then the modifications are taken from the AASequence object, otherwise
the parameter modif overrides the modifications stored in the object.

If protein is given as an object then the result of the digestion will be a vector
of InSilicoSpectro::InSilico::Peptide objects instead of the data structure.

=item modif

The parameter giving the localized modifications. If this parameter is not provided,
then the protein is assumed to have no localized modification. Localized variable
modifications are possible, see function variablePeptide. In case there are localized
variable modifications, all the combinations of modifications will be put in the final
result, i.e. the peptide is present several times with different modification strings.

Localized modifications are specified according to the two possible format explained
above.

=item fixedModif

A reference to a vector of fixed modification names. The
rules for identifying possible amino acids where modifications
occur are read from the configuration file.
All possible modification sites for all fixed modifications are
computed and these sites are combined with the fixed modifications
given by the parameter modif.

Fixed modification always have the priority over variable
modifications and it is not allowed to have two fixed modifications
at the same location.

=item varModif

A reference to a vector of variable modification names. If this parameter
is provided then each generated peptide will be tested for possible
variable modifications and all the combinations will be put in the final
result, i.e. the peptide is present several times with different modification
strings.

=item pmf

If this parameter is set to any value, then the exact modification location
in the result is replaced by the format for PMF, see above.

=item nmc

Maximum number of missed cleavages, default 0.

=item minMass

Minimum peptide mass, default 500 Da.

=item maxMass

Maximum peptide mass, default 999999 Da.

=item enzyme

The enzyme can be specified either by a regular expression or by a CleavEnzyme
object. If this parameter is not provided then the digestion is performed for
trypsin according to the regular expression

  (?<=[KR])(?=[^P])

Regular expressions used for specifying an enzyme can be given as strings or
precompiled regular expression such as

  $dibasicRegex = qr/(?<=[KR])(?=[KR])/,

which is exported by this module.

When you specify the enzyme by a CleavEnzyme object, the regular expression is
read from the object.

=item CTermGain, NTermGain

In case the enzyme does not add H at N-termini and OH at C-termini, you can
define new formulas for what is added.

When the enzyme comes as a CleavEnzyme object, these values are read from the
enzyme object directly.

=item CTermModif, NTermModif

In case the enzyme does introduce a modification at peptide C-/N-termini, you can
provide the name of the modification to apply.

When the enzyme comes as a CleavEnzyme object, these values are read from the
enzyme object directly.

=item methionine

If methionine is set to any value then, in case the first protein amino acid
is a methionine, supplementary peptides with initial methionine removed are
generated. This may be useful when processing RNA-translated sequences.

=item addProton

This parameter, if set to any value, tells the function to add the mass
of one proton to each peptide mass. This is useful for PMF as it allows
direct comparison of theoretical (charged) masses with experimental
masses.

=item duplicate

When set to any value, and the protein is given as a AASequence object, this
parameter tells the function not to try to save memory when creating the Peptide
object.

=back

The result of the digestion is returned either as a vector of InSilicoSpectro::InSilico::Peptide
objects or as a data structure which is a vector of six references:

  result[0] -> vector of peptide sequences
  result[1] -> vector of start positions in the original protein string
  result[2] -> vector of end positions in the original protein string
  result[3] -> vector of number of missed cleavages
  result[4] -> vector of peptide masses
  result[5] -> vector of modification descriptions

Variables $digestIndexPept=0, $digestIndexStart=1, $digestIndexEnd=2, $digestIndexNmc=3,
$digestIndexMass=4, and $digestIndexModif=5 are exported for convenience.

Example:

  my $protein = 'MCTMACTKGIPRKQWWEMMKPCKADFCV';
  my $modif =   '::Cys_CAM::Oxidation::::::::::::::Oxidation:::::::::::';
  my @result = digestByRegExp(protein=>$protein, modif=>$modif, methionine=>1, nmc=>2);
  print "$protein\n$modif\n";
  for (my $i = 0; $i < @{$result[0]}; $i++){
    print "$result[$digestIndexPept][$i]\t$result[$digestIndexStart][$i]\t",
          "$result[$digestIndexEnd][$i]\t$result[$digestIndexNmc][$i]\t",
          "$result[$digestIndexMass][$i]\t", modifToString($result[$digestIndexModif][$i]), "\n";
  }

More examples in InSilicoSpectro/InSilico/test/testCalcDigest.pl and InSilicoSpectro/InSilico/test/testCalcDigestOOP.pl

=cut


sub finalizeDigestion
{
  my ($peptides, $starts, $ends, $nmc, $modif, $l, $minMass, $maxMass, $results, $addProton, $fixedModif, $varModif, $pmf, $NTermGain, $CTermGain, $NTermModif, $CTermModif, $initMet) = @_;

  # Prepares modifications
  my @modif;
  if (!defined($modif)){
    # Creates an empty vector
    for (my $i = 0; $i < $l+2; $i++){
      push(@modif, '');
    }
  }
  else{
    if ((my $ref = ref($modif)) eq 'ARRAY'){
      # The modifs are given as a vector directly
      @modif = @$modif;
      croak("Invalid length for vector @$modif [".join(',',@modif)."]") if (@modif > $l+2);
      if (@modif < $l+2){
	# The last empty modifs were trimmed
	my $nModif = $l+2-@modif;
	for (my $i = 0; $i < $nModif; $i++){
	  push(@modif, '');
	}
      }
    }
    elsif (!$ref){
      # Scalar, assume string
      my $nModif = 0;
      foreach (split(//, $modif)){
	$nModif++ if ($_ eq ':');
      }
      croak("The string of modifications does not have the correct length") if ($nModif != $l+1);
      @modif = split(/:/, $modif);
      if (@modif < $l+2){
	# The last empty modifs were trimmed
	$nModif = $l+2-@modif;
	for (my $i = 0; $i < $nModif; $i++){
	  push(@modif, '');
	}
      }
    }
    else{
      croak("Unknown format for specifying modifications [$modif]");
    }
  }

  # In case of special terminal gains (not +H2O)
  my $NTermGainMass = (massFromComposition($NTermGain))[getMassType()];
  my $CTermGainMass = (massFromComposition($CTermGain))[getMassType()];

  # For each peptide creates the appropriate modif string and computes the mass
  for (my $i = 0; $i < @$peptides; $i++){
    my @peptModif;
    my $len = length($peptides->[$i]);
    if ($starts->[$i] == 0){
      # N-term peptide
      @peptModif = @modif[0..$len];
      if ($ends->[$i]+1 == $l){
	# Also C-term, includes the original C-term modif
	push(@peptModif, $modif[-1]);
      }
      else{
	# N-term only, includes an empty C-term modif
	push(@peptModif, '');
      }
    }
    else{
      # This peptide is not N-term, includes an empty N-term modif
      @peptModif = ('', @modif[$starts->[$i]+1..$starts->[$i]+$len]);
      if ($ends->[$i]+1 == $l){
	# C-term
	push(@peptModif, $modif[-1]);
      }
      else{
	# Not C-term, includes an empty modif
	push(@peptModif, '');
      }
    }

    # N-/C-term gains/modifs
    my $termGainMass = 0;
    if (($starts->[$i] == 0) || ($initMet && ($starts->[$i] == 1)) || ($nmc->[$i] == -3) || ($nmc->[$i] == -2)){
      # N-term peptide
      $termGainMass += $nTerm;
    }
    else{
      # Cleaved peptide
      $termGainMass += $NTermGainMass || $nTerm;
      $peptModif[0] = $NTermModif if (length($NTermModif) > 0);
    }
    if (($ends->[$i] == $l-1) || ($nmc->[$i] == -3) || ($nmc->[$i] == -1)){
      # C-term peptide
      $termGainMass += $cTerm;
    }
    else{
      $termGainMass += $CTermGainMass || $cTerm;
      $peptModif[-1] = $CTermModif if (length($CTermModif) > 0);
    }

    my @modifList = variablePeptide(pept=>$peptides->[$i], modif=>\@peptModif, fixedModif=>$fixedModif, varModif=>$varModif, pmf=>$pmf);
    for (my $j = 0; $j < @modifList; $j++){
      # Computes the peptide mass
      my ($peptMass, $modifDescr);
      $modifDescr = $modifList[$j];
      if (defined($pmf)){
	$peptMass = getPeptideMass(pept=>$peptides->[$i], termGain=>$termGainMass);
	$peptMass += $modifList[++$j];
      }
      else{
	$peptMass = getPeptideMass(pept=>$peptides->[$i], modif=>$modifList[$j], termGain=>$termGainMass);
      }
      $peptMass += getMass('el_H+') if (defined($addProton));

      # Stores peptides
      if (($peptMass <= $maxMass) && ($peptMass >= $minMass)){
	push(@{$results->[$digestIndexPept]}, $peptides->[$i]);
	push(@{$results->[$digestIndexStart]}, $starts->[$i]);
	push(@{$results->[$digestIndexEnd]}, $ends->[$i]);
	push(@{$results->[$digestIndexNmc]}, $nmc->[$i]);
	push(@{$results->[$digestIndexMass]}, $peptMass);
	push(@{$results->[$digestIndexModif]}, $modifDescr);
      }
    }
  }

} # finalizeDigestion


sub digestByRegExp
{
  # Digests by an enzyme given as a regular expression, default is trypsin
  my (%h) = @_;
  my ($protein, $modif, $nmc, $minMass, $maxMass, $methionine, $enzyme, $addProton, $fixedModif, $varModif, $pmf, $duplicate, $NTermGain, $CTermGain, $NTermModif, $CTermModif) = ($h{protein}, $h{modif}, $h{nmc}, $h{minMass}, $h{maxMass}, $h{methionine}, $h{enzyme}, $h{addProton}, $h{fixedModif}, $h{varModif}, $h{pmf}, $h{duplicate}, $h{NTermGain}, $h{CTermGain}, $h{NTermModif}, $h{CTermModif});

  # Protein as a string or an object
  my ($proteinSeq, $proteinIsAnObject);
  if (ref($protein) && $protein->isa('InSilicoSpectro::InSilico::AASequence')){
    # Gets the sequence
    $proteinSeq = $protein->sequence();
    if (!defined($modif)){
      $modif = $protein->modif();
    }
    $proteinIsAnObject = 1;
  }
  else{
    $proteinSeq = $protein;
  }

  # Variables preparation
  my $l = length($proteinSeq);
  $nmc = 0 if (!defined($nmc));
  $minMass = 500 if (!defined($minMass));
  $maxMass = 999999 if (!defined($maxMass));

  # Generates the peptides with 0 missed cleavage
  my (@peptides, $enzymeIsAnObject);
  if (!defined($enzyme)){
    # Uses default trypsin regexp
    @peptides = split(/$trypsinRegex/, $proteinSeq);
  }
  else{
    my $ref = ref($enzyme);
    if (!$ref || ($ref eq 'Regexp')){
      # $enzyme is a string defining a regexp or a compiled regexp
      @peptides = split(/$enzyme/, $proteinSeq);
    }
    elsif ($enzyme->isa('InSilicoSpectro::InSilico::CleavEnzyme')){
      my $regexp = $enzyme->regexp();
      @peptides = split(/$regexp/, $proteinSeq);
      $NTermGain = $enzyme->NTermGain();
      $CTermGain = $enzyme->CTermGain();
      $NTermModif = $enzyme->NTermModif();
      $CTermModif = $enzyme->CTermModif();
      $enzymeIsAnObject = 1;
    }
    else{
      croak("Unknown enzyme object [$ref]");
    }
  }
  my (@nmc, @starts, @ends);
  push(@starts, 0);
  push(@nmc, 0);
  for (my $i = 0; $i < @peptides-1; $i++){
    push(@ends, $starts[$i]+length($peptides[$i])-1);
    push(@starts, $ends[$i]+1);
    push(@nmc, 0);
  }
  push(@ends, $l-1);

  # Generates the peptides with >= 1 missed cleavages
  my ($numPept, $missed);
  $numPept = @peptides;
  for (my $i = 0; $i < $numPept-1; $i++){
    $missed = $peptides[$i];
    for (my $j = 1; ($j <= $nmc) && ($i+$j < $numPept); $j++){
      push(@starts, $starts[$i]);
      push(@ends, $ends[$i+$j]);
      push(@nmc, $j);
      $missed .= $peptides[$i+$j];
      push(@peptides, $missed);
    }
  }

  # Includes peptides with initial methionine suppressed in case of translated RNA/DNA.
  if (defined($methionine) && (substr($proteinSeq, 0, 1) eq 'M')){
    push(@starts, 1);
    push(@ends, $ends[0]);
    push(@nmc, 0);
    push(@peptides, substr($peptides[0], 1));
    $missed = $peptides[-1];
    for (my $j = 1; ($j <= $nmc) && ($j < $numPept); $j++){
      push(@starts, 1);
      push(@ends, $ends[$j]);
      push(@nmc, $j);
      $missed .= $peptides[$j];
      push(@peptides, $missed);
    }
  }

  # Decomposes the modification string, computes the masses and stores the results
  my @results;
  my $initMet = defined($methionine) && (substr($proteinSeq, 0, 1) eq 'M');
  finalizeDigestion(\@peptides, \@starts, \@ends, \@nmc, $modif, $l, $minMass, $maxMass, \@results, $addProton, $fixedModif, $varModif, $pmf, $NTermGain, $CTermGain, $NTermModif, $CTermModif, $initMet);
  if ($proteinIsAnObject){
    # Creates fully-featured peptide objects and push then into @objectResults
    my @objectResults;
    for (my $i = 0; $i < @{$results[0]}; $i++){
      my $peptObj = new InSilicoSpectro::InSilico::Peptide(parentProtein=>$protein, start=>$results[$digestIndexStart][$i], end=>$results[$digestIndexEnd][$i], nmc=>$results[$digestIndexNmc][$i], enzymatic=>'full');
      $peptObj->sequence($proteinSeq) if ($duplicate);
      $peptObj->modif($results[$digestIndexModif][$i]);
      $peptObj->addProton(1) if (defined($addProton));
      $peptObj->enzyme($enzyme) if ($enzymeIsAnObject);
      $peptObj->nTerm(($peptObj->start() == 0) || ($initMet && ($peptObj->start() == 1)));
      $peptObj->cTerm($peptObj->end() == $l-1);
      $peptObj->aaBefore(substr($proteinSeq, $peptObj->start()-1, 1)) if ($peptObj->start() > 0);
      $peptObj->aaAfter(substr($proteinSeq, $peptObj->end()+1, 1)) if ($peptObj->end() < $l-1);
      push(@objectResults, $peptObj);
    }
    return @objectResults;
  }
  else{
    return @results;
  }

} # digestByRegExp


=head2 nonSpecificDigestion(%h)

Generic digestion function where either no enzyme is used or half enzymatic
peptides are computed. The result of the digestion is either (1) a data structure
that lists all the peptides with their masses, modifications, and start/stop
positions (see digestByRegExp above for a description); or (2) a vector of
InSilicoSpectro::InSilico::Peptide objects. The choice depends on the type of the parameter
protein, see hereafter.

The number of missed cleavage reported in the data structure is used to distinguish
between the three possible cases: -3 for no enzyme peptide, -1 for half-tryptic
peptides at their N-term end, and -2 for half-tryptic peptides at their C-term
end.

The named parameters are:

=over 4

=item protein

See function digestByRegExp.

=item modif

See function digestByRegExp.

=item fixedModif

See function digestByRegExp.

=item varModif

See function digestByRegExp.

=item pmf

See function digestByRegExp.

=item minMass

Minimum peptide mass.

=item maxMass

Maximum peptide mass.

=item minLen

Minimum peptide length in amino acids.

=item maxLen

Maximum peptide length in amino acids.

=item enzyme

If this parameter is not provided then the digestion is performed without
any enzyme, i.e. the protein is cut after every amino acid and only the
mass window and the peptide length window are applied as criteria to
filter possible peptide.

If an enzyme regular expression or a CleavEnzyme object (see digestByRegExp
above) is provided, then half-enzymatic peptides are generated, i.e.
peptides with either the N- or the C-term end that corresponds to a cleavage
site. The mass window and peptide length window also apply in this case.

=item CTermGain, NTermGain

See function digestByRegExp.

=item CTermModif, NTermModif

See function digestByRegExp.

=item addProton

See function digestByRegExp.

=item duplicate

See function digestByRegExp.

=back

Example:

  my $protein = 'MCTMACTKGIPRKQWWEMMKPCKADFCV';
  my $modif =   '::Cys_CAM::Oxidation::::::::::::::Oxidation:::::::::::';
  my @result = nonSpecificDigestion(protein=>$protein, modif=>$modif);
  print "$protein\n$modif\n";
  for (my $i = 0; $i < @{$result[0]}; $i++){
    print "$result[$digestIndexPept][$i]\t$result[$digestIndexStart][$i]\t",
          "$result[$digestIndexEnd][$i]\t$result[$digestIndexNmc][$i]\t",
          "$result[$digestIndexMass][$i]\t", modifToString($result[$digestIndexModif][$i]), "\n";
  }

More examples in InSilicoSpectro/InSilico/test/testCalcDigest.pl and InSilicoSpectro/InSilico/test/testCalcDigestOOP.pl

=cut
sub nonSpecificDigestion
{
  # No enzyme digestion or half-enzymatic digestion
  my (%h) = @_;
  my ($protein, $modif, $minMass, $maxMass, $minLen, $maxLen, $enzyme, $addProton, $fixedModif, $varModif, $pmf, $duplicate, $NTermGain, $CTermGain, $NTermModif, $CTermModif) = ($h{protein}, $h{modif}, $h{minMass}, $h{maxMass}, $h{minLen}, $h{maxLen}, $h{enzyme}, $h{addProton}, $h{fixedModif}, $h{varModif}, $h{pmf}, $h{duplicate}, $h{NTermGain}, $h{CTermGain}, $h{NTermModif}, $h{CTermModif});

  # Protein as a string or an object
  my ($proteinSeq, $proteinIsAnObject);
  if (ref($protein) && $protein->isa('InSilicoSpectro::InSilico::AASequence')){
    # Gets the sequence
    $proteinSeq = $protein->sequence();
    if (!defined($modif)){
      $modif = $protein->modif();
    }
    $proteinIsAnObject = 1;
  }
  else{
    $proteinSeq = $protein;
  }

  # Variables preparation
  my $l = length($proteinSeq);
  $minMass = 500 if (!defined($minMass));
  $maxMass = 3500 if (!defined($maxMass));
  $minLen = 3 if (!defined($minLen) || ($minLen < 1));
  $maxLen = 40 if (!defined($maxLen) || ($maxLen > 100));

  my (@peptides, @starts, @ends, @nmc, $enzymeIsAnObject);
  if (defined($enzyme)){
    # Half-enzymatic digestion

    my %already; # Duplicate peptides are possible

    # N-term peptides
    for (my $j = $minLen; ($j <= $maxLen) && ($j <= $l); $j++){
      my $peptide = substr($proteinSeq, 0, $j);
      if (!defined($already{$peptide})){
	push(@starts, 0);
	push(@ends, $j-1);
	push(@peptides, $peptide);
	push(@nmc, -1);
	$already{$peptide} = 1;
      }
    }

    # Inner peptides
    my @p;
    my $ref = ref($enzyme);
    if (!$ref || ($ref eq 'Regexp')){
      # $enzyme is a string defining a regexp or a compiled regexp
      @p = split(/$enzyme/, $proteinSeq);
    }
    elsif ($enzyme->isa('InSilicoSpectro::InSilico::CleavEnzyme')){
      my $regexp = $enzyme->regexp();
      @p = split(/$regexp/, $proteinSeq);
      $NTermGain = $enzyme->NTermGain();
      $CTermGain = $enzyme->CTermGain();
      $NTermModif = $enzyme->NTermModif();
      $CTermModif = $enzyme->CTermModif();
      $enzymeIsAnObject;
    }
    else{
      croak("Unknown enzyme object [$ref]");
    }

    my $site = 0;
    for (my $i = 0; $i < @p-1; $i++){
      $site += length($p[$i]);

      # On the left of the cleavage site
      for (my $j = $site-$minLen; ($j >= 0) && ($j >= $site-$maxLen); $j--){
	my $peptide = substr($proteinSeq, $j, $site-$j);
	if (!defined($already{$peptide})){
	  push(@starts, $j);
	  push(@ends, $site-1);
	  push(@peptides, $peptide);
	  push(@nmc, -2);
	  $already{$peptide} = 1;
	}
      }
	
      # On the right of the cleavage site
      for (my $j = $site+$minLen; ($j <= $l) && ($j <= $site+$maxLen); $j++){
	my $peptide = substr($proteinSeq, $site, $j-$site);
	if (!defined($already{$peptide})){
	  push(@starts, $site);
	  push(@ends, $j-1);
	  push(@peptides, $peptide);
	  push(@nmc, -1);
	  $already{$peptide} = 1;
	}
      }
    }

    # C-term peptides
    for (my $j = $l-$minLen; ($j >= 0) && ($j >= $l-$maxLen); $j--){
      my $peptide = substr($proteinSeq, $j, $l-$j);
      if (!defined($already{$peptide})){
	push(@starts, $j);
	push(@ends, $l-1);
	push(@peptides, $peptide);
	push(@nmc, -2);
	$already{$peptide} = 1;
      }
    }
  }
  else{
    # No-enzyme digestion

    for (my $i = 0; $i <= $l-$minLen; $i++){
      for (my $j = $minLen; ($i+$j <= $l) && ($j <= $maxLen); $j++){
	push(@starts, $i);
	push(@ends, $i+$j-1);
	push(@peptides, substr($proteinSeq, $i, $j));
	push(@nmc, -3);
      }
    }
  }

  # Decomposes the modification string, computes the masses and store the results
  my @results;
  finalizeDigestion(\@peptides, \@starts, \@ends, \@nmc, $modif, $l, $minMass, $maxMass, \@results, $addProton, $fixedModif, $varModif, $pmf, $NTermGain, $CTermGain, $NTermModif, $CTermModif, 0);
  if ($proteinIsAnObject){
    # Creates fully-featured peptide objects and push them into @objectResults
    my @objectResults;
    for (my $i = 0; $i < @{$results[0]}; $i++){
      my $peptObj = new InSilicoSpectro::InSilico::Peptide(parentProtein=>$protein, start=>$results[$digestIndexStart][$i], end=>$results[$digestIndexEnd][$i]);
      if ($results[$digestIndexNmc][$i] == -3){
	$peptObj->enzymatic('no');
      }
      elsif ($results[$digestIndexNmc][$i] == -1){
	$peptObj->enzymatic('half-N');
      }
      else{
	$peptObj->enzymatic('half-C');
      }
      $peptObj->sequence($proteinSeq) if ($duplicate);
      $peptObj->modif($results[$digestIndexModif][$i]);
      $peptObj->addProton(1) if (defined($addProton));
      $peptObj->enzyme($enzyme) if ($enzymeIsAnObject);
      $peptObj->nTerm($peptObj->start() == 0);
      $peptObj->cTerm($peptObj->end() == $l-1);
      $peptObj->aaBefore(substr($proteinSeq, $peptObj->start()-1, 1)) if ($peptObj->start() > 0);
      $peptObj->aaAfter(substr($proteinSeq, $peptObj->end()+1, 1)) if ($peptObj->end() < $l-1);
      push(@objectResults, $peptObj);
    }
    return @objectResults;
  }
  else{
    return @results;
  }

} # nonSpecificDigestion


=head2 matchPMF(%h)

This function compares an experimental PMF spectrum with a theoretical
PMF spectrum, i.e. the result of a digestion function, and associates
each theoretical mass with one experimental mass.

The named parameters are:

=over 4

=item digestResult

A reference to a vector containing the result of the protein digestion
as computed by either digestByRegExp or nonSpecificDigestion functions.

=item expSpectrum

The experimental spectrum is given either as a data structure or as an
object of class InSilicoSpectro::Spectra::ExpSpectrum.

The data structure is a vector of references to vectors corresponding
to experimental peaks in the experimental spectrum. The parameter expSpectrum
is a reference to the experimental spectrum. Namely, expSpectrum has
a structure like

  expSpectrum->[0] -> (mass, intensity, s/n, ...) for peak 1
  expSpectrum->[1] -> (mass, intensity, s/n, ...) for peak 2
  expSpectrum->[2] -> (mass, intensity, s/n, ...) for peak 3
  ...

By default, for matchPMF, it is assumed that the mass has index 0 and intensity has
index 1 in the peak vectors. The other data in these vectors are not used but they
can be retrieved after the spectrum match for computing statistics for instance.
If mass index is not 0 or intensity index is not 1, use the parameters massIndex
and intensityIndex.

In case expSpectrum is a InSilicoSpectro::Spectra::ExpSpectrum object, the experimental spectrum
as well as mass and intensity indices are retrieved from the object directly.

If the peptide mass fingerprinting spectrum has been acquired on an ESI instrument,
where peptides can be multiply charged, it is the user responsibility to replace
multiply charged peptides m/z values by their singly charged equivalent. The match
algorithm ignores peptide charges.

=item tol

Relative mass error tolerance; this parameter is optional. When not
specified, the closest experimental peak is returned for each
theoretical mass and any tolerance can be applied afterwards, i.e.
outside of the function matchPMF. When specified, the most intense
peak found with mass error satisfying

  relative error <= tol OR absolute error <= minTol

is returned; if no peak is found then the value in the returned
vector remains undefined.

=item minTol

Absolute mass error, default value 0.1 Da. This parameter is used
only in case tol parameter is specified, see above.

=item sorted

The experimental spectrum must sorted with respect to the mass for
matchPMFClosest to work. In case it is already sorted when the
function is called, sorted can be set to any value to avoid an
unnecessary sort operation.

=item massIndex

Mass index in the experimental peak vectors, default 0.

=item intensityIndex

Intensity index in the experimental peak vectors, default 1.

=back

The result of the matching is a vector of the same length as
digestResult that contains references to the closest peaks vector
in expSpectrum. The reference to the closest experimental peak
for the peptide described at index i in digestResult is found at
index i in the returned vector.

Examples in InSilicoSpectro/InSilico/test/testCalcPMFMatch.pl and InSilicoSpectro/InSilico/test/testCalcPMFMatchOOP.pl.

=cut
sub dichoSpectrumSearch
{
  my ($sorted, $left, $right, $theoMass, $massIndex) = @_;

  my $middle;
  while ($right >= $left){
    $middle = int(($right+$left)*0.5);
    if ($sorted->[$middle][$massIndex] >= $theoMass){
      $right = $middle-1;
    }
    if ($sorted->[$middle][$massIndex] <= $theoMass){
      $left = $middle+1;
    }
  }
  if ($left-$right == 2){
    # Found the exact mass
    return $sorted->[$middle];
  }
  elsif ($right == -1){
    # Search for a mass smaller than the smallest in expSpectrum, return the smallest
    return $sorted->[$massIndex];
  }
  elsif ($left == scalar(@$sorted)){
    # Search for a mass that is larger than the largest mass in expSpectrum, return the largest
    return $sorted->[-1];
  }
  else{
    # Normal case
    return ($sorted->[$left][$massIndex]-$theoMass < $theoMass-$sorted->[$right][$massIndex]) ? $sorted->[$left] : $sorted->[$right];
  }

} # dichoSpectrumSearch


sub dichoSpectrumMostIntSearch
{
  my ($sorted, $left, $right, $theoMass, $tol, $minTol, $greedy, $used, $massIndex, $intensityIndex) = @_;

  my $middle;
  while ($right >= $left){
    $middle = int(($right+$left)*0.5);
    if ($sorted->[$middle][$massIndex] >= $theoMass){
      $right = $middle-1;
    }
    if ($sorted->[$middle][$massIndex] <= $theoMass){
      $left = $middle+1;
    }
  }

  my ($expMass, $k);
  if ($left-$right == 2){
    # Found the exact mass
    $expMass = $sorted->[$middle][$massIndex];
    $k = $middle;
  }
  elsif ($right == -1){
    # Search for a mass smaller than the smallest in expSpectrum, return the smallest
    $expMass = $sorted->[0][$massIndex];
    $k = 0;
  }
  elsif ($left == scalar(@$sorted)){
    # Search for a mass that is larger than the largest mass in expSpectrum, return the largest
    $expMass = $sorted->[-1][$massIndex];
    $k = scalar(@$sorted)-1;
  }
  else{
    # Normal case
    if ($sorted->[$left][$massIndex]-$theoMass < $theoMass-$sorted->[$right][$massIndex]){
      $expMass = $sorted->[$left][$massIndex];
      $k = $left;
    }
    else{
      $expMass = $sorted->[$right][$massIndex];
      $k = $right;
    }
  }

  if ((abs($theoMass-$expMass)/($theoMass+$expMass)*2e+6 <= $tol) || (abs($theoMass-$expMass) <= $minTol)){
    # The closest mass is within the mass tolerance, start to search the most intense
    my $maxIntensity = -9999;
    my $iMax = -1;
    for (my $j = $k; ($j >= 0) && ((abs($theoMass-$sorted->[$j][$massIndex])/($theoMass+$sorted->[$j][$massIndex])*2e+6 <= $tol) || (abs($theoMass-$sorted->[$j][$massIndex]) <= $minTol)); $j--){
      if ((!$greedy || !$used->[$j]) && ($sorted->[$j][$intensityIndex] > $maxIntensity)){
	$maxIntensity = $sorted->[$j][$intensityIndex];
	$iMax = $j;
      }
    }
    for (my $j = $k+1; ($j < scalar(@$sorted)) && ((abs($theoMass-$sorted->[$j][$massIndex])/($theoMass+$sorted->[$j][$massIndex])*2e+6 <= $tol) || (abs($theoMass-$sorted->[$j][$massIndex]) <= $minTol)); $j++){
      if ((!$greedy || !$used->[$j]) && ($sorted->[$j][$intensityIndex] > $maxIntensity)){
	$maxIntensity = $sorted->[$j][$intensityIndex];
	$iMax = $j;
      }
    }

    if ($iMax != -1){
      $used->[$iMax] = 1 if ($greedy);
      return $sorted->[$iMax];
    }
  }

  return undef;

} # dichoSpectrumMostIntSearch


sub matchPMF
{
  my (%h) = @_;
  my ($digestResult, $spectrum, $sorted, $tol, $minTol, $massIndex, $intensityIndex) = ($h{digestResult}, $h{expSpectrum}, $h{sorted}, $h{tol}, $h{minTol}, $h{massIndex}, $h{intensityIndex});

  $minTol = $minTol || 0.1;
  $massIndex = $massIndex || 0;
  $intensityIndex = $intensityIndex || 1;

  # Determines digestResult type
  my $peptIsAnObject;
  if (ref($digestResult->[0]) && (ref($digestResult->[0]) ne 'ARRAY') && $digestResult->[0]->isa('InSilicoSpectro::InSilico::Peptide')){
    $peptIsAnObject = 1;
  }

  # Determines spectrum type
  my $expSpectrum;
  if (ref($spectrum) && (ref($spectrum) ne 'ARRAY') && $spectrum->isa('InSilicoSpectro::Spectra::ExpSpectrum')){
    $expSpectrum = $spectrum->spectrum();
    $massIndex = $spectrum->peakDescriptor()->getFieldIndex('mass');
    $intensityIndex = $spectrum->peakDescriptor()->getFieldIndex('intensity');
    if (!defined($intensityIndex)){
      $intensityIndex = $spectrum->peakDescriptor()->getFieldIndex('height');
    }
  }
  else{
    $expSpectrum = $spectrum;
  }

  # Prepares the experimental spectrum (sorts according to the first column that must be the mass)
  my @sorted = defined($sorted) ? @$expSpectrum : sort {$a->[$massIndex] <=> $b->[$massIndex]} @$expSpectrum;

  # Find the closest masses
  my @closest;
  my $n = $peptIsAnObject ? scalar(@$digestResult) : scalar(@{$digestResult->[$digestIndexMass]});
  for (my $i = 0; $i < $n; $i++){
    my $theoMass = $peptIsAnObject ? $digestResult->[$i]->getMass() : $digestResult->[$digestIndexMass][$i];
    $closest[$i] = defined($tol) ? dichoSpectrumMostIntSearch(\@sorted, 0, $#sorted, $theoMass, $tol, $minTol, undef, undef, $massIndex, $intensityIndex) : dichoSpectrumSearch(\@sorted, 0, $#sorted, $theoMass, $massIndex);
  }

  return @closest;

} # matchPMF


=head2 variablePeptide(%h)

Given a peptide sequence, fixed and localized variable modifications,
and lists of variable and fixed modifications, this function returns a list comprising
all possible modification combinations. Each amino acid can only receive one
modification at a time and if several are possible for a given amino acid they
will yield several distinct modification combinations. In case you need an amino
acid to be modified simultaneously by several modifications, you can define this
modifications combination as a new modification.

The peptide can given by a string, a InSilicoSpectro::InSilico::Peptide object or a
InSilicoSpectro::InSilico::AASequence object.

The parameters are:

=over 4

=item pept

The peptide.

=item modif

A reference to a vector (no string possible here) containing fixed and localized
variable modifications for the peptide. If this parameter is not
provided, then no such modifications are considered.

Fixed modification are always present whereas localized variable
modifications are associated with a specific amino acid but may
be present or not. Add '(*)' before a modification name to specify
a localized variable modification. It is even possible to give
several alternative variable modifications for the same amino
acid: add '(*)' before the name of the first one and add the
other modifications names separated by comas:

  (*)mod1,mod2,mod3

If the peptide is provided as a InSilicoSpectro::InSilico::Peptide object or a
InSilicoSpectro::InSilico::AASequence object and the parameter modif is not
given, then the localized modifications are taken from the object.

=item fixedModif

See function digestByRegExp.

=item varModif

See function digestByRegExp.

=item pmf

See function digestByRegExp. The total mass shift corresponding to a
modification combination follows it in the returned vector.

=back

Examples in InSilicoSpectro/InSilico/test/testCalcVarpept.pl and InSilicoSpectro/InSilico/test/testCalcVarpeptOOP.pl.

=cut
sub variablePeptide
{
  my (%h) = @_;
  my ($pept, $modif, $fixedModif, $varModif, $pmf) = ($h{pept}, $h{modif}, $h{fixedModif}, $h{varModif}, $h{pmf});
  croak("No peptide given in variablePeptide") unless (defined($pept));

  # Gets peptide sequence
  my $peptSeq;
  if (ref($pept)){
    if ($pept->isa('InSilicoSpectro::InSilico::Peptide') || $pept->isa('InSilicoSpectro::InSilico::AASequence')){
      $peptSeq = $pept->sequence();
      if (!defined($modif)){
	$modif = $pept->modif();
      }
    }
    else{
      croak("Illegal peptide object [$pept]");
    }
  }
  else{
    $peptSeq = $pept;
  }

  # Checks modif length
  my $len = length($peptSeq);
  my @modif = defined($modif) ? @$modif : ();
  croak("The vector of modifications is too long") if (scalar(@modif) > $len+2);

  # Part 1: Lists modifications ---------------------------------

  # Locates fixed modifications
  my @pept = split(//, $peptSeq);
  my (@fixedModif, @varModif);
  for (my $i = 0; $i < $len+2; $i++){
    $varModif[$i] = [];
    $fixedModif[$i] = "";
  }
  foreach my $name (@{$fixedModif}){
    # Checks modification
    if (!defined($elMass{"mod_$name"})){
      croak(__FILE__."(".__LINE__.") Unknown fixed modification in variablePeptide: [$name]");
    }
    
    # locates and adds
    my $mr=InSilicoSpectro::InSilico::ModRes::getFromDico($name);
    my @modpos=$mr->seq2pos($peptSeq);
    
    if ($mr->nTerm){
      # N-term modification
      if (@modpos){
	if (length($fixedModif[0]) > 0){
	  if ($fixedModif[0] ne $name){
	    croak("Multiple fixed modification [$name] at N-term in variablePeptide");
	  }
	}
	else{
	  # Sets the modification
	  $fixedModif[0] = $name;
	}
      }
    }
    elsif ($mr->cTerm){
      # C-term modification
      if (@modpos){
	if (length($fixedModif[$len+1]) > 0){
	  if ($fixedModif[$len+1] ne $name){
	    croak("Multiple fixed modification [$name] at C-term in variablePeptide");
	  }
	}
	else{
	  # Sets the modification
	  $fixedModif[$len+1] = $name;
	}
      }
    }else{      # Non terminal modification
      foreach my $i (@modpos){
	if (length($fixedModif[$i+1]) > 0){
	  if ($fixedModif[$i+1] ne $name){
	    croak("Multiple fixed modification [$name]+[$fixedModif[$i+1]] at pos [$i] in variablePeptide");
	  }
	}
	else{
	  # Sets the modification
	  $fixedModif[$i+1] = $name;
	}
      }
    }
  }
    
  # Separates fixed from localized variable modifications as given by the parameter modif
    for (my $i = 0; $i < $len+2; $i++){
    if (length($modif[$i]) > 0){
      if (index($modif[$i], '(*)') == 0){
	# Adds variable modif by checking that they are all different
	my @list = split(/,/, substr($modif[$i], 3));
	for (my $j = 0; $j < @list; $j++){
	  for (my $k = 0; $k < $j; $k++){
	    if ($list[$k] eq $list[$j]){
	      croak("Two identical localized variable modifications for the same amino acid [$list[$k]] = [$list[$j]]");
	    }
	  }
	  if (defined($elMass{"mod_$list[$j]"})){
	    push(@{$varModif[$i]}, $list[$j]);
	  }
	  else{
	    croak(__FILE__."(".__LINE__.") Unknown localized modification in variablePeptide: [$list[$j]]");
	  }
	}
      }
      else{
	# Adds fixed modif
	if (defined($elMass{"mod_$modif[$i]"})){
	  if (length($fixedModif[$i]) > 0){
	    if ($fixedModif[$i] ne $modif[$i]){
	      croak("Multiple fixed modification [$modif[$i]]+[$fixedModif[$i]] at pos [",$i-1,"] in variablePeptide");
	    }
	  }
	  else{
	    $fixedModif[$i] = $modif[$i];
	  }
	}
	else{
	  croak(__FILE__."(".__LINE__.") Unknown modification in variablePeptide: [$modif[$i]]");
	}
      }
    }
  }

  # Locates variable modifications
  foreach my $name (@{$varModif}){
    my $mr=InSilicoSpectro::InSilico::ModRes::getFromDico($name);
    my @modpos=$mr->seq2pos($peptSeq);
    # Checks modification
    if (!defined($elMass{"mod_$name"})){
      croak(__FILE__."(".__LINE__.") Unknown variable modification in variablePeptide: [$name]");
    }

    # locates and adds
    if ($mr->nTerm){
      # N-term modification
      if (@modpos){
	# Checks it is new for this position
	my $new = 1;
	for (my $j = 0; $j < @{$varModif[0]}; $j++){
	  if ($name eq $varModif[0][$j]){
	    $new = 0;
	    last;
	  }
	}

	# Adds
	if ($new){
	  push(@{$varModif[0]}, $name);
	}
      }
    }
    elsif ($mr->cTerm){
      # C-term modification
      if (@modpos){
	# Checks it is new for this position
	my $new = 1;
	for (my $j = 0; $j < @{$varModif[$len+1]}; $j++){
	  if ($name eq $varModif[$len+1][$j]){
	    $new = 0;
	    last;
	  }
	}

	# Adds
	if ($new){
	  push(@{$varModif[$len+1]}, $name);
	}
      }
    }else
      {
      # Non terminal modification
      foreach my $i(@modpos){
	# Checks it is new for this position
	my $new = 1;
	for (my $j = 0; $j < @{$varModif[$i+1]}; $j++){
	  if ($name eq $varModif[$i+1][$j]){
	    $new = 0;
	    last;
	  }
	}
	
	# Adds
	if ($new){
	  push(@{$varModif[$i+1]}, $name);
	}
      }
    }

  }

#  print STDERR "$peptSeq\n",join(':',@modif),"$modif\n\nFound modifications:\n";
#  print STDERR "fixed:    ",join(':',@fixedModif),"\n";
#  print STDERR "variable: ";
#  for (my $i = 0; $i < @varModif; $i++){
#    print STDERR join(',',@{$varModif[$i]});
#    print STDERR  ":" if ($i < @varModif-1);
#  }
#  print STDERR "\n\n";

  # Part 2: Generates all possible modification combinations --------------------

  # We compute all the (position dependent) modification combinations (MS/MS)
  my @modifList;

  # Prepares a list of positions and number of variable modifications
  my (@location, @avail, $nVarModif);
  for (my $i = 0; $i < @varModif; $i++){
    if (@{$varModif[$i]} > 0){
      push(@location, $i);
      push(@avail, scalar(@{$varModif[$i]}));
      $nVarModif++;
    }
  }

  # No variable modification
  if (defined($pmf)){
    my $massShift = 0;
    my %fixedCount;
    foreach (@fixedModif){
      $fixedCount{$_}++ if (length($_) > 0);
    }
    my @pmfModif;
    foreach (sort(keys(%fixedCount))){
      push(@pmfModif, $fixedCount{$_}, $_);
      $massShift += $fixedCount{$_}*getMass("mod_$_");	
    }
    push(@modifList, [@pmfModif], $massShift);
  }
  else{
    push(@modifList, [@fixedModif]);
  }

  # Generates all the combinations of variable modifications
  my %pmfList;
  if ($nVarModif > 0){
    my $comb = 0;
    my @nMod = split(//, '0' x @avail);
    $nMod[0] = 1;
    while (1){
      # Computes the current combination
      my @curMod = @fixedModif;
      for (my $i = 0; $i < @nMod; $i++){
	if ($nMod[$i] > 0){
	  # There is a modification at this position
	  $curMod[$location[$i]] = $varModif[$location[$i]][$nMod[$i]-1];
	}
      }

      # Stores it
      if (defined($pmf)){
	my $massShift = 0;
	my $string = "";
	my %count;
	foreach (@curMod){
	  $count{$_}++ if (length($_) > 0);
	}
	my @pmfModif;
	foreach (sort(keys(%count))){
	  push(@pmfModif, $count{$_}, $_);
	  $string .= ', ' if (length($string) > 0);
	  $string .= "$count{$_}x($_)";
	  $massShift += $count{$_}*getMass("mod_$_");	
	}
	$pmfList{$string} = [[@pmfModif], $massShift]; # Uses a hash to avoid repetitions
      }
      else{
	push(@modifList, [@curMod]);
      }

      # Gets the next combination
      my $i;
      for ($i = 0; ($i < @avail) && ($nMod[$i] == $avail[$i]); $i++){}
      last if ($i == @avail);
      $nMod[$i]++;
      for (my $j = 0; $j < $i; $j++){
	$nMod[$j] = 0;
      }
      $comb++;
    }
  }

  if (defined($pmf)){
    foreach (sort(keys(%pmfList))){
      push(@modifList, @{$pmfList{$_}});
    }
  }
  return @modifList;

} # variablePeptide


=head2 locateModif($peptSeq, $modif, $fixedModif, $varModif, $modifVect)

This function is used to generate a vector of modifications on the basis of localized
fixed and variable modifications as well as a list of fixed and variable modifications,
which are located by using their rule. The result is returned in $modifVect.

The parameters are:

=over 4

=item $peptSeq

The peptide sequence.

=item $modif

The localized modifications, see function variablePeptide.

=item $fixedModif

A reference to a vector containing the name of fixed modifications.

=item $varModif

A reference to a vector containing the name of variable modifications.

=item $modifVect

A reference to a vector that will contain the result.

=back

Example: see InSilicoSpectro/InSilico/test/testCalcDigest.pl and the mini
web site.

=cut
sub locateModif
{
  my ($peptSeq, $modif, $fixedModif, $varModif, $modifVect) = @_;
  my $len = length($peptSeq);
  my @modif = defined($modif) ? @$modif : ();
  croak("The vector of modifications is too long") if (scalar(@modif) > $len+2);

  # Part 1: Lists modifications ---------------------------------

  # Locates fixed modifications
  my @pept = split(//, $peptSeq);
  my (@fixedModif, @varModif);
  for (my $i = 0; $i < $len+2; $i++){
    $varModif[$i] = [];
    $fixedModif[$i] = "";
  }
  foreach my $name (@{$fixedModif}){
    # Checks modification
    if (!defined($elMass{"mod_$name"})){
      print STDERR "".(join "\n", %elMass)."\n";
      croak(__FILE__."(".__LINE__.") Unknown modification in variablePeptide: [$name]");
    }

    # locates and adds
    my $mr=InSilicoSpectro::InSilico::ModRes::getFromDico($name);
    my @modpos=$mr->seq2pos($peptSeq);
    if ($mr->nTerm){
      # N-term modification
      if (@modpos){
	if (length($fixedModif[0]) > 0){
	  if ($fixedModif[0] ne $name){
	    croak("Multiple fixed modification [$name] at N-term in variablePeptide");
	  }
	}
	else{
	  # Sets the modification
	  $fixedModif[0] = $name;
	}
      }
    }
    elsif ($mr->cTerm){
      # C-term modification
      if (@modpos){
	if (length($fixedModif[$len+1]) > 0){
	  if ($fixedModif[$len+1] ne $name){
	    croak("Multiple fixed modification [$name] at C-term in variablePeptide");
	  }
	}
	else{
	  # Sets the modification
	  $fixedModif[$len+1] = $name;
	}
      }
    }
    else{
      # Non terminal modification
      foreach my $i (@modpos){
	if (length($fixedModif[$i+1]) > 0){
	  if ($fixedModif[$i+1] ne $name){
	    croak("Multiple fixed modification [$name]+[$fixedModif[$i+1]] at pos [$i] in variablePeptide");
	  }
	}
	else{
	  # Sets the modification
	  $fixedModif[$i+1] = $name;
	}
      }
    }
  }

  # Separates fixed from localized variable modifications as given by the parameter modif
  for (my $i = 0; $i < $len+2; $i++){
    if (length($modif[$i]) > 0){
      if (index($modif[$i], '(*)') == 0){
	# Adds variable modif by checking that they are all different
	my @list = split(/,/, substr($modif[$i], 3));
	for (my $j = 0; $j < @list; $j++){
	  for (my $k = 0; $k < $j; $k++){
	    if ($list[$k] eq $list[$j]){
	      croak("Two identical localized variable modifications for the same amino acid [$list[$k]] = [$list[$j]]");
	    }
	  }
	  if (defined($elMass{"mod_$list[$j]"})){
	    push(@{$varModif[$i]}, $list[$j]);
	  }
	  else{
	    croak(__FILE__."(".__LINE__.") Unknown modification in variablePeptide: [$list[$j]]");
	  }
	}
      }
      else{
	# Adds fixed modif
	if (defined($elMass{"mod_$modif[$i]"})){
	  if (length($fixedModif[$i]) > 0){
	    if ($fixedModif[$i] ne $modif[$i]){
	      croak("Multiple fixed modification [$modif[$i]]+[$fixedModif[$i]] at pos [",$i-1,"] in variablePeptide");
	    }
	  }
	  else{
	    $fixedModif[$i] = $modif[$i];
	  }
	}
	else{
	  croak(__FILE__."(".__LINE__.") Unknown modification in variablePeptide: [$modif[$i]]");
	}
      }
    }
  }

  # Locates variable modifications
  foreach my $name (@{$varModif}){
    # Checks modification
    if (!defined($elMass{"mod_$name"})){
      croak(__FILE__."(".__LINE__.") Unknown modification in variablePeptide: [$name]");
    }

    my $mr=InSilicoSpectro::InSilico::ModRes::getFromDico($name);
    my @modpos=$mr->seq2pos($peptSeq);
    # locates and adds
    if ($mr->nTerm){
      # N-term modification
      if (@modpos){
	# Checks it is new for this position
	my $new = 1;
	for (my $j = 0; $j < @{$varModif[0]}; $j++){
	  if ($name eq $varModif[0][$j]){
	    $new = 0;
	    last;
	  }
	}

	# Adds
	if ($new){
	  push(@{$varModif[0]}, $name);
	}
      }
    }
    elsif ($mr->cTerm){
      # C-term modification
      if (@modpos){
	# Checks it is new for this position
	my $new = 1;
	for (my $j = 0; $j < @{$varModif[$len+1]}; $j++){
	  if ($name eq $varModif[$len+1][$j]){
	    $new = 0;
	    last;
	  }
	}

	# Adds
	if ($new){
	  push(@{$varModif[$len+1]}, $name);
	}
      }
    }
    else{
      # Non terminal modification
      foreach my $i (@modpos){
	# Checks it is new for this position
	my $new = 1;
	for (my $j = 0; $j < @{$varModif[$i+1]}; $j++){
	  if ($name eq $varModif[$i+1][$j]){
	    $new = 0;
	    last;
	  }
	}
	
	# Adds
	if ($new){
	  push(@{$varModif[$i+1]}, $name);
	}
      }
    }
  }

  # Computes the vector of all modifications
  for (my $i = 0; $i < $len+2; $i++){
    if (length($fixedModif[$i]) > 0){
      $modifVect->[$i] = $fixedModif[$i];
    }
    elsif (scalar(@{$varModif[$i]}) > 0){
      $modifVect->[$i] = '(*)'.join(',', @{$varModif[$i]});
    }
    else{
      $modifVect->[$i] = '';
    }
  }

} # locateModif


# -----------------------------------------------------------------------
# MS/MS functions
# -----------------------------------------------------------------------


=head1 Fragment mass functions

Fragment types are read from the configuration file. Supplementary 
fragments can be added subsequently by using the function setLoss,
setSeries, and setFragType. Each fragment type is described by three main
properties:

=over 4

=item Ion series

A fragment ion series is the basic properties required for computing theoretical
masses. Classical ion series are a,b,c and x,y,z. They define the generic
position where the peptide is fragmented. 

Certain very short fragments, such as b1, or very long fragments, such
as bn, are normally not produced or detected. Hence an ion series also
defines the first and last possible fragments.

=item Charge state

A fragment charge state can be 1,2,3,...

=item Neutral losses

Certain amino acids have the potential to loose certain molecules during the
fragmentation process. To precisely define a fragment type one must specify
if loss(es) is(are) possible and, if yes, which one(s) and with which
multiplicity.

For instance, a fragment type b-H2O can be defined that
is able to loose water once. Another example is b-H2O* that is allowed to
loose water as many times as possible, depending on the peptide sequences
(the maximum number of loss is limited by the number of amino acids able
to loose water in the peptide sequence).

It is even possible to combine losses: b-NH3*-H2O* is a fragment type
that allows for multiple water and ammonia losses.

=back

=head2 getFragmentMasses(%h)

This function computes the theoretical fragmentation spectrum (MS/MS
spectrum) of a peptide. Namely, the peptide can given by a string, a 
InSilicoSpectro::InSilico::Peptide object or a InSilicoSpectro::InSilico::AASequence object
Top-down proteomics).

The named parameters are:

=over 4

=item pept

The peptide.

=item modif

The peptide localized modifications. Can be a string or a reference to
a vector, see function digestByRegExp. When not provided the peptide
is assumed unmodified.

Only fixed (and localized) modifications make sense in the context
of fragment mass computations.

If the peptide is provided as a InSilicoSpectro::InSilico::Peptide object or a
InSilicoSpectro::InSilico::AASequence object and the parameter modif is not
given, then the localized modifications are taken from the object.

=item fragTypes

A reference to a vector that gives the list of fragment types to use
for computing the theoretical spectrum.

=item spectrum

A reference to a hash that is used for storing the theoretical spectrum.
This hash is emptied before computation to remove a possible previous
spectrum.

=back

The data structure containing the theoretical spectrum is as follows.

  $spectrum{peptide}     = peptide sequence or Peptide object (depends on the given parameter)
  $spectrum{modif}       = reference to the vector of modifications actually used for the computation
  $spectrum{peptideMass} = peptide mass
  $spectrum{mass}        = theoretical spectrum
  $spectrum{ionType}     = ion types

$spectrum{mass} is a reference to another hash whose keys are either
term for N- or C-terminal fragments, or internal for internal fragments
such as immonium ions.

$spectrum{mass}{term} is a reference to a hash whose keys are the computed
fragment types. For instance, we assume that b,y,b-H2O* were computed. We
have

  $spectrum{mass}{term}{b}        = theoretical b fragment masses
  $spectrum{mass}{term}{y++}      = theoretical y++ fragment masses
  $spectrum{mass}{term}{b-H2O*}   = theoretical b-H2O* fragment masses

In case of fragment types without loss the hash

  $spectrum{mass}{term}{fragment_type}

is a reference to a vector of length n, where n is the length of the
peptide sequence. For a N-terminal fragment type (a,b,c), index i
in this vector correspond to a fragment that includes the i-th amino
acid as its last amino acid. For a C-terminal fragment type (x,y,z),
index i in this vector corresponds to a fragment that includes
the (n-i)-th amino acid as its last amino acid. B<unused
positions> (too short or too long fragments) are left B<undefined>.

=head3 Losses

In case of fragment with loss, it is possible that more than
n positions are required to store the theoretical spectrum. We note
that by convention fragment types with loss (b-H2O, b-H2O*) must
include one loss at least. That is they do not include the masses
corresponding to the fragment type without loss (b).

Simultaneous losses at one amino acid are not permitted. Such
multiple losses can be caused by defining a fragment type with
several possible losses and at least two of these losses are
possible on the same amino acid. In case you really need multiple
losses, you can define a new fragment type that only happens at
the common amino acid and induces the total mass shift.

If we find no possible loss in a given peptide sequence for a
given fragment type, then the reference

  $spectrum{mass}{term}{fragment_type}

remains undefined. If only one position for potential loss exists
or the fragment type limits the number of loss to one (b-NH3), then
the length of the theoretical spectrum will be n as for fragments
without loss. In case several losses are possible and several
positions for loss are found, the the length of the vector referen-
ced by $spectrum{mass}{term}{fragment_type} is a multiple of n.
For instance for two losses we would have the masses with one
loss in the cells 0...n-1 and the masses with two losses in the
cells n...2n-1. Recall that impossible fragments are
represented by undefined cells.

In order to display theoretical spectra it is useful to be
able to keep track of the exact number of losses, especially
when several types of losses are possible simultaneously. Thus
we store in

  $spectrum{ionType}

strings that describe the exact type of ions at hand. For instance
b++-2(H2O)-NH3 to describe a doubly charged b fragment with two
water losses and one ammonia loss (its fragment type b++-H2O*-NH3*
does not provide this information). The ion types are listed
by fragment types as are the theoretical masses

  $spectrum{ionType}{b}
  $spectrum{ionType}{y++}
  $spectrum{ionType}{b-H2O*}

For fragment types without loss we simply copy the fragment type

  $spectrum{ionType}{b}[0]   = 'b'
  $spectrum{ionType}{y++}[0] = 'y++'

whereas for fragment types with loss, we compute the appropriate
strings and store them as a vector referenced by

  $spectrum{ionType}{fragment_type}.

=head3 Immonium ions

Immonium ions are internal ions that result from a y_m/a_n cleavages.
By specifying 'immo' in the list of ion types, the masses corresponding
to the immonium ions of the amino acids present in the peptide are
computed and stored in a hash

  $spectrum{mass}{intern}{immo}

whose keys are the one letter codes of the residues and the values
are the masses.

The configuration file contains the information about which are the
amino acids that yield such ions as well as the mass delta to apply
to the amino acid mass. Moreover, modified cysteines as well as
modified methionine and histidine are included in the immonium ions
with adapted mass. For Lysine, both its "nominal" immonium ion mass
(101) and after ammonia loss (84) are computed. Immonium ions for
the N- and C-terminal amino acids are not computed.

=head3 Example

my %spectrum;
$peptide = 'HCMSKPQMLR';
$modif = '::Cys_CAM::::::Oxidation:::';
getFragmentMasses(pept=>$peptide, modif=>$modif, fragTypes=>['b','a',
          'b-NH3*','b-H2O*','b++','y','y-NH3*','y-H2O*','y++','immo'],
          spectrum=>\%spectrum);
print "\nfragments ($spectrum{peptideMass}):\n";
my $len = length($peptide);
foreach my $frag (keys(%{$spectrum{mass}{term}})){
  for (my $i = 0; $i < @{$spectrum{ionType}{$frag}}; $i++){
    print $spectrum{ionType}{$frag}[$i];
    for (my $j = $i*$len; $j < ($i+1)*$len; $j++){
      print "\t", $spectrum{mass}{term}{$frag}[$j]+0.0;
    }
    print "\n";
  }
}
foreach my $frag (keys(%{$spectrum{mass}{intern}})){
  print $spectrum{ionType}{$frag}[0];
  foreach my $aa (keys(%{$spectrum{mass}{intern}{$frag}})){
    print "\t$aa\t$spectrum{mass}{intern}{$frag}{$aa}";
  }
  print "\n";
}

More examples in InSilicoSpectro/InSilico/test/testCalcFrag.pl and InSilicoSpectro/InSilico/test/testCalcFragOOP.pl.

=cut
sub getFragmentMasses
{
  my (%h) = @_;
  my ($pept, $modif, $frags, $spectrum) = ($h{pept}, $h{modif}, $h{fragTypes}, $h{spectrum});

  # Cleans the spectrum hash just in case
  undef(%$spectrum);

  # Gets peptide sequence
  my $peptSeq;
  if (ref($pept)){
    if ($pept->isa('InSilicoSpectro::InSilico::Peptide') || $pept->isa('InSilicoSpectro::InSilico::AASequence')){
      $peptSeq = $pept->sequence();
      if (!defined($modif)){
	$modif = $pept->modif();
      }
    }
    else{
      croak("Illegal peptide object [$pept]");
    }
  }
  else{
    $peptSeq = $pept;
  }

  # Computes peptide mass
  my $len = length($peptSeq);
  my @modif;
  if (defined($modif)){
    if ((my $ref = ref($modif)) eq 'ARRAY'){
      # The modifs are given as a vector directly
      @modif = @$modif;
      croak("Vector @$modif too long[".join(',',@modif)."]") if (@modif > $len+2);
    }
    elsif (!$ref){
      # Scalar, assume string
      @modif = split(/:/, $modif);
    }
    else{
      croak("Unknown format for specifying modifications [$modif]");
    }
  }
  my $peptideMass = getPeptideMass(pept=>$peptSeq, modif=>\@modif);
  $spectrum->{peptideMass} = $peptideMass;
  $spectrum->{peptide} = $pept;
  $spectrum->{modif} = [@modif];

  # Computes the sums of amino acid masses
  my @pept = split(//, $peptSeq);
  my $mass = 0;
  $mass += getMass("mod_$modif[0]") if ($modif[0]); # N-term modif
  my @base;
  push(@base, 0); # for complete C-Term ions
  for (my $i = 0; $i < @pept; $i++){
    $mass += getMass("aa_$pept[$i]");
    $mass += getMass("mod_$modif[$i+1]") if ($modif[$i+1]); # internal modif
    push(@base, $mass);
  }
  $base[-1] += getMass("mod_$modif[$len+1]") if ($modif[$len+1]); # C-term modif

  # Computes the fragments of each requested fragment type
  foreach my $frag (@$frags){

    if ($frag eq 'immo'){
      # Immonium ions

      my %already;
      for (my $i = 1; $i < @pept-1; $i++){
	if (defined($immoAA{$pept[$i]})){
	  my $actualAA = "$pept[$i]|$modif[$i+1]";
	  next if (defined($already{$actualAA}));

	  if (!$modif[$i+1] || (($pept[$i] eq 'C') || ($pept[$i] eq 'M') || ($pept[$i] eq 'H'))){
	    my $mass = getMass("aa_$pept[$i]") + $immoDelta;
	    my $immoName = $pept[$i];
	    if ($modif[$i+1]){
	      $immoName .= "+$modif[$i+1]";
	      $mass += getMass("mod_$modif[$i+1]");
	    }
	    $spectrum->{mass}{intern}{$frag}{$immoName} = $mass;
	    if ($pept[$i] eq 'K'){
	      # Consider a possible extra mass with ammonia loss
	      $mass -= getMass('mol_NH3');
	      $spectrum->{mass}{intern}{$frag}{"$immoName-NH3"} = $mass;
	    }
	    $already{$actualAA} = 1;
	    $spectrum->{ionType}{$frag}[0] = 'immo';
	  }
	}
      }
    }
    else{
      # Regular fragment types

      my $series = $fragType{$frag}{series};
      my $charge = $fragType{$frag}{charge};
      my $loss = $fragType{$frag}{loss};
      my $firstFrag = $series{$series}{firstFrag};
      my $lastFrag = $series{$series}{lastFrag};
      my $delta = $series{$series}{delta}[$massType];

      if (!defined($loss)){
	# no loss, straightforward computation
	$delta += ($charge-1)*getMass('el_H+');
	
	if ($series{$series}{terminus} eq 'N'){
	  # N-term ions
	  $delta += $nTerm;
	  for (my $i = $firstFrag; $i <= $len-$lastFrag+1; $i++){
	    $spectrum->{mass}{term}{$frag}[$i-1] = ($base[$i]+$delta)/$charge;
	  }
	  $spectrum->{ionType}{$frag}[0] = $frag;
	}
	else{
	  # C-term ions, reverse and complement masses
	  for (my $i = $firstFrag-1; $i < $len-$lastFrag+1; $i++){
	    $spectrum->{mass}{term}{$frag}[$i] = ($peptideMass-$base[$len-$i-1]+$delta)/$charge;
	  }
	  $spectrum->{ionType}{$frag}[0] = $frag;
	}
      }
      else{
	# Losses, possibly multiple and combined
	
	# Locates available positions for loss for each loss type (and checks all residues are different)
	my @loss = @$loss;
	my (@avail, $nTotLoss, @distinctPos);
	my ($startLoop, $endLoop) = ($series{$series}{terminus} eq 'N') ? (0, $len-$lastFrag) : ($lastFrag-1, $len-1);
	for (my $i = $startLoop; $i <= $endLoop; $i++){
	  for (my $j = 0; $j < @loss; $j++){
	    if ($loss{$loss[$j]}{residues}{$pept[$i]}){
	      push(@{$avail[$j]}, $i);
	      $nTotLoss++;
	      $distinctPos[$i]++;
	    }
	  }
	}
	next if ($nTotLoss == 0); # this ion type is not possible for this peptide
	for (my $i = 0; $i < @distinctPos; $i++){
	  if ($distinctPos[$i] > 1){
	    croak("Multiple loss at one single amino acid [$pept[$i]] in [$frag]");
	  }
	}
	
	# Computes maximum number of losses for each loss type
	my @maxLoss;
	for (my $j = 0; $j < @loss; $j++){
	  my $repeat = $fragType{$frag}{repeat}[$j];
	  $repeat = $len if ($repeat == -1);
	  $maxLoss[$j] = defined($avail[$j]) ? ( (@{$avail[$j]} < $repeat) ? scalar(@{$avail[$j]}) : $repeat ) : 0;
	}
	
	# Reverses the loss positions for C-term ions
	if ($series{$series}{terminus} eq 'C'){
	  for (my $j = 0; $j < @loss; $j++){
	    @{$avail[$j]} = reverse(@{$avail[$j]});
	  }
	}
	
	# Generates every combination of number of possible losses
	my $comb = 0;
	my @nLoss = split(//, '0' x @maxLoss);
	$nLoss[0] = 1;
	$delta += $nTerm if ($series{$series}{terminus} eq 'N');
	while (1){
	  # Computes the fragments of the current combination

	  # Adapt delta to the number of losses
	  my $d = $delta;
	  for (my $i = 0; $i < @maxLoss; $i++){
	    $d += $nLoss[$i]*$loss{$loss[$i]}{delta}[$massType];
	  }

	  if ($series{$series}{terminus} eq 'N'){
	    # N-term ions

	    # First position that includes as many as required possible losses
	    my $rightMost = 0;
	    for (my $i = 0; $i < @maxLoss; $i++){
	      if (($nLoss[$i] > 0) && ($avail[$i][$nLoss[$i]-1] > $rightMost)){
		$rightMost = $avail[$i][$nLoss[$i]-1];
	      }
	    }

	    # Computes the fragments and check they are visible (firstFrag/lastFrag)
	    for (my $i = $rightMost+1; $i <= $len-$lastFrag+1; $i++){
	      if ($i >= $firstFrag){
		$spectrum->{mass}{term}{$frag}[($comb*$len)+$i-1] = ($base[$i]+$d)/$charge;
	      }
	    }
	  }
	  else{
	    # C-term ions

	    # Last position that includes as many as required possible losses (from the right)
	    my $leftMost = $len-1;
	    for (my $i = 0; $i < @maxLoss; $i++){
	      if (($nLoss[$i] > 0) && ($avail[$i][$nLoss[$i]-1] < $leftMost)){
		$leftMost = $avail[$i][$nLoss[$i]-1];
	      }
	    }

	    # Computes the fragments and check they are visible (firstFrag/lastFrag)
	    for (my $i = $len-$leftMost-1; $i < $len-$lastFrag+1; $i++){
	      if ($i >= $firstFrag-1){
		$spectrum->{mass}{term}{$frag}[($comb*$len)+$i] = ($peptideMass-$base[$len-$i-1]+$d)/$charge;
	      }
	    }
	  }

	  # Computes the exact ion type and saves its name
	  my $ionType = $series;
	  for (my $i = 0; $i < @maxLoss; $i++){
	    if ($nLoss[$i] > 1){
	      $ionType .= "-$nLoss[$i]($loss[$i])";
	    }
	    elsif ($nLoss[$i] == 1){
	      $ionType .= "-$loss[$i]";
	    }
	  }
	  $spectrum->{ionType}{$frag}[$comb] = $ionType;
	  $comb++;

	  # Gets the next combination
	  my $i;
	  for ($i = 0; ($i < @maxLoss) && ($nLoss[$i] == $maxLoss[$i]); $i++){}
	  last if ($i == @maxLoss);
	  $nLoss[$i]++;
	  for (my $j = 0; $j < $i; $j++){
	    $nLoss[$j] = 0;
	  }
	}
      }
    }
  }

} # getFragmentMasses


=head2 matchSpectrumClosest(%h)

This function compares an experimental MS/MS spectrum with a theoretical
MS/MS spectrum and associates each theoretical mass with its closest
experimental mass. The application of any mass tolerance can be done
afterwards.

The named parameters are:

=over 4

=item pept

The peptide sequence or a Peptide object. When not provided the spectrum is considered to be
already computed and ready for use in spectrum.

=item modif

The modification string. When not provided the peptide is assumed
unmodified. If the peptide is provided as a Peptide object, then
the modifications are read from the Peptide object if no modif
parameter is set, otherwise it overrides the object data.

=item fragTypes

A reference to a vector that gives the list of fragment types to use
for computing the theoretical spectrum.

=item spectrum

The theoretical spectrum.

=item expSpectrum

The experimental spectrum, a data structure or an object InSilicoSpectro::Spectra::ExpSpectrum, see
method PMFMatch.

=item sorted

The experimental spectrum must sorted with respect to the mass for 
matchSpectrumClosest to work. In case it is already sorted when the
function is called, sorted can be set to any value to avoid an
unnecessary sort operation.

=item massIndex

The mass index in the experimental peak vectors, default 0.

=back

The result of the matching is an addition to the spectrum data structure.
A new structure parallel to spectrum->{mass} is created that is named

  spectrum->{match}

that references a hash analogous to spectrum->{mass} but with the
theoretical masses replaced by references to the closest peaks
vector in expSpectrum.

Examples in InSilicoSpectro/InSilico/test/testCalcMatch.pl and InSilicoSpectro/InSilico/test/testCalcMatchOOP.pl.

=cut
sub matchSpectrumClosest
{
  my (%h) = @_;
  my ($pept, $modif, $frags, $spectrum, $spec, $sorted, $massIndex) = ($h{pept}, $h{modif}, $h{fragTypes}, $h{spectrum}, $h{expSpectrum}, $h{sorted}, $h{massIndex});

  if (defined($pept)){
    # First compute the spectrum
    getFragmentMasses(pept=>$pept, modif=>$modif, fragTypes=>$frags, spectrum=>$spectrum);
  }

  $massIndex = $massIndex || 0;

  # Determines spectrum type
  my $expSpectrum;
  if (ref($spec) && (ref($spec) ne 'ARRAY') && $spec->isa('InSilicoSpectro::Spectra::ExpSpectrum')){
    $expSpectrum = $spec->spectrum();
    $massIndex = $spec->peakDescriptor()->getFieldIndex('mass');
  }
  else{
    $expSpectrum = $spec;
  }
  $spectrum->{massIndex} = $massIndex;
  $spectrum->{expSpectrum} = $expSpectrum;

  # Prepares the experimental spectrum (sorts according to the first column that must be the mass)
  my @sorted = defined($sorted) ? @$expSpectrum : sort {$a->[$massIndex] <=> $b->[$massIndex]} @$expSpectrum;

  # Finds the closest terminal masses
  foreach my $frag (keys(%{$spectrum->{mass}{term}})){
    for (my $i = 0; $i < @{$spectrum->{mass}{term}{$frag}}; $i++){
      my $theoMass;
      if (defined(($theoMass = $spectrum->{mass}{term}{$frag}[$i]))){
	$spectrum->{match}{term}{$frag}[$i] = dichoSpectrumSearch(\@sorted, 0, $#sorted, $theoMass, $massIndex);
      }
    }
  }

  # Finds the closest internal masses
  foreach my $frag (keys(%{$spectrum->{mass}{intern}})){
    foreach my $aa (keys(%{$spectrum->{mass}{intern}{$frag}})){
      my $theoMass = $spectrum->{mass}{intern}{$frag}{$aa};
      $spectrum->{match}{intern}{$frag}{$aa} = dichoSpectrumSearch(\@sorted, 0, $#sorted, $theoMass, $massIndex);
    }
  }

} # matchSpectrumClosest


=head2 matchSpectrumGreedy(%h)

Alternative algorithm for matching experimental and theoretical spectra. The experimental
spectrum must have the masses at index 0 and the intensities at index 1 in the peak
vectors. The mass error tolerance is determined by the rule

  relative error <= tol OR absolute error <= minTol

Four named parameters are available in addition to the ones of matchSpectrumClosest:

=over 4

=item tol

Relative mass tolerance (default 500 ppm).

=item minTol

Minimum absolute mass tolerance (default 0.2 Da).

=item order

A reference to a vector that gives the fragment types in an order of priority for
matching.

=item intensityIndex

The intensity index in the experimental peak vectors, default 1.

=back

If order is not set, then matchSpectrumGreedy returns the matching experimental
peaks within mass tolerance tol with the highest intensities. That is when several
experimental masses are possible, the one corresponding to the most intense peak
is chosen, although it is not necessarily the closest.

If order is set, then a greedy algorithm is applied additionally. Namely, the
fragment types are processed in the order given by this parameter and the most
intense peaks are chosen as before but a chosen peak is no longer available
for subsequent matches. This ensures that experimental masses are used once
only which is not true for the case with no order and for matchSpectrumClosest.

Examples in InSilicoSpectro/InSilico/test/testCalcMatch.pl and InSilicoSpectro/InSilico/test/testCalcMatchOOP.pl.

=cut
sub matchSpectrumGreedy
{
  my (%h) = @_;
  my ($pept, $modif, $frags, $spectrum, $spec, $tol, $minTol, $order, $sorted, $massIndex, $intensityIndex) = ($h{pept}, $h{modif}, $h{fragTypes}, $h{spectrum}, $h{expSpectrum}, $h{tol}, $h{minTol}, $h{order}, $h{sorted}, $h{massIndex}, $h{intensityIndex});

  $tol = $tol || 500;
  $minTol = $minTol || 0.2;
  $massIndex = $massIndex || 0;
  $intensityIndex = $intensityIndex || 1;

  if (defined($pept)){
    # First compute the spectrum
    getFragmentMasses(pept=>$pept, modif=>$modif, fragTypes=>$frags, spectrum=>$spectrum);
  }

  # Determines spectrum type
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
  $spectrum->{massIndex} = $massIndex;
  $spectrum->{intensityIndex} = $intensityIndex;
  $spectrum->{expSpectrum} = $expSpectrum;

  # Prepares the experimental spectrum (sorts according to the first column that must be the mass)
  my @sorted = defined($sorted) ? @$expSpectrum : sort {$a->[$massIndex] <=> $b->[$massIndex]} @$expSpectrum;
  my @used;

  # Find the closest masses
  my @orderedFrag = defined($order) ? @$order : (keys(%{$spectrum->{mass}{term}}), keys(%{$spectrum->{mass}{intern}}));
  foreach my $frag (@orderedFrag){
    if (defined($spectrum->{mass}{term}{$frag})){
      for (my $i = 0; $i < @{$spectrum->{mass}{term}{$frag}}; $i++){
	my $theoMass;
	if (defined(($theoMass = $spectrum->{mass}{term}{$frag}[$i]))){
	  $spectrum->{match}{term}{$frag}[$i] = dichoSpectrumMostIntSearch(\@sorted, 0, $#sorted, $theoMass, $tol, $minTol, defined($order), \@used, $massIndex, $intensityIndex);
	}
      }
    }
    elsif (defined($spectrum->{mass}{intern}{$frag})){
      foreach my $aa (keys(%{$spectrum->{mass}{intern}{$frag}})){
	my $theoMass = $spectrum->{mass}{intern}{$frag}{$aa};
	$spectrum->{match}{intern}{$frag}{$aa} = dichoSpectrumMostIntSearch(\@sorted, 0, $#sorted, $theoMass, $tol, $minTol, defined($order), \@used, $massIndex, $intensityIndex);
      }
    }
  }

} # matchSpectrumGreedy


=head2 getSeries($name)

Returns a vector (terminus, monoisotopic delta, average delta,
first fragment, last fragment) that contains the parameters
of series $name, where

=over 4

=item $name

is th name of the series, e.g. b or y.

=item terminus

is equal to 'N' or 'C'.

=item monoisotopic delta

is the mass delta to apply when computing the monoisotopic mass.
It is 0 for a b series and 1.007825 for y.

=item average delta

is the mass delta to apply when computing the average mass.
It is 0 for a b series and 1.007976 for y.

=item first fragment

is the number of the first fragment to compute. For instance,
fragment b1 is generally not detected hence first fragment
should be set to 2 for a b series. The rule is the same for
N- and C-term series.

=item last fragment

is the number of the last fragment counted from the end. For
instance, the last b fragment is normally not detected hence
last fragment should be set to 2. If a fragment containing
all the amino acids of the peptide is possible, then it
should be set to 1. The rule is the same for N- and C-term
series.

=back

=cut
sub getSeries
{
  my ($name) = @_;

  return ($series{$name}{terminus}, $series{$name}{delta}[0], $series{$name}{delta}[1], $series{$name}{firstFrag}, $series{$name}{lastFrag});

} # getSeries


=head2 setSeries($name, $terminus, $formula, $firstFrag, $lastFrag)

Adds a new series to the series read from the configuration file.
The parameters are defined above in getSeries except formula.
The mass deltas are not given as real numbers but rather as
deltas in atoms. For instance, b series formula is empty because
we do want 0 delta and c series formula is 'N 1 H 3'. Example:

  setSeries('c', 'N', 'N 1 H 3', 2, 2);

=cut
sub setSeries
{
  my ($name, $terminus, $formula, $firstFrag, $lastFrag) = @_;
  croak("Already defined series for [$name]") if (defined($series{$name}));

  $series{$name}{terminus} = uc($terminus);
  $series{$name}{delta} = [massFromComposition($formula)];
  $series{$name}{firstFrag} = $firstFrag;
  $series{$name}{lastFrag} = $lastFrag;

} # setSeries


=head2 getLoss($name)

Returns a vector (residues, monoisotopic delta, average delta)
that contains the parameters of a neutral loss, where

=over 4

=item $name

is the name of the neutral loss.

=item residues

is a string containing the one character codes of the amino
acids where the loss is possible.

=item monoisotopic delta

is the mass delta to apply when computing the monoisotopic mass.

=item average delta

is the mass delta to apply when computing the average mass.

=back

=cut
sub getLoss
{
  my ($name) = @_;

  return (join('', keys(%{$loss{$name}{residues}})), $loss{$name}{delta}[0], $loss{$name}{delta}[1]);

} # getLoss


=head2 setLoss($name, $residues, $formula)
=head2 setLoss($name, $residues, $deltamass_mono, $deltamass_avg)

Adds a new loss to the ones read from the file fragments.xml.
The parameters are defined above in getLoss except formula.
The mass deltas are not given as real numbers but rather as
deltas in atoms. Example:

  setLoss('H2O', 'ST', 'H 2 O 1');
or 
  setLoss('H2O', 'ST', 18.003, 17.927);

=cut
sub setLoss
{
  my $name=shift;
  my $residues=shift;
  if($_[0]=~/^[A-Z]/){
    #we have a formula
    my $formula=shift;
    croak("Already defined loss for [$name]") if (defined($loss{$name}));
    $loss{$name}{delta} = [massFromComposition($formula)];
  }else{
    # we should have two masses
    $loss{$name}{delta} = [$_[0], $_[1]];
  }

  foreach (split(//, $residues)){
    $loss{$name}{residues}{$_} = 1;
  }

} # setLoss


=head2 getFragType($name)

Returns a vector (series, charge, loss 1, repeat 1, loss 2, repeat 2, ...)
containing the parameters of a fragment type, where

=over 4

=item $name

is the name of the fragment type.

=item series

is the series on which this fragment type is based.

=item charge

is the charge state of a fragment of this type.

=item loss k

in case the fragment type includes losses, loss k is set to the name of
each loss possible for this fragment type.

=item repeat k

the maximum number of each loss, -1 means no maximum.

=back

=cut
sub getFragType
{
  my ($name) = @_;

  my @tmp = ($fragType{$name}{series}, $fragType{$name}{charge});
  if (defined($fragType{$name}{loss})){
    for (my $i = 0; $i < @{$fragType{$name}{loss}}; $i++){
      push (@tmp, $fragType{$name}{loss}[$i], $fragType{$name}{repeat}[$i]);
    }
  }
  return @tmp;

} # getFragType


=head2 getFragTypeList

Returns a vector containing the list of all fragment type names (in arbitrary order).

=cut
sub getFragTypeList
{
  return (keys(%fragType), 'immo');

} # getFragTypeList


=head2 setFragType($name, $series, $charge, $loss, $repeat)

Adds a new fragment type to the ones read from the file fragments.xml.
The parameters $name, $charge and $series are defined above in
getFragType.

=over 4

=item $loss

is the reference of a vector containing the names of the possible
losses for this fragment type. In case no loss is possible then
$loss may be let undefined or references an empty vector.

=item $repeat

gives the repetitions of the losses listed in vector $loss.
If $loss is undefined or references an empty vector, then
$repeat is ignored.

=back

Example:

  setFragType('y++-H2O*-NH3(2)', 'y', 2, ['H2O', 'NH3'], [-1, 2]);

defines a fragment type made of doubly charged y fragments with a
maximum of 2 ammonia losses and an arbitrary number of water losses.

=cut
sub setFragType
{
  my ($name, $series, $charge, $loss, $repeat) = @_;
  croak("Already defined fragment type for [$name]") if (defined($fragType{$name}));

  croak("Series [$series] not defined for fragment type [$name]") if (!defined($series{$series}));
  $fragType{$name}{series} = $series;
  $fragType{$name}{charge} = $charge;
  if (defined($loss)){
    for (my $i = 0; $i < @$loss; $i++){
      if (!defined($loss{$loss->[$i]})){
	croak("Loss [$loss->[$i]] not defined for fragment type [$name]");
      }
    }
    $fragType{$name}{loss} = [@$loss] if (@$loss > 0);
    $fragType{$name}{repeat} = [@$repeat] if (@$loss > 0);
  }

} # setFragType


=head2 setImmonium($residues, $delta)

Replaces the definition of immonium ion parameters read from the file
fragments.xml.

=over 4

=item $residues

is a string containing the one letter codes of the residues that
yield detectable immonium ions.

=item $delta

is the mass delta to obtain the immonium ion mass from its amino
acid mass.

=back

=cut
sub setImmonium
{
  my ($residues, $delta) = @_;

  $immoDelta = $delta;
  undef(%immoAA);
  foreach (split(//, $residues)){
    $immoAA{$_} = 1;
  }

} # setImmonium


=head2 getImmonium

Returns a vector (residues, delta); the parameters residues and delta
are defined in setImmoniumn above.

=cut
sub getImmonium
{
  return (join('', keys(%immoAA)), $immoDelta);

} # getImmonium


=head2 getImmoniumMass($aa, $mod)

Computes the mass of an immonium ion given the amino acid one letter
code $aa and a possible modification $mod. In case of Lysine (K), two
values are returned.

=cut
sub getImmoniumMass
{
  my ($aa, $mod) = @_;

  my $mass = getMass("aa_$aa")+$immoDelta;
  $mass += getMass("mod_$mod") if ($mod);
  if ($aa eq 'K'){
    # Consider a possible extra mass with ammonia loss
    return ($mass, $mass-getMass('mol_NH3'))
  }
  else{
    return $mass;
  }

} # getImmoniumMass


# ------------------------------------------------------------------------
# XML parsing
# ------------------------------------------------------------------------


sub twigAddElement
{
  my ($twig, $el) = @_;

  my $symbol = $el->atts->{symbol};
  my $mel = $el->first_child('mass');
  my $mono = $mel->atts->{monoisotopic};
  my $avg = $mel->atts->{average};
  $elMass{"el_$symbol"} = [$mono, $avg];

} # twigAddElement


sub twigAddMolecule
{
  my ($twig, $el) = @_;

  my $symbol = $el->atts->{symbol};
  my ($mono, $avg);
  if (my $mel = $el->first_child('mass')){
    # Mass directly provided, use it
    $mono = $mel->atts->{monoisotopic};
    $avg = $mel->atts->{average};
  }
  else{
    # Use the formula instead
    my $formula = $el->first_child('formula')->text;
    ($mono, $avg) = massFromComposition($formula);
  }
  $elMass{"mol_$symbol"} = [$mono, $avg];

} # twigAddMolecule


sub twigAddAminoAcid
{
  my ($twig, $el) = @_;
  my $symbol = $el->atts->{code1};
  my $mel = $el->first_child('mass');
  my $mono = $mel->atts->{monoisotopic};
  my $avg = $mel->atts->{average};
  $elMass{"aa_$symbol"} = [$mono, $avg];

} # twigAddAminoAcid


sub twigAddSeries
{
  my ($twig, $el) = @_;

  my $name = $el->atts->{name};
  my $terminus = $el->first_child('terminus')->text;
  my $firstFrag = $el->first_child('firstFragment')->text;
  my $lastFrag = $el->first_child('lastFragment')->text;
  my $formula = $el->first_child('formula')->text;
  setSeries($name, $terminus, $formula, $firstFrag, $lastFrag);

} # twigAddSeries


sub twigAddLoss
{
  my ($twig, $el) = @_;

  my $name = $el->atts->{name};
  my $residues = $el->first_child('residues')->atts->{aa};
  my $formula = $el->first_child('formula')&&$el->first_child('formula')->text;
  if($formula){
    setLoss($name, $residues, $formula);
  }else{
    my $eldm=$el->first_child('deltaMass')|| die "must specify 'formula' or 'deltamass' in oneLoss definition [$name]";
    $eldm->print(\*STDERR);
    setLoss($name, $residues, $eldm->atts->{monoisotopic}, $eldm->atts->{average});
  }

} # twigAddLoss


sub twigAddFragType
{
  my ($twig, $el) = @_;

  my $name = $el->atts->{name};
  my $series = $el->atts->{series};
  my $charge = $el->atts->{charge};
  my (@lossName, @repeat);
  my @children = $el->children('loss');
  foreach (@children){
    push(@lossName, $_->atts->{name});
    push(@repeat, $_->atts->{repeat});
  }
  setFragType($name, $series, $charge, \@lossName, \@repeat);

} # twigAddFragType


sub twigAddInternFragType
{
  my ($twig, $el) = @_;

  my $name = $el->atts->{name};
  my $residues = $el->first_child('residues')->text;
  my $mono = $el->first_child('delta')->atts->{monoisotopic};
  my $avg = $el->first_child('delta')->atts->{average};
  if ($name eq 'immo'){
    setImmonium($residues, $mono);
  }
  else{
    croak("Unknown internal fragment type [$name]");
  }

} # twigAddInternFragType


sub twigAddModRes
{
  my ($twig, $el) = @_;

  my $name = $el->atts->{id} || $el->atts->{name};
  #return  added by alex; does not handle regexp definitions
  my $rel = $el->first_child('residues') or return;
  my $residues = $rel->atts->{aa};
  my $residuesAfter = $rel->atts->{aaAfter} || '.';
  my $terminus = defined($rel->atts->{nterm}) ? 'N' : (defined($rel->atts->{cterm}) ? 'C' : '-');
  my $del = $el->first_child('delta');
  my $mono = $del->atts->{monoisotopic};
  my $avg = $del->atts->{average};
  setModif($name, $mono, $avg, $residues, $residuesAfter, $terminus);

} # twigAddModRes


=head1 EXAMPLES

See programs starting with testCalc in folder InSilicoSpectro/InSilico/test/.

=head1 AUTHORS

Jacques Colinge, Upper Austria University of Applied Science at Hagenberg

=cut
