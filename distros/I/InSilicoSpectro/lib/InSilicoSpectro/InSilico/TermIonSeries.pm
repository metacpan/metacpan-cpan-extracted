package  InSilicoSpectro::InSilico::TermIonSeries;

# Mass spectrometry Perl module for representing N-/C-terminal fragment ions

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
use InSilicoSpectro::InSilico::IonSeries;

our (@ISA, @EXPORT, @EXPORT_OK);
@ISA = qw(Exporter InSilicoSpectro::InSilico::IonSeries);
@EXPORT = qw();
@EXPORT_OK = ();

our %visibleAttr = (series=>1, terminus=>1);

return 1;

=head1 NAME

TermIonSeries - Perl class to represent N-/C-terminal fragment ion series.

=head1 SYNOPSIS

use InSilicoSpectro::InSilico::TermIonSeries

=head1 DESCRIPTION

This class inherits from IonSeries and just adds two new attributes for keeping track of
the orientation and the series (a,b,c,x,y,z).

=head1 ATTRIBUTES

=head2 series

The generic series for these ions, i.e. the generic series for y++ and y-NH3 is y.

=head2 terminus

Equals 'C' or 'N';

=head1 METHODS

=head2 new([%h|$TermIonSeries])

Constructor. %h is a hash of attribute=>value pairs, $TermIonSeries is a
InSilicoSpectro::InSilico::TermIonSeries object, from which the attributes are copied.

=cut
sub new
{
  my $pkg = shift;

  my $tis;
  my $class = ref($pkg) || $pkg;

  if (ref($_[0]) && $_[0]->isa('InSilicoSpectro::InSilico::TermIonSeries')){
    $tis = {};
    %$tis = %{$_[0]};
    bless($tis, $class);
  }
  else{
    $tis = new InSilicoSpectro::InSilico::IonSeries(@_);
    bless($tis, $class);
    if (!ref($_[0])){
      my %h = @_;
      foreach (keys(%h)){
	$tis->$_($h{$_}) if ($visibleAttr{$_});
      }
    }
  }
  return $tis;

} # new


=head2 series([$s])

Accessor/modifier of the attribute series.

=cut
sub series
{
  my ($this, $s) = @_;

  if (defined($s)){
    $this->{series} = $s;
  }
  return $this->{series};

} # series


=head2 terminus([$s])

Accessor/modifier of the attribute terminus.

=cut
sub terminus
{
  my ($this, $t) = @_;

  if (defined($t)){
    $t = uc($t);
    if (($t eq 'C') || ($t eq 'N')){
      $this->{terminus} = $t;
    }
    else{
      croak("Illegal value for terminus [$t]");
    }
  }
  return $this->{terminus};

} # terminus


=head1 EXAMPLES

See t/InSilico/testCalcFragOOP.pl.

=head1 AUTHORS

Jacques Colinge, Upper Austria University of Applied Science at Hagenberg

=cut
