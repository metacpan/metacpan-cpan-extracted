#!/usr/bin/perl


# Test program for Perl classes Spectrum and PeakDescriptor
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
#  http://www.fhs-hagenberg.ac.at


=head1 testSpectrum.pl

=cut

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}

use strict;
use Carp;
use InSilicoSpectro::Spectra::ExpSpectrum;
use InSilicoSpectro::Spectra::PeakDescriptor;

eval{
  # Test 1, reads from a pkl file and creates a ExpSpectrum object
  my @spectrum;
  open(P, '../InSilico/meuh.pkl');
  while (<P>){
    chomp;
    my ($mass, $height) = split(/[\s,]+/);
    push(@spectrum, [$mass, $height]);
  }
  close(P);

  my $pd = new InSilicoSpectro::Spectra::PeakDescriptor(['mass', 'intensity']);
  my $spectrum = new InSilicoSpectro::Spectra::ExpSpectrum(spectrum=>\@spectrum, peakDescriptor=>$pd);
  print "$pd\n$spectrum";
};
if ($@){
  carp($@);
}

