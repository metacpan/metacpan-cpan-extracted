#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-NumAxis.
#
# Gtk2-Ex-NumAxis is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-NumAxis is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NumAxis.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

{
  require Locale::Currency::Format;
  print Locale::Currency::Format::currency_format('USD', 11123456.789),"\n";
  print Locale::Currency::Format::currency_format('USD', 11123456.789,
                                                  Locale::Currency::Format::FMT_SYMBOL()),"\n";
  exit 0;
}
{
  require PAB3::Utils;
  PAB3::Utils::set_locale ('en_AU');
  print PAB3::Utils::strfmon("%n\n", 123.4567);
  print PAB3::Utils::strfmon("%i\n", 123999.4567);
  exit 0;
}

