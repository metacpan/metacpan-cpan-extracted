#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::Units;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to Gtk2->init_check() unsuccessful';
MyTestHelpers::glib_gtk_versions();

plan tests => 37;

{
  my $want_version = 48;
  is ($Gtk2::Ex::Units::VERSION, $want_version, 'VERSION variable');
  is (Gtk2::Ex::Units->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Gtk2::Ex::Units->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::Units->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

my $label = Gtk2::Label->new;

#-----------------------------------------------------------------------------
# em()

{
  my $em = Gtk2::Ex::Units::em($label);
  ok ($em > 0);
  ok ($em < 1000);
}

#-----------------------------------------------------------------------------
# digit_width()

{
  my $digit_width = Gtk2::Ex::Units::digit_width($label);
  ok ($digit_width > 0);
  ok ($digit_width < 1000);
}

#-----------------------------------------------------------------------------
# ex()

{
  my $ex = Gtk2::Ex::Units::ex($label);
  ok ($ex > 0);
  ok ($ex < 1000);
}

#-----------------------------------------------------------------------------
# line_height()

{
  my $line_height = Gtk2::Ex::Units::line_height($label);
  ok ($line_height > 0);
  ok ($line_height < 1000);
}


#-----------------------------------------------------------------------------

{
  my $target = $label;
  my $char_width = Gtk2::Ex::Units::char_width($target);
  my $em = Gtk2::Ex::Units::em($target);
  my $digit_width = Gtk2::Ex::Units::digit_width($target);
  my $ex = Gtk2::Ex::Units::ex($target);
  my ($screen_width, $screen_height);
  if ($label->can('get_screen')) {
    my $screen = $label->get_screen;
    $screen_width = $screen->get_width;
    $screen_height = $screen->get_height;
  } else {
    $screen_width = Gtk2::Gdk->screen_width;
    $screen_height = Gtk2::Gdk->screen_height;
  }
  diag "em=$em, ex=$ex, char=$char_width, digit=$digit_width";

  foreach my $elem (
                    # no unit
                    [ \&Gtk2::Ex::Units::width, '123', 123 ],
                    [ \&Gtk2::Ex::Units::height, '456', 456 ],

                    # pixel
                    [ \&Gtk2::Ex::Units::width, '123 pixel', 123 ],
                    [ \&Gtk2::Ex::Units::height, '456 pixels', 456 ],

                    # char
                    [ \&Gtk2::Ex::Units::width, '0 char', 0 ],
                    [ \&Gtk2::Ex::Units::width, '6 char', 6*$char_width ],
                    [ \&Gtk2::Ex::Units::width, '7 chars', 7*$char_width ],

                    # em
                    [ \&Gtk2::Ex::Units::width, '0 em', 0 ],
                    [ \&Gtk2::Ex::Units::width, '6 em', 6*$em ],
                    [ \&Gtk2::Ex::Units::width, '7 ems', 7*$em ],
                    # no em for height as yet
                    # [ \&Gtk2::Ex::Units::height, '0 em', 0 ],
                    # [ \&Gtk2::Ex::Units::height, '1 em' ],

                    # digit
                    [ \&Gtk2::Ex::Units::width, '0 digits', 0 ],
                    [ \&Gtk2::Ex::Units::width, '1 digit', $digit_width ],

                    # ex
                    [ \&Gtk2::Ex::Units::height, '6 ex', 6*$ex ],
                    [ \&Gtk2::Ex::Units::height, '8 exes', 8*$ex ],

                    # line
                    [ \&Gtk2::Ex::Units::height, '0 lines', 0 ],

                    # screen
                    [ \&Gtk2::Ex::Units::width, '1 screen', $screen_width ],
                    [ \&Gtk2::Ex::Units::width, '2 screens', 2*$screen_width ],
                    [ \&Gtk2::Ex::Units::height, '1 screen', $screen_height ],
                    [ \&Gtk2::Ex::Units::height, '2 screens', 2*$screen_height],

                    # mm
                    [ \&Gtk2::Ex::Units::width, '0 mm', 0 ],
                    [ \&Gtk2::Ex::Units::height, '0 mm', 0 ],

                    # inch
                    [ \&Gtk2::Ex::Units::width, '0 inch', 0 ],
                    [ \&Gtk2::Ex::Units::height, '0 inches', 0 ],

                    # cm -- not implemented, as yet
                    # [ \&Gtk2::Ex::Units::width, '0 cm', 0 ],
                    # [ \&Gtk2::Ex::Units::height, '0 cm', 0 ],

                   ) {
    my ($func, $str, $want) = @$elem;

    if (defined $want) {
      is (&$func($target,$str), $want,
          "str: $str")
    } else {
      like (&$func($target,$str), qr/^[0-9.]+$/,
            "str: $str");
    }
  }

}


# is (Gtk2::Ex::Units::height ($target, '6 lines'), 6 * $line);
# is (Gtk2::Ex::Units::height ($target, '6 line'),  6 * $line);

my $frame = Gtk2::Frame->new;
$frame->add ($label);

{

  is (Gtk2::Ex::Units::width ($frame, '123'),        123);
  is (Gtk2::Ex::Units::height ($frame, '456'),        456);

  # is (Gtk2::Ex::Units::height ($frame, '6 lines'), 6 * $line);
}

exit 0;
