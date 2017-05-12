package InSilicoSpectro::InSilico::AASequence;

# Perl object class for protein sequences

#Copyright (C) 2005 Alexandre Masselot and Jacques Colinge

#This library is free software; you can redistribute it and/or
#modify it under the terms of the GNU Lesser General Public
#License as published by the Free Software Foundation; either
#version 2.1 of the License, or (at your option) any later version.

#This library is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#Lesser General Public License for more details.

#You should have received a copy of the GNU Lesser General Public
#License along with this library; if not, write to the Free Software
#Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use strict;
require Exporter;
use Carp;
use InSilicoSpectro::Utils::io;
use InSilicoSpectro::InSilico::Sequence;
use InSilicoSpectro::InSilico::MassCalculator;


our (@ISA, @EXPORT, @EXPORT_OK, $isBioPerl);
@ISA = qw(InSilicoSpectro::InSilico::Sequence);

@EXPORT = qw($qrValidAASeq);
@EXPORT_OK = ();

# Visible attributes controled vocabulary
our %visibleAttr = (readingFrame=>1, modif=>1);

our $qrValidAASeq=qr/^[ACDEFGHIJKLMNOPQRSTUVWY]*$/;

return 1;

=head1 NAME

InSilicoSpectro::InSilico::AASequence - Elementary protein sequence.

=head1 SYNOPSIS

use InSilicoSpectro::InSilico::AASequence;

=head1 DESCRIPTION

Inherits from InSilicoSpectro::InSilico::Sequence. The AASequence class is
intended to store protein sequence data.

=head1 ATTRIBUTES

=over 4

=item readingFrame

Set to -3, -2, -1, 1, 2, or 3 in case the sequence was obtained by RNA/DNA
translation.

=item

=back

=head1 METHODS

=head2 new([%h|$bpSeq|$Sequence|$AASequence])

Constructor. %h is a hash of attribute=>value pairs, $bpSeq is a
BioPerl Bio::seq object, from which the attributes are copied,
$Sequence and $AASequence are InSilicoSpectro::InSilico::Sequence and
InSilicoSpectro::InSilico::AASequence respectively.

=cut
sub new
{
  my $pkg = shift;

  my $class = ref($pkg) || $pkg;
  my $seq;

  if (ref($_[0]) && $_[0]->isa('InSilicoSpectro::InSilico::AASequence')){
    $seq = {};
    %$seq = %{$_[0]};
    bless($seq, $class);
  }
  elsif (ref($_[0]) && $_[0]->isa('InSilicoSpectro::InSilico::Sequence')){
    $seq = new InSilicoSpectro::InSilico::Sequence($_[0]);
    bless($seq, $class);
  }
  else{
    $seq = new InSilicoSpectro::InSilico::Sequence(@_);
    bless($seq, $class);
    if (!ref($_[0])){
      my %h = @_;
      foreach (keys(%h)){
	$seq->$_($h{$_}) if ($visibleAttr{$_});
      }
    }
  }
  return $seq;

} # new


=head2 sequence([$val])

sequence accessor/modifier: sets sequence attribute if $val is given, returns the sequence attribute.

=cut
sub sequence
{
  my $this = shift;

  undef($this->{mass});
  return $this->SUPER::sequence(@_);

} # sequence


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
    }
    elsif (!ref($modif)){
      $this->{modif} = [split(/:/, $modif)];
      undef($this->{mass});
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

$pos = 0 is the N-terminal site, $pos = protein length +1 is the C-terminal site,
and 1 <= $pos <= protein length correspond to amino acids.

To remove a modification set it to an empty string ''.

=cut
sub modifAt
{
  my ($this, $pos, $modif) = @_;

  croak("No sequence defined") if ($this->getLength() == 0);
  $pos = int($pos);
  croak("Invalid position [$pos]") if (($pos < 0) || ($pos > $this->getLength()+1));
  if ($modif){
    $this->{modif}[$pos] = $modif;
    undef($this->{mass});
  }
  return $this->{modif}[$pos] = $modif;

} # modifAt


=head2 getMass

Returns the protein mass or undefined in case either the protein sequence
is not set or there are variable modifications.

=cut
sub getMass
{
  my $this = shift;

  return $this->{mass} if (defined($this->{mass}) && ($this->{massType} == InSilicoSpectro::InSilico::MassCalculator::getMassType()));

  return undef if (!defined($this->{sequence}));

  my @list;
  foreach (@{$this->{modif}}){
    if (length($_) > 0){
      return undef if (index($_, '(*)') != -1);
      push(@list, $_);
    }
  }

  my $mass = InSilicoSpectro::InSilico::MassCalculator::getPeptideMass(pept=>$this->{sequence}, modif=>\@list);
;
  $this->{mass} = $mass;
  $this->{massType} = InSilicoSpectro::InSilico::MassCalculator::getMassType();
  return $mass;

} # getMass


=head1 EXAMPLES

See t/InSilico/testAASequence.pl.

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

Jacques Colinge, Upper Austria University of Applied Science at Hagenberg

=cut

