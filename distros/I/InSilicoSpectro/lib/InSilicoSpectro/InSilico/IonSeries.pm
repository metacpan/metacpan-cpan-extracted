package  InSilicoSpectro::InSilico::IonSeries;

# Mass spectrometry Perl module for representing fragment ions

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

use strict;
use Carp;
require Exporter;

our (@ISA, @EXPORT, @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = ();

our %visibleAttr = (ionType=>1, charge=>1, masses=>1, names=>1, massType=>1, matches=>1, massIndex=>1, intensityIndex=>1);

return 1;

=head1 NAME

IonSeries - Perl class to represent fragment ion series.

=head1 SYNOPSIS

use InSilicoSpectro::InSilico::IonSeries

=head1 DESCRIPTION

IonSeries class is intended to provide a basic class aimed at representing an entire
series of fragment ions. By series we mean all the b++ ions, all the y-2(H2O)-NH3 ions,
or all the immonium ions for instance.

ALthough needs may vary (display, further computations, scoring, etc.), we believe that
to group fragment ions in series is both convenient (no too many objects created like
if we would create one object per fragment) and flexible (one can focus on a specific
ion type).

In addition to only represent theoretical masses, IonSeries objects have one attribute
to point to an experimental peak in case theoretical masses are metched with an experimental
spectrum.

=head1 ATTRIBUTES

=over 4

=item ionType

The name of the fragment ions in the objects, e.g. b, c, y++, a++-2(NH3), immo.

=item charge

The charge state.

=item masses

A reference to a vector that contains all the m/z values of the fragments ion of the series.
Masses that are not possibles (loss, too short or too long fragment) are indicated by undef
values, i.e. the vector referenced by masses always has the peptide length.

=item massType

A value that indicates whether the masses are monoisotopic masses (0) or average masses (1).

=item names

A reference to a vector that contains the names of the fragments. For a terminal ion series it
simply the numbers of the fragments 1, 2, ..., n; and for an internal ion series it is a list of the
fragment sequences. See masses concerning the vector length and impossible masses.

=item matchedPeak

A reference to a vector describing an experimental peak (see class InSilicoSpectro::Spectra::ExpSpectrum).
This attribute is used in case of match with an experimental spectrum only.

=item massIndex

The index for getting the mass from the matched peaks.

=item intensityIndex

The index for getting the intensity from the matched peaks.

=back

=head1 METHODS

=head2 new([%h|$IonSeries])

Constructor. %h is a hash of attribute=>value pairs, $IonSeries is a
InSilicoSpectro::InSilico::IonSeries object, from which the attributes are copied.

=cut
sub new
{
  my $pkg = shift;

  my $is = {};
  my $class = ref($pkg) || $pkg;
  bless($is, $class);

  if (ref($_[0]) && $_[0]->isa('InSilicoSpectro::InSilico::IonSeries')){
    %$is = %{$_[0]};
    bless($is, $class);
  }
  else{
    bless($is, $class);
    if (!ref($_[0])){
      my %h = @_;
      foreach (keys(%h)){
	$is->$_($h{$_}) if ($visibleAttr{$_});
      }
    }
  }
  return $is;

} # new


=head2 ionType([$it])

Accessor/modifier of the attribute ionType.

=cut
sub ionType
{
  my ($this, $it) = @_;

  if (defined($it)){
    $this->{ionType} = $it;
  }
  return $this->{ionType};

} # ionType


=head2 matches([$it])

Accessor/modifier of the attribute matches.

=cut
sub matches
{
  my ($this, $mp) = @_;

  if (defined($mp)){
    if (ref($mp) eq 'ARRAY'){
      $this->{matches} = $mp;
    }
    else{
      croak("Illegal type for matches [$mp]");
    }
  }
  return $this->{matches};

} # matches


=head2 charge([$z])

Accessor/modifier of the attribute charge.

=cut
sub charge
{
  my ($this, $z) = @_;

  if (defined($z)){
    $z = int($z);
    if ($z > 0){
      $this->{charge} = $z;
    }
    else{
      croak("Invalid charge value [$z]");
    }
  }
  return $this->{charge};

} # charge


=head2 massIndex([$z])

Accessor/modifier of the attribute massIndex.

=cut
sub massIndex
{
  my ($this, $ind) = @_;

  if (defined($ind)){
    $ind = int($ind);
    if ($ind >= 0){
      $this->{massIndex} = $ind;
    }
    else{
      croak("Invalid massIndex value [$ind]");
    }
  }
  return $this->{massIndex};

} # massIndex


=head2 intensityIndex([$z])

Accessor/modifier of the attribute intensityIndex.

=cut
sub intensityIndex
{
  my ($this, $ind) = @_;

  if (defined($ind)){
    $ind = int($ind);
    if ($ind >= 0){
      $this->{intensityIndex} = $ind;
    }
    else{
      croak("Invalid intensityIndex value [$ind]");
    }
  }
  return $this->{intensityIndex};

} # intensityIndex


=head2 massType([$mt])

Accessor/modifier of the attribute massType.

=cut
sub massType
{
  my ($this, $mt) = @_;

  if (defined($mt)){
    $mt = int($mt);
    if (($mt == 0) || ($mt == 1)){
      $this->{massType} = $mt;
    }
    else{
      croak("Invalid massType value [$mt]");
    }
  }
  return $this->{massType};

} # massType


=head2 masses([$m])

Accessor/modifier of the attribute masses.

=cut
sub masses
{
  my ($this, $m) = @_;

  if (defined($m)){
    if (ref($m) eq 'ARRAY'){
      $this->{masses} = $m;
    }
    else{
      croak("Invalid masses type [$m]");
    }
  }
  return $this->{masses};

} # masses


=head2 names([$n])

Accessor/modifier of the attribute names.

=cut
sub names
{
  my ($this, $n) = @_;

  if (defined($n)){
    if (ref($n) eq 'ARRAY'){
      $this->{names} = $n;
    }
    else{
      croak("Invalid names type [$n]");
    }
  }
  return $this->{names};

} # names


=head2 toString

Returns a string containing the list of fragments with their m/z values.

=head2 Overloaded "" operator

Returns what is returned by toString.

=cut
use overload '""' => \&toString;
sub toString
{
  my $this = shift;

  my $string = $this->ionType().": ";
  my @names = @{$this->names()};
  my @masses = @{$this->masses()};
  my @matches = defined($this->matches()) ? @{$this->matches()} : ();
  for (my $i = 0; $i < @masses; $i++){
    if (defined($names[$i])){
      $string .= $names[$i].':'.$masses[$i];
      if (defined($matches[$i])){
	$string .= "-match($matches[$i][0])";
      }
      $string .= "\t";
    }
  }
  $string .= '(z='.$this->charge().', '.($this->massType()==0 ? 'mono' : 'avg').')';
  return $string;

} # toString



=head1 EXAMPLES

See t/InSilico/testCalcFragOOP.pl.

=head1 AUTHORS

Jacques Colinge, Upper Austria University of Applied Science at Hagenberg

=cut
