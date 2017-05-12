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
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Units;

my $toplevel = Gtk2::Window->new;
#my $widget = Gtk2::DrawingArea->new;
my $widget = Gtk2::Label->new;
$toplevel->add ($widget);

my $layout = $widget->create_pango_layout ('');
my $context  = $layout->get_context;
my $fontdesc = ($layout->get_font_description
                || $context->get_font_description);
print "fontdesc '",$fontdesc->to_string,"'\n";
my $lang = $context->get_language;
print "lang '",$lang->to_string,"'\n";
my $metrics = $context->get_metrics ($fontdesc, $context->get_language);

my $approx_char_width = ($metrics->get_approximate_char_width
                         / Gtk2::Pango::PANGO_SCALE());

say "charw $approx_char_width";
say "ex    ", Gtk2::Ex::Units::height($widget, '1 ex');
say "line  ", Gtk2::Ex::Units::height($widget, '1 line');
say "em    ", Gtk2::Ex::Units::width ($widget, '1 em');
#say "emh   ", Gtk2::Ex::Units::height($widget, '1 em');
say "sw    ", Gtk2::Ex::Units::width($widget, '1 screen');
say "sh    ", Gtk2::Ex::Units::height($widget, '1 screen');
say "dw    ", Gtk2::Ex::Units::width($widget, '1 digit');
say "mmw   ", Gtk2::Ex::Units::width ($widget, '1mm');
say "mmh   ", Gtk2::Ex::Units::height($widget, '1mm');
say "inw   ", Gtk2::Ex::Units::width ($widget, '1inch');
say "inh   ", Gtk2::Ex::Units::height($widget, '1inch');
say "mmw   ", Gtk2::Ex::Units::_mm_width ($widget);
say "mmh   ", Gtk2::Ex::Units::_mm_height($widget);
say "inw   ", Gtk2::Ex::Units::_inch_width ($widget);
say "inh   ", Gtk2::Ex::Units::_inch_height($widget);

{
  my $target = $widget->create_pango_layout('');
   $target->set_spacing(100 * Gtk2::Pango::PANGO_SCALE());

  foreach my $str ('4', '9',
                   "0\n1\n2\n3\n4\n5\n6\n7\n8\n9",
                   'a', 'aa',
                   "n\nn", "\n", "",
                  ) {
    require Data::Dumper;
    my $print = Data::Dumper->new([$str],['str'])->Useqq(1)->Indent(0)->Dump;

    my $rect = Gtk2::Ex::Units::_pango_rect($target,$str);
    say "$print ink  ",$rect->{'width'}/Gtk2::Pango::PANGO_SCALE(),
      " x ",$rect->{'height'}/Gtk2::Pango::PANGO_SCALE();

    $rect = Gtk2::Ex::Units::_pango_rect($target,$str,1);
    say "$print log  ",$rect->{'width'}/Gtk2::Pango::PANGO_SCALE(),
      " x ",$rect->{'height'}/Gtk2::Pango::PANGO_SCALE();
  }
}

$widget->set_size_request (Gtk2::Ex::Units::width ($widget, '100 mm'),
                           Gtk2::Ex::Units::height($widget, '100 mm'));
$toplevel->show_all;
Gtk2->main;

exit 0;
