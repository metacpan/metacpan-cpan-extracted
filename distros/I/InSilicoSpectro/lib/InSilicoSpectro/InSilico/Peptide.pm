package InSilicoSpectro::InSilico::Peptide;

# Perl object class for peptides

# Copyright (C) 2005 Jacques Colinge and Alexandre Masselot

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

use strict;
require Exporter;
use Carp;

use InSilicoSpectro::InSilico::MassCalculator;
use InSilicoSpectro::InSilico::AASequence;
use InSilicoSpectro::InSilico::CleavEnzyme;
use InSilicoSpectro::Utils::io;

our (@ISA, @EXPORT, @EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT = qw();
@EXPORT_OK = ();

our %visibleAttr = (sequence=>1, modif=>1, parentProtein=>1, start=>1, end=>1, readingFrame=>1, nTerm=>1, cTerm=>1, enzymatic=>1, enzyme=>1, aaBefore=>1, aaAfter=>1, nmc=>1, addProton=>1);
our %aaList = split(//, 'A1C1D1E1F1G1H1I1K1L1M1N1P1Q1R1S1T1V1W1Y1');

return 1;


=head1 NAME

InSilicoSpectro::InSilico::Peptide - A class for digestion products

=head1 SYNOPSIS

use InSilicoSpectro::InSilico::Peptide;

=head1 DESCRIPTION

This class role is to model peptides obtained by enzymatic digestion (InSilicoSpectro::InSilico::CleavEnzyme) from
a protein sequence (InSilicoSpectro::InSilico::AASequence).

=head1 ATTRIBUTES

=over 4

=item sequence

=item modif

The localized modifications for MS/MS computations or a list of modifications with number of occurence
for PMF computations. See method getModifType.

=item parentProtein

A InSilicoSpectro::InSilico::AASequence object containing the protein sequence from which
the peptide has been obtained.

=item start

Start position in the parent protein sequence.

=item end

End position in the parent protein sequence.

=item readingFrame

Useful in case the digested protein sequence came from DNA/RNA translation.

=item nTerm

Boolean, is the peptide an N-terminal peptide.

=item cTerm

Boolean, is the peptide a C-terminal peptide.

=item enzyme

The enzyme that yielded the peptide (useful for mass computations because of
NTermGain and CTermGain for "exotic" enzymes); must be of class InSilicoSpectro::InSilico::CleavEnzyme.

=item aaBefore

Amino acid immediately before the peptide (at its N-terminus).

=item aaAfter

Amino acid immediately after the peptide (at its C-terminus).

=item enzymatic

Was the peptide cleaved by the enzyme at its both ends (value 'full'), at its
N-terminus only (value 'half-N'), at its C-terminus only (value 'half-C'), or
not enzymatic (value 'no').

This method is the accessor/modifier for attribute enzymatic.

=item nmc

Number of missed cleavages.

=item addProton

Set to 1 if you want to add the mass of one proton to the peptide mass when it
is computed (for PMF). Otherwise either set to 0 or do not set.

=back

=head1 METHODS

=head2 new(%h|$Peptide)

Constructor. %h is a hash of attribute=>value pairs, $Peptide is a
InSilicoSpectro::InSilico::Peptide object, from which the attributes are copied.

=cut
sub new
{
  my $pkg = shift;

  my $pept = {};
  my $class = ref($pkg) || $pkg;
  bless($pept, $class);

  if (ref($_[0]) && $_[0]->isa('InSilicoSpectro::InSilico::Peptide')){
    %$pept = %{$_[0]};
    undef($pept->{mass});
    bless($pept, $class);
  }
  else{
    bless($pept, $class);
    if (!ref($_[0])){
      my %h = @_;
      foreach (keys(%h)){
	$pept->$_($h{$_}) if ($visibleAttr{$_});
      }
    }
  }
  return $pept;

} # new


=head1 Accessors and modifiers

=head2 parentProtein([$val])

Returns the parent protein object (InSilicoSpectro::InSilico::AASequence). If $val is
given, then the parent protein is set to $val.

The end and start positions are left unchanged by this method, hence do not forget
to ajust them if needed. The readingFrame is copied from the protein.

=cut
sub parentProtein
{
  my ($this, $val) = @_;

  if (defined($val)){
    if ($val->isa('InSilicoSpectro::InSilico::AASequence')){
      $this->{parentProtein} = $val;
      $this->{readingFrame} = $val->{readingFrame};
      undef($this->{mass});
    }
    else{
      croak("The object must be of class InSilicoSpectro::InSilico::AASequence [".ref($val)."]");
    }
  }
  return $this->{parentProtein};

} # parentProtein


=head2 sequence([$val])

Returns the peptide sequence as a string. If $val is given then the peptide
sequence is set to $val.

=cut
sub sequence
{
  my ($this, $val) = @_;

  if (defined($val)){
    $val =~ s/\s//g;
    $this->{sequence} = $val;
    undef($this->{mass});
  }
  if (defined($this->{sequence})){
    return $this->{sequence};
  }
  else{
    # No sequence is only possible if there is a reference to a Sequence object
    if (!defined($this->{start}) || !defined($this->{end}) || !defined($this->{parentProtein})){
      croak("All of parentProtein, start, end must be defined if no sequence is set");
    }
    if ($this->{start} < $this->{end}){
      # Direct orientation
      return substr($this->parentProtein->sequence, $this->{start}, $this->{end}-$this->{start}+1);
    }
    else{
      # Reverse orientation
      return substr($this->parentProtein->sequence, $this->{end}, $this->{start}-$this->{end}+1);
    }
  }

} # sequence


=head2 enzyme([$val])

Enzyme accessor/modifier.

=cut
sub enzyme
{
  my ($this, $val) = @_;

  if (defined($val)){
    if (ref($val) && $val->isa('InSilicoSpectro::InSilico::CleavEnzyme')){
      $this->{enzyme} = $val;
      undef($this->{mass});
    }
    else{
      croak("Illegal enzyme class [$val]");
    }
  }
  return $this->{enzyme};

} # enzyme


=head2 location($start, $end, readingFrame)

Returns a vector with (start, end, readingFrame). If $start, $end, and
readingFrame are given then it sets them.

=cut
sub location
{
  my ($this, $start, $end, $readingFrame);
  return ($this->start($start), $this->end($end), $this->readingFrame($readingFrame));

} # location


=head2 start([$val])

Start position accessor/modifier.

=cut
sub start
{
  my ($this, $val) = @_;

  if (defined $val){
    $val = int($val);
    if ($val >= 0){
      $this->{start} = $val;
      undef($this->{mass});
    }
    else{
      croak("Negative position [$val]");
    }
  }
  return $this->{start};

} # start


=head2 end([$val])

End position accessor/modifier.

=cut
sub end
{
  my ($this, $val) = @_;

  if (defined $val){
    $val = int($val);
    if ($val >= 0){
      $this->{end} = $val;
      undef($this->{mass});
    }
    else{
      croak("Negative position [$val]");
    }
  }
  return $this->{end};

} # end


=head2 readingFrame([$val])

readingFrame accessor/modifier: sets readingFrame attribute if $val is given, returns the
readingFrame attribute.

=cut
sub readingFrame
{
  my ($this, $val) = @_;

  if ($val){
    $val = int($val);
    if (($val >= -3) && ($val <= 3)){
      $this->{readingFrame} = $val;
    }
    else{
      croak("Illegal reading frame [$val]");
    }
  }
  return $this->{readingFrame};

} # readingFrame


=head2 nTerm([$val])

NTerm position accessor/modifier.

=cut
sub nTerm
{
  my ($this, $val) = @_;

  if (defined $val){
    $val = int($val);
    if (($val == 0) || ($val == 1)){
      $this->{nTerm} = $val;
    }
    else{
      croak("Illegal value [$val]");
    }
  }
  return $this->{nTerm};

} # nTerm


=head2 cTerm([$val])

CTerm position accessor/modifier.

=cut
sub cTerm
{
  my ($this, $val) = @_;

  if (defined $val){
    $val = int($val);
    if (($val == 0) || ($val == 1)){
      $this->{cTerm} = $val;
    }
    else{
      croak("Illegal value [$val]");
    }
  }
  return $this->{cTerm};

} # cTerm


=head2 addProton([$val])

aaBefore position accessor/modifier.

=cut
sub addProton
{
  my ($this, $val) = @_;

  if (defined $val){
    $val = int($val);
    if (($val == 0) || ($val == 1)){
      $this->{addProton} = $val;
      undef($this->{mass});
    }
    else{
      croak("Illegal value [$val]");
    }
  }
  return $this->{addProton};

} # addProton


=head2 aaBefore([$val])

NTerm position accessor/modifier.

=cut
sub aaBefore
{
  my ($this, $val) = @_;

  if (defined $val){
    if ($aaList{$val}){
      $this->{aaBefore} = $val;
    }
    else{
      warn("[WARNING] Illegal amino acid [$val]");
    }
  }
  return $this->{aaBefore};

} # aaBefore


=head2 aaAfter([$val])

aaAfter accessor/modifier.

=cut
sub aaAfter
{
  my ($this, $val) = @_;

  if (defined $val){
    if ($aaList{$val}){
      $this->{aaAfter} = $val;
    }
    else{
      warn("[WARNING] amino acid [$val]");
    }
  }
  return $this->{aaAfter};

} # aaAfter


=head2 enzymatic([$val])

Enzymatic status accessor/modifier.

=cut
sub enzymatic
{
  my ($this, $val) = @_;

  if (defined $val){
    if (($val eq 'full') || ($val eq 'half-N') || ($val eq 'half-C') || ($val eq 'no')){
      $this->{enzymatic} = $val;
    }
    else{
      croak("Illegal enzymatic status [$val]");
    }
  }
  return $this->{enzymatic};

} # enzymatic


=head2 nmc([$val])

Number of missed cleavages accessor/modifier.

=cut
sub nmc
{
  my ($this, $val) = @_;

  if (defined $val){
    $val = int($val);
    if ($val >= 0){
      $this->{nmc} = $val;
    }
    else{
      croak("Illegal number of missed cleavages [$val]");
    }
  }
  return $this->{nmc};

} # nmc


=head2 modif([$modif])

Modifications accessor/modifier: sets modifications if $modif, a reference to vector of modification
names or a string is given (see Pheny::InSilico::MassCalculator::variablePeptide function for instance),
returns a reference to a vector of modifications. This vector can be converted into a string for
display purpose by the Pheny::InSilico::MassCalculator::modifToString function.

=cut
sub modif

{
  my ($this, $modif) = @_;

  if (defined($modif)){
    if (ref($modif) eq 'ARRAY'){
      $this->{modif} = [@$modif];
      undef($this->{mass});
      $this->{modifType} = ((length($modif->[0]) > 0) && ($modif->[0] eq int($modif->[0]))) ? 'PMF' : 'MS/MS';
    }
    elsif (!ref($modif)){
      $this->{modif} = [split(/:/, $modif)];
      undef($this->{mass});
      $this->{modifType} = 'MS/MS';
    }
    else{
      croak("Invalid modification format [$modif]");
    }
  }
  return $this->{modif};

} # modif


=head2 modifAt($pos, [$modif])

Accessor/modifier for modification at position $pos. Sets the modification if
$modif, a string, is provided.

$pos = 0 is the N-terminal site, $pos = peptide length +1 is the C-terminal site,
and 1 <= $pos <= peptide length correspond to amino acids.

To remove a modification set it to an empty string ''.

This method is for localized modifications in view of MS/MS and forces the modification
type to be MS/MS (clears previous PMF modifications if any).

=cut
sub modifAt
{
  my ($this, $pos, $modif) = @_;

  croak("No sequence defined") if ($this->getLength() == 0);
  $pos = int($pos);
  croak("Invalid position [$pos]") if (($pos < 0) || ($pos > $this->getLength()+1));
  if ($modif){
    if ($this->getModifType() eq 'PMF'){
      $this->{modif} = [];
    }
    $this->{modif}[$pos+1] = $modif;
    $this->{modifType} = 'MS/MS';
    undef($this->{mass});
  }
  return $this->{modif}[$pos+1];

} # modifAt


=head2 addPmfModif($num, $modifName)

Adds a new pair (number of occurence, modification name) to the pmfModif list. This method
is for PMF and it forces the modification type to be PMF (clears previous MS/MS modifications
if any).

=cut
sub addPmfModif
{
  my ($this, $num, $modifName) = @_;

  if ($num && $modifName){
    if ($this->getModifType() eq 'MS/MS'){
      $this->{modif} = [];
    }
    push(@{$this->{pmfModif}}, $num, $modifName);
    $this->{modifType} = 'PMF';
    undef($this->{mass});
  }

} # addPmfModif


=head2 clearModif

Clears modifications.

=cut
sub clearModif
{
  my $this = shift;
  undef($this->{modif});
  undef($this->{mass});
  undef($this->{modifType});

} # clearModif


=head2 getModifType

Returns the modification type ('PMF' or 'MS/MS') or undef if no type is defined, i.e. no
modifications are set.

=cut
sub getModifType
{
  my $this = shift;
  return $this->{modifType};

} # getModifType


=head2 getMass

Returns the peptide mass or undefined in case either the peptide sequence
is not set or there are variable modifications.

=cut
sub getMass
{
  my $this = shift;
  return $this->{mass} if (defined($this->{mass}) && ($this->{massType} == InSilicoSpectro::InSilico::MassCalculator::getMassType()));

  return undef if (!defined(my $sequence = $this->sequence()));

  my @list;
  if ($this->getModifType() eq 'PMF'){
    my $modif = $this->modif();
    for (my $i = 0; $i < @$modif; $i+=2){
      for (my $j = 0; $j < $modif->[$i]; $j++){
	push(@list, $modif->[$i+1]);
      }
    }
  }
  else{
    foreach (@{$this->{modif}}){
      if (length($_) > 0){
	return undef if (index($_, '(*)') != -1);
	push(@list, $_);
      }
    }
  }

  my $termGainMass;
  if (my $enz = $this->enzyme()){
    if ($enz->NTermGain() && !$this->nTerm() && (($this->enzymatic() eq 'full') || ($this->enzymatic() eq 'half-N'))){
      # Not a N-term peptide and peptide N-terminus created by the enzyme
      $termGainMass += (InSilicoSpectro::InSilico::MassCalculator::massFromComposition($enz->NTermGain()))[InSilicoSpectro::InSilico::MassCalculator::getMassType()];
    }
    else{
      # Standard +H rule
      $termGainMass += InSilicoSpectro::InSilico::MassCalculator::getMass('el_H');
    }
    if ($enz->CTermGain() && !$this->cTerm() && (($this->enzymatic() eq 'full') || ($this->enzymatic() eq 'half-C'))){
      # Not a C-term peptide and peptide C-terminus created by the enzyme
      $termGainMass += (InSilicoSpectro::InSilico::MassCalculator::massFromComposition($enz->CTermGain()))[InSilicoSpectro::InSilico::MassCalculator::getMassType()];
    }
    else{
      # Standard +OH rule
      $termGainMass += InSilicoSpectro::InSilico::MassCalculator::getMass('el_H')+InSilicoSpectro::InSilico::MassCalculator::getMass('el_O');
    }
  }

  my $mass = InSilicoSpectro::InSilico::MassCalculator::getPeptideMass(pept=>$sequence, modif=>\@list, termGain=>$termGainMass);
  $mass += InSilicoSpectro::InSilico::MassCalculator::getMass('el_H+') if ($this->addProton());
;
  $this->{mass} = $mass;
  $this->{massType} = InSilicoSpectro::InSilico::MassCalculator::getMassType();
  return $mass;

} # getMass


=head2 getMoZ(charge)


=cut

sub getMoZ
{
  my $this = shift;
  my $charge=shift or croak "must provide a charge for Peptide->getMoZ";
  my $m=$this->getMass();
  $m-=InSilicoSpectro::InSilico::MassCalculator::getMass('el_H+') if ($this->addProton());
  return $m/$charge+InSilicoSpectro::InSilico::MassCalculator::getMass('el_H+');
}

=head2 getLength

Returns peptide sequence length.

=cut
sub getLength
{
  my $this = shift;

  return defined($this->{sequence}) ? length($this->{sequence}) : abs($this->{posEnd}-$this->{posStart})+1;

} # getLength


=head1 I/O

=head2 toString

Returns a string made of the amino acids before and after and the
peptide sequence. Example 'K.ATURPLJK.S'.

=head2 Overloaded "" operator

Returns the string returned by toString.

=head2 print

Prints a complete peptide description.

=cut
use SelectSaver;
use overload '""' => \&toString;
sub toString
{
  my $this = shift;
  return (length($this->aaBefore()) == 1 ? $this->aaBefore().'.' : '').$this->sequence().(length($this->aaAfter()) == 1 ? '.'.$this->aaAfter() : '');
}
sub print
{
  my ($this, $out) = @_;

  my $fdOut = defined($out) ? (new SelectSaver(InSilicoSpectro::Utils::io->getFD($out) || croak("cannot open [$out]: $!"))) : \*STDOUT;
  print $fdOut $this->toString(), "\n";
  print $fdOut "".(InSilicoSpectro::InSilico::MassCalculator::modifToString($this->modif()))."\n" if (defined($this->modif()));
  print $fdOut $this->nmc(), " missed cleavage(s)\n" if (defined($this->nmc()));
  print $fdOut "Starts at ", $this->start(), "\n" if (defined($this->start()));
  print $fdOut "Ends at ", $this->end(), "\n" if (defined($this->end()));
  print $fdOut "C-terminal peptide\n" if ($this->cTerm());
  print $fdOut "N-terminal peptide\n" if ($this->nTerm());
  print $fdOut "Enzymatic: ", $this->enzymatic(), "\n" if ($this->enzymatic());
  my $massType = InSilicoSpectro::InSilico::MassCalculator::getMassType();
  InSilicoSpectro::InSilico::MassCalculator::setMassType(0);
  print $fdOut "Monoisotopic mass=", $this->getMass();
  InSilicoSpectro::InSilico::MassCalculator::setMassType(1);
  print $fdOut " Da, average mass=", $this->getMass(), " Da\n";
  InSilicoSpectro::InSilico::MassCalculator::setMassType($massType);
}


=head1 EXAMPLES

See t/InSilico/testPeptide.pl and t/InSilico/testCalcDigestOOP.pl.

=head1 AUTHORS

Jacques Colinge, Upper Austria University of Applied Science at Hagenberg

Alexandre Masselot, www.genebio.com

=cut
