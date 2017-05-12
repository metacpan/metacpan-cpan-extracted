package InSilicoSpectro::Spectra::ExpSpectrum;

=head1 NAME

InSilicoSpectro::Spectra::ExpSpectrum - A class for representing spectra.

=head1 SYNOPSIS

use InSilicoSpectro::Spectra::ExpSpectrum;

=head1 DESCRIPTION

This class role is to model mass spectra.

=head1 METHODS


=head1 METHODS

=head2 my $sp=new(%h|$ExpSpectrum)

Constructor. %h is a hash of attribute=>value pairs, $ExpSpectrum is a
InSilicoSpectro::Spectra::ExpSpectrum object, from which the attributes are copied.

=head2 $sp->peakDescriptor([$pd])

An object of class InSilicoSpectro::Spectra::PeakDescriptor that defines the index of each
experimental peak property such as mass, intensity, s/n, etc.

=head2 $sp->spectrum([\@array]);

Accessor and modifier for the experimental spectrum. The spectrum is a reference to
a vector of references to vectors containing peak properties (see function
InSilicoSpectro::InSilico::PMFMatch).

The experimental spectrum itself. It is part of the design of this class to impose
a data structure for the spectrum and make it visible (no accessors/modifiers).

The data structure is a vector of references to vectors corresponding
to the experimental peaks in the experimental spectrum. The attribute spectrum
is a reference to the experimental spectrum:
a structure like

  spectrum->[0] -> (mass, intensity, s/n, ...) for peak 1
  spectrum->[1] -> (mass, intensity, s/n, ...) for peak 2
  spectrum->[2] -> (mass, intensity, s/n, ...) for peak 3
  ...

The actual order of the peak properties is given by the PeakDescriptor object pointed by
the attribute peakDescriptor.

=head2 $sp->size();

Return the size of the spectrum

=head2 toString

Converts the spectrum into a string with eol characters between peaks and at the end of the
last line. Properties of a peak are separated by a tab character.

=head2 Overloaded "" operator

Returns the result of toString.

=head1 COPYRIGHT

Copyright (C) 2004-2006  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

Jacques Colinge

=cut

use strict;
require Exporter;
use Carp;


our (@ISA, @EXPORT, @EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT = qw();
@EXPORT_OK = ();

our %visibleAttr = (peakDescriptor=>1, spectrum=>1);


sub new
{
  my $pkg = shift;

  my $spec={};
  my $class = ref($pkg) || $pkg;
  bless($spec, $class);

  if (ref($_[0]) && $_[0]->isa('InSilicoSpectro::Spectra::ExpSpectrum')){
    %$spec = %{$_[0]};
    bless($spec, $class);
  }
  else{
    bless($spec, $class);
    if (!ref($_[0])){
      my %h = @_;
      foreach (keys(%h)){
	$spec->$_($h{$_}) if ($visibleAttr{$_});
      }
    }
  }
  return $spec;

} # new


sub peakDescriptor
{
  my ($this, $pd) = @_;

  if (ref($pd) && $pd->isa('InSilicoSpectro::Spectra::PeakDescriptor')){
    $this->{peakDescriptor} = $pd;
  }

  return $this->{peakDescriptor};

} # peakDescriptor



sub spectrum
{
  my ($this, $sp) = @_;

  if (ref($sp) eq 'ARRAY'){
    #if (ref($sp->[0]) eq 'ARRAY'){
      $this->{spectrum} = $sp;
    #}
    #else{
    #  croak __FILE__."(".__LINE__."): Illegal data structure for the experimental spectrum";
    #}
  }

  return $this->{spectrum};

} # spectrum


sub size{
  my $this=shift;
  return undef unless defined $this->spectrum;
  return scalar @{$this->spectrum};
}

use overload '""' => \&toString;
sub toString{
  my $this = shift;
  my $string;
  if($this->spectrum()){
    my @spectrum = @{$this->spectrum()};
    foreach (@spectrum){
      next unless ref($_) eq 'ARRAY^';
      $string .= join("\t", @$_)."\n";
    }
  }
  return $string;
}


return 1;
