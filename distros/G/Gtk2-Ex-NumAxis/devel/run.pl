#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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
use POSIX;
use Gtk2;
use Gtk2::Ex::NumAxis;

use FindBin;
my $progname = $FindBin::Script;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my ($unit, $decimals) = Gtk2::Ex::NumAxis::round_up_2_5_pow_10 (100);
  print "$progname: $unit $decimals\n";
  ($unit, $decimals) = Gtk2::Ex::NumAxis::round_up_2_5_pow_10 (80);
  print "$progname: $unit $decimals\n";
  ($unit, $decimals) = Gtk2::Ex::NumAxis::round_up_2_5_pow_10 (45);
  print "$progname: $unit $decimals\n";
  ($unit, $decimals) = Gtk2::Ex::NumAxis::round_up_2_5_pow_10 (0.33);
  print "$progname: $unit $decimals\n";
  ($unit, $decimals) = Gtk2::Ex::NumAxis::round_up_2_5_pow_10 (0.00099);
  print "$progname: $unit $decimals\n";
}

Gtk2->init;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->set_default_size (-1, 500);

my $box = Gtk2::HBox->new (0,0);
$toplevel->add ($box);

my $vbox = Gtk2::VBox->new (0,0);
$box->pack_start ($vbox, 0,0,0);

use constant LOG_E_10 => 2.30258509299404568402;

sub exp10 {
  my ($x) = @_;
  exp ($x * LOG_E_10);
}
if (0) {
  my $adj = Gtk2::Adjustment->new (0,
                                   -3,
                                   5,
                                   0.1, 1, 1);
  my $axis = Gtk2::Ex::NumAxis->new(adjustment => $adj,
                                    transform   => \&POSIX::exp10,
                                    untransform => \&POSIX::log10,
                                   );
  $box->add($axis);

  my $scrollbar = Gtk2::Scrollbar->new($adj);
  $box->add($scrollbar);
}

my $adj = Gtk2::Adjustment->new (-100, # value
                                 -1000, # lower
                                 1000,  # upper
                                 1,   # step increment
                                 10,  # page increment
                                 20); # page size
### adj: "$adj"
my $axis = Gtk2::Ex::NumAxis->new(adjustment => $adj,
                                  inverted => 1,
                                  min_decimals => 2);
$axis->add_events (['button-press-mask']);
# $axis->signal_connect (number_to_text => sub {
#                          my ($axis, $number, $decimals) = @_;
#                          return sprintf "%.*f\nblah", $decimals, $number;
#                         });
my %vertical_to_horiziontal = (vertical   => 'horizontal',
                               horizontal => 'vertical');
require Glib::Ex::ConnectProperties;
Glib::Ex::ConnectProperties->new ([$axis,'orientation'],
                                  [$box,'orientation',
                                   hash_in => \%vertical_to_horiziontal,
                                   hash_out => \%vertical_to_horiziontal]);
$box->add($axis);
### axis: "$axis"

if (0) {
  my $adj = Gtk2::Adjustment->new (1000, -1000, 10000, 100, 1000, 8000);
  my $vscale = Gtk2::VScale->new($adj);
  $vscale->set('digits', 2);
  $box->add($vscale);
}

if (1) {
  #   my $adj = Gtk2::Adjustment->new (100, -100, 1000, 10, 100, 800);
  #  $ruler->set('digits', 2);
  my $ruler = Gtk2::VRuler->new;
  $adj->signal_connect ('value-changed' => sub {
                          my ($adj) = @_;
                          # $ruler->set_range ($adj->lower, $adj->upper,
                          #                     $adj->value, 999);
                          $ruler->set_range ($adj->value,
                                             $adj->value + $adj->page_size,
                                             $adj->value, 999);
                        });
  Glib::Ex::ConnectProperties->new ([$axis,'orientation'],
                                    [$ruler,'orientation']);
  $box->add($ruler);
  ### ruler: "$ruler"
}

{
  my $scrollbar = Gtk2::VScrollbar->new($adj);
  ### scrollbar: "$scrollbar"
  $box->pack_start($scrollbar, 0,0,0);
  Glib::Ex::ConnectProperties->new ([$axis,'inverted'],
                                    [$scrollbar,'inverted']);
  Glib::Ex::ConnectProperties->new ([$axis,'orientation'],
                                    [$scrollbar,'orientation']);
}

{
  my $button = Gtk2::CheckButton->new_with_label ("inverted");
  Glib::Ex::ConnectProperties->new ([$axis,'inverted'],
                                    [$button,'active']);
  $vbox->pack_start ($button, 0,0,0);
}
{
  my $spin = Gtk2::SpinButton->new_with_range (0, 2*$adj->page_size, 10);
  Glib::Ex::ConnectProperties->new ([$adj,'page-size'],
                                    [$spin,'value']);
  $vbox->pack_start ($spin, 0,0,0);
}
{
  my $spin = Gtk2::SpinButton->new_with_range (0, 2*$adj->page_size, 1);
  Glib::Ex::ConnectProperties->new ([$adj,'step-increment'],
                                    [$spin,'value']);
  $vbox->pack_start ($spin, 0,0,0);
}
{
  my $spin = Gtk2::SpinButton->new_with_range (0, 50, 1);
  Glib::Ex::ConnectProperties->new ([$axis,'min-decimals'],
                                    [$spin,'value']);
  $vbox->pack_start ($spin, 0,0,0);
}
{
  require Gtk2::Ex::ComboBox::Enum;
  my $combo = Gtk2::Ex::ComboBox::Enum->new (enum_type => 'Gtk2::Orientation');
  Glib::Ex::ConnectProperties->new ([$axis,'orientation'],
                                    [$combo,'active-nick']);
  $vbox->pack_start ($combo, 0,0,0);
}

$toplevel->show_all;

Gtk2->main();
exit 0;









#   if (my $nf = $self->{'number_format_object'}) {
#     return $nf->format_number ($num, $decimals, 1);
#   }
# #   This is
# # either a reference to a function, or a C<Number::Format> object, or C<undef>
# # for a simple default format.
# # 
# # A function is called with the number and how many decimals to show, and it
# # should return a string (possibly a Perl wide-char string).  The decimals
# # passed can be more than the C<decimals> property above if a unit smaller
# # than that has been selected.  Here's an example using C<sprintf> with a "+"
# # to put a "+" sign on positive numbers,
# # 
# #     sub my_formatter {
# #       my ($n, $decimals) = @_;
# #       return sprintf ('%+.*f', $decimals, $n);
# #     }
# #     $axis->set('number-format-object', \&my_formatter);
# # 
# # If C<formatter> is a C<Number::Format> object then 
# 
# 
# # =item C<number-format-object> (Perl C<Number::Format> object, default undef)
# # 
# # A C<Number::Format> object for how to display numbers.  The default C<undef>
# # means a plain C<sprintf> instead.
# # 
# # The C<format_number> method is used and various settings such as thousands
# # separator and decimal point in the object thus affect the display.  For
# # example,
# # 
# #     use Number::Format;
# #     my $nf = Number::Format->new (-thousands_sep => ' ',
# #                                   -decimal_point => ',');
# #     $axis->set (number_format_object => $nf);
# # 
# 
#                  Glib::ParamSpec->scalar
#                  ('number-format-object',
#                   'number-format-object',
#                   '',
#                   Glib::G_PARAM_READWRITE),

