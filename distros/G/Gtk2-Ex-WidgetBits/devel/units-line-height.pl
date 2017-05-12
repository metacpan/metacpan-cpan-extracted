#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
BEGIN { $ENV{'DISPLAY'} ||= ':0' }
use Gtk2 '-init';
use Gtk2::Pango 'PANGO_SCALE';
use Gtk2::Ex::Units;

my $toplevel = Gtk2::Window->new ('toplevel');

my $layout = $toplevel->create_pango_layout ('');
$layout->set_spacing (100 * PANGO_SCALE);
print "layout spacing=",$layout->get_spacing,"\n";

my $context  = $layout->get_context;
my $fontdesc = ($layout->get_font_description
                || $context->get_font_description);
my $lang = $context->get_language;
my $metrics = $context->get_metrics ($fontdesc, $lang);

print "ascent=",$metrics->get_ascent/PANGO_SCALE," descent=",$metrics->get_descent/PANGO_SCALE,"\n";

foreach my $i (0 .. 4) {
  my $str = join ("\n", ('X') x $i) . "\n";
  $layout->set_text ($str);
  my ($ink, $logical) = $layout->get_extents;
  print "str '$str'",
    "  ink ",$ink->{'width'}/PANGO_SCALE,"x",$ink->{'height'}/PANGO_SCALE,
    "  logical ",$logical->{'width'}/PANGO_SCALE,"x",$logical->{'height'}/PANGO_SCALE,
      "\n";
}

exit 0;
