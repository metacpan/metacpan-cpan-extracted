package  InSilicoSpectro::InSilico::InternIonSeries;

# Mass spectrometry Perl module for representing internal fragment ions

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

our %visibleAttr = ();

return 1;

=head1 NAME

InternIonSeries - Perl class to represent internal fragment ion series.

=head1 SYNOPSIS

use InSilicoSpectro::InSilico::InternIonSeries

=head1 DESCRIPTION

For the time being this class is simply inherited from IonSeries without adding
any new method. It is just here to have a dedicated object for internal ions such
that we can identify them by call the method isa.

=head1 METHODS

=head2 new([%h|$InternIonSeries])

Constructor. %h is a hash of attribute=>value pairs, $IonSeries is a
InSilicoSpectro::InSilico::IonSeries object, from which the attributes are copied.

=cut
sub new
{
  my $pkg = shift;

  my $iis;
  my $class = ref($pkg) || $pkg;

  if (ref($_[0]) && $_[0]->isa('InSilicoSpectro::InSilico::IonSeries')){
    $iis = new InSilicoSpectro::InSilico::IonSeries(@_);
    bless($iis, $class);
  }
  elsif (ref($_[0]) && $_[0]->isa('InSilicoSpectro::InSilico::InternIonSeries')){
    $iis = {};
    %$iis = %{$_[0]};
    bless($iis, $class);
  }
  else{
    $iis = new InSilicoSpectro::InSilico::IonSeries(@_);
    bless($iis, $class);
    if (!ref($_[0])){
      my %h = @_;
      foreach (keys(%h)){
	$iis->$_($h{$_}) if ($visibleAttr{$_});
      }
    }
  }
  return $iis;

} # new



=head1 EXAMPLES

See t/InSilico/testCalcFragOOP.pl.

=head1 AUTHORS

Jacques Colinge, Upper Austria University of Applied Science at Hagenberg

=cut
