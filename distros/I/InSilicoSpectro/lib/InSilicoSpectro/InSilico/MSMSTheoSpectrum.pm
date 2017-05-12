package  InSilicoSpectro::InSilico::MSMSTheoSpectrum;

# Mass spectrometry Perl module for representing theoretical MS/MS spectra

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
@EXPORT = qw();
@EXPORT_OK = ();

use strict;
use Carp;
use InSilicoSpectro::InSilico::MassCalculator;
use InSilicoSpectro::InSilico::MSMSOutput;
use InSilicoSpectro::InSilico::Peptide;
use InSilicoSpectro::Spectra::ExpSpectrum;
use InSilicoSpectro::InSilico::TermIonSeries;
use InSilicoSpectro::InSilico::InternIonSeries;

our %visibleAttr = (theoSpectrum=>1, massType=>1, tol=>1, minTol=>1);


return 1;

=head1 NAME

MSMSTheoSPectrum - Perl class to represent MS/MS theoretical spectra

=head1 SYNOPSIS

use InSilicoSpectro::InSilico::MSMSTheoSpectrum;

=head1 DESCRIPTION

MSMSTheoSpectrum class is an object that simplifies the access to the data contained in the data structure
returned by function InSilicoSpectro::InSilico::MassCalculator::getFragmentMasses.

Note that there is no analogous class for PMF spectra because the theoretical spectrum in this case is simply
the vector of Peptide objects returned by the digestion functions. To define an object to wrap such a simple
data structure would be overdue.

=head1 ATTRIBUTES

=over 4

=item theoSpectrum

A reference to the data structure returned by the function InSilicoSpectro::InSilico::MassCalculator::getFragmentMasses.

=item massType

Monoisotopic (0) or average (1) masses.

=item tol

Relative mass error tolerance. Useful for displaying matches with a different tolerance than
the one used by the MassCalculator match functions.

=item minTol

Absolute mass error tolerance. Useful for displaying matches with a different tolerance than
the one used by the MassCalculator match functions.

=back

=head1 METHODS

=head2 new([%h|$MSMSTheoSpectrum])

Constructor. %h is a hash of attribute=>value pairs, $MSMSTheoSpectrum is a
InSilicoSpectro::InSilico::MSMSTheoSpectrum object, from which the attributes are copied.

Example:

  getFragmentMasses(pept=>$peptide, fragTypes=>['b','a','b-H2O*-NH3*','b++','y','y-H2O*-NH3*','y++','immo'], spectrum=>\%spectrum);
  my $theoSpectrum = new InSilicoSpectro::InSilico::MSMSTheoSpectrum(theoSpectrum=>\%spectrum, massType=>getMassType());

=cut
sub new
{
  my $pkg = shift;

  my $tsp = {};
  my $class = ref($pkg) || $pkg;
  bless($tsp, $class);

  if (ref($_[0]) && $_[0]->isa('InSilicoSpectro::InSilico::MSMSTheoSpectrum')){
    %$tsp = %{$_[0]};
    bless($tsp, $class);
  }
  else{
    bless($tsp, $class);
    if (!ref($_[0])){
      my %h = @_;
      foreach (keys(%h)){
	$tsp->$_($h{$_}) if ($visibleAttr{$_});
      }
    }
  }
  return $tsp;

} # new


=head2 theoSpectrum([$theoSpectrum])

Acessor/modifier of attribute theoSpectrum.

=cut
sub theoSpectrum
{
  my $this = shift;

  if (defined($_[0])){
    if (ref($_[0]) eq 'HASH'){
      $this->{theoSpectrum} = $_[0];
      my $peptide = $this->{theoSpectrum}{peptide};
      if (ref($peptide) && $peptide->isa('InSilicoSpectro::InSilico::Peptide')){
	$this->{peptideLength} = length($peptide->sequence());
      }
      else{
	$this->{peptideLength} = length($peptide);
      }
    }
    else{
      croak("Illegal data type for theoSpectrum");
    }
  }
  return $this->{theoSpectrum};

} # theoSpectrum


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


=head2 tol([$mt])

Accessor/modifier of the attribute tol.

=cut
sub tol
{
  my ($this, $mt) = @_;

  if (defined($mt)){
    $this->{tol} = $mt;
  }
  return $this->{tol};

} # tol


=head2 minTol([$mt])

Accessor/modifier of the attribute minTol.

=cut
sub minTol
{
  my ($this, $mt) = @_;

  if (defined($mt)){
    $this->{minTol} = $mt;
  }
  return $this->{minTol};

} # minTol


=head2 getPeptide

Returns the peptide sequence or the Peptide object stored in the data structure produced
by getFragmentMasses.

=cut
sub getPeptide
{
  my $this = shift;
  return $this->theoSpectrum()->{peptide};

} # getPeptide


=head2 getPeptideLength

Returns the length of the fragmented peptide.

=cut
sub getPeptideLength
{
  my $this = shift;
  return $this->{peptideLength};

} # getPeptide Length


=head2 getModif

Returns a reference to the vector of modifications used for the theoretical masses
computation.

=cut
sub getModif
{
  my $this = shift;
  return $this->theoSpectrum()->{modif};

} # getModif


=head2 getPeptideMass

Returns the peptide mass.

=cut
sub getPeptideMass
{
  my $this = shift;
  return $this->theoSpectrum()->{peptideMass};

} # getPeptideMass


=head2 getTermIons

Returns a vector containing all the terminal ion series sorted with respect to their name
by the function InSilicoSpectro::InSilico::MSMSOutput::cmpFragTypes.

=cut
sub getTermIons
{
  my $this = shift;

  my $tol = $this->tol();
  my $minTol = $this->minTol() || 0.2;
  my @termIons;
  my $len = length($this->getPeptide());
  my $names = [(1..$len)];
  my %spectrum = %{$this->{theoSpectrum}};
  my $massIndex = $spectrum{intensityIndex};
  foreach my $frag (keys(%{$spectrum{mass}{term}})){
    for (my $i = 0; $i < @{$spectrum{ionType}{$frag}}; $i++){
      my ($series, $charge) = (InSilicoSpectro::InSilico::MassCalculator::getFragType($frag))[0,1];
      my $terminus = (InSilicoSpectro::InSilico::MassCalculator::getSeries($series))[0];
      my $ionType = $spectrum{ionType}{$frag}[$i];
      my (@masses, @matches);
      for (my $j = $i*$len; $j < ($i+1)*$len; $j++){
	push(@masses, $spectrum{mass}{term}{$frag}[$j]);
	if (defined($spectrum{match}{term}{$frag}[$j])){
	  if (defined($tol)){
	    my $theoMass = $spectrum{mass}{term}{$frag}[$j];
	    my $expMass = $spectrum{match}{term}{$frag}[$j][$massIndex];
	    my $error = $expMass-$theoMass;
	    if ((abs($error)/($theoMass+$expMass)*2e+6 <= $tol) || (abs($error) <= $minTol)){
	      push(@matches, $spectrum{match}{term}{$frag}[$j]);
	    }
	    else{
	      push(@matches, undef);
	    }
	  }
	  else{
	    push(@matches, $spectrum{match}{term}{$frag}[$j]);
	  }
	}
	else{
	  push(@matches, undef);
	}
      }
      push(@termIons, new InSilicoSpectro::InSilico::TermIonSeries(ionType=>$ionType, charge=>$charge, series=>$series, terminus=>$terminus, names=>$names, masses=>[@masses], massType=>$this->massType(), intensityIndex=>$spectrum{intensityIndex}, massIndex=>$massIndex, matches=>(defined($spectrum{match}) ? [@matches] : undef)));
    }
  }

  @termIons = sort {InSilicoSpectro::InSilico::MSMSOutput::cmpFragTypes($a->ionType(), $b->ionType())} @termIons;
  return @termIons;

} # getTermIons


=head2 getInternIons

Returns a vector containing all the internal ion series sorted with respect to their name
by the function InSilicoSpectro::InSilico::MSMSOutput::cmpFragTypes.

=cut
sub getInternIons
{
  my $this = shift;

  my $tol = $this->tol();
  my $minTol = $this->minTol() || 0.2;
  my @internIons;
  my %spectrum = %{$this->{theoSpectrum}};
  my $massIndex = $spectrum{intensityIndex};
  foreach my $frag (keys(%{$spectrum{mass}{intern}})){
    my $ionType =  $spectrum{ionType}{$frag}[0];
    my (@masses, @names, @matches);
    foreach my $aa (sort keys(%{$spectrum{mass}{intern}{$frag}})){
      push(@names, $aa);
      push(@masses, $spectrum{mass}{intern}{$frag}{$aa});
      if (defined($spectrum{match}{intern}{$frag}{$aa})){
	if (defined($tol)){
	  my $theoMass = $spectrum{mass}{intern}{$frag}{$aa};
	  my $expMass = $spectrum{match}{intern}{$frag}{$aa}[$massIndex];
	  my $error = $expMass-$theoMass;
	  if ((abs($error)/($theoMass+$expMass)*2e+6 <= $tol) || (abs($error) <= $minTol)){
	    push(@matches, $spectrum{match}{intern}{$frag}{$aa});
	  }
	  else{
	    push(@matches, undef);
	  }
	}
	else{
	  push(@matches, $spectrum{match}{intern}{$frag}{$aa});
	}
      }
      else{
	push(@matches, undef);
      }
    }
    push(@internIons, new InSilicoSpectro::InSilico::InternIonSeries(ionType=>$ionType, charge=>1, names=>[@names], masses=>[@masses], massType=>$this->massType(), massIndex=>$massIndex, intensityIndex=>$spectrum{intensityIndex}, matches=>(defined($spectrum{match}) ? [@matches] : undef)));
  }

  @internIons = sort {InSilicoSpectro::InSilico::MSMSOutput::cmpFragTypes($a->ionType(), $b->ionType())} @internIons;
  return @internIons;

} # getInternIons


=head1 EXAMPLES

See t/InSilico/testCalcFragOOP.pl.

=head1 AUTHORS

Jacques Colinge, Upper Austria University of Applied Science at Hagenberg

=cut
