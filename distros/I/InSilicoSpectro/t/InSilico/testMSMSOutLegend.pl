#!/usr/bin/perl

# Test program for Perl module MSMSOutput.pm
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


BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
}

use strict;
use Carp;
use InSilicoSpectro::InSilico::MSMSOutput;

eval{
  plotLegendOnly(fname=>'test2', intSel=>'original', format=>'png', fontChoice=>'default:Large');
#  plotLegendOnly(fname=>'test2', intSel=>'order', format=>'png', fontChoice=>'/usr/lib/jvm/java-1.4.2-sun-1.4.2.05/jre/lib/fonts/LucidaTypewriterRegular.ttf:18');
#  plotLegendOnly(fname=>'test2', intSel=>'original', format=>'png', fontChoice=>'/usr/X11R6/lib/X11/fonts/truetype/luximri.ttf:18');
};
if ($@){
  carp($@);
}
