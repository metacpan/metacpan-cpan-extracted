#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-TickerView.
#
# Gtk2-Ex-TickerView is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-TickerView is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-TickerView.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./vertical-rottext.pl
#
# This is vertical scrolling tickers with vertical rotated text.  The text
# is done with a pango rotation matrix in a custom cell renderer.  Is there
# an easier way than that?  The Gtk2 2.12 CellRendererText doesn't seem to
# have such a thing, unless it's well hidden.  In particular the "gravity"
# attribute on the text or set separately in the 'attributes' property
# doesn't seem to have any effect.
#
# Well, at worst this is an example of how you can use your own custom cell
# renderer to get anything you want drawn in a ticker, if it wasn't obvious
# that would work :-).
#

package My::CellRendererText::Rotate;
use strict;
use warnings;
use Gtk2;
use POSIX ();

use constant DEBUG => 0;

use Glib::Object::Subclass
  'Gtk2::CellRendererText',
  properties => [ Glib::ParamSpec->double
                  ('rotation',
                   'rotation',
                   'Angle in degrees to rotate the text drawn, in an anti-clockwise direction.   So for instance 90 means the text goes upwards, or -90 means downwards.',
                   - POSIX::DBL_MAX(),
                   POSIX::DBL_MAX(),
                   0,
                   Glib::G_PARAM_READWRITE),
                ];

# sub INIT_INSTANCE {
#   my ($self) = @_;
# }

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $name = $pspec->get_name;
  if ($name eq 'rotation') {
    delete $self->{'layout'};
  }
  $self->{$name} = $newval;
}

sub GET_SIZE {
  my ($self, $widget, $cell_area) = @_;
  if (DEBUG) { print "GET_SIZE '",$self->get('text')||'',"'\n"; }

  my $layout = _get_layout ($self, $widget);
  my (undef, $rect) = $layout->get_extents;  # logical extents
  my $context = $layout->get_context;
  if (my $matrix = $context->get_matrix) { # matrix set only when needed
    $rect = $matrix->transform_rectangle ($rect);
  }
  if (DEBUG) { require Data::Dumper;
               print " pango rect ",Data::Dumper::Dumper($rect); }
  
  my $x = $rect->{'x'} / Gtk2::Pango->scale;
  my $y = $rect->{'y'} / Gtk2::Pango->scale;
  my $width = $rect->{'width'} / Gtk2::Pango->scale + 2 * $self->get('xpad');
  my $height = $rect->{'height'} / Gtk2::Pango->scale + 2 * $self->get('ypad');
  if (DEBUG) { print " pixels ",$x,",",$y, " ", $width,"x",$height, "\n"; }
  return ($x, $y, $width, $height);
}

sub RENDER {
  my ($self, $drawable, $widget, $background_area, $cell_area,
      $expose_area, $flags) = @_;
  if (DEBUG) { print "RENDER ",$cell_area->x,",",$cell_area->y," ",
                 $cell_area->width,"x",$cell_area->height,"\n"; }

  my $layout = _get_layout ($self, $widget);
  my $style = $widget->get_style;

  my $state = $widget->state;
  if (! $self->get('sensitive')) {
    $state = 'insensitive';
  }

  $style->paint_layout ($drawable,
                        $state,
                        1,           # use text gc
                        $expose_area,
                        $widget,
                        __PACKAGE__, # identifier
                        $cell_area->x + $self->get('xpad'),
                        $cell_area->y + $self->get('xpad'),
                        $layout);
}

# Return a Gtk2::Pango::Layout ready to draw the 'text' from $self onto
# $widget.  The layout object isn't cached in case we're asked to drawn to
# different widgets at different times (though that doesn't happen in this
# program.)
#
sub _get_layout {
  my ($self, $widget) = @_;

  my $text = $self->get('text');
  if (! defined $text) { $text = ''; }
  my $layout = $widget->create_pango_layout ($text);
  $layout->set_single_paragraph_mode ($self->get('single-paragraph-mode'));

  # ENHANCE-ME: this would be the point to apply the various 'foreground'
  # and whatnot attributes of CellRendererText ...

  if (my $rotation = POSIX::fmod ($self->{'rotation'}, 360)) {
    # make a matrix if rotation not zero
    if (DEBUG) { print " rotate $rotation\n"; }
    my $context = $layout->get_context;
    my $matrix = Gtk2::Pango::Matrix->new;
    $matrix->rotate ($rotation);
    $context->set_matrix ($matrix);
  }
  return $layout;
}


#-----------------------------------------------------------------------------
package main;
use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::TickerView;

use constant MY_FRAME_RATE => 18;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

my $hbox = Gtk2::HBox->new;
$toplevel->add ($hbox);

{
  my $liststore = Gtk2::ListStore->new ('Glib::String');
  foreach ('This', 'is', 'some', 'words', 'scrolling', 'downwards.') {
    $liststore->set ($liststore->append, 0 => $_);
  }
  my $ticker = Gtk2::Ex::TickerView->new (model => $liststore,
                                          orientation => 'vertical',
                                          run => 1,
                                          frame_rate => MY_FRAME_RATE);
  $ticker->set_direction ('rtl'); # scroll down, in vertical mode
  $hbox->pack_start ($ticker, 0,0,0);

  my $renderer = My::CellRendererText::Rotate->new (rotation => 90, # upwards
                                                    ypad => 6);
  $ticker->pack_start ($renderer, 0);
  $ticker->add_attribute ($renderer, text => 0);
}

my $label = Gtk2::Label->new (<<"HERE");

This is some silliness
scrolling text vertically
rotated using custom
renderers.

Can the gtk text
renderer rotate?  If so
the fiddling about here
is a bit embarrassing,
though it's an example
of how the TickerView
doesn't care what or how
the renderers draw.

HERE
$label->set (justify => 'center');
$hbox->pack_start ($label, 0,0,0);

{
  my $liststore = Gtk2::ListStore->new ('Glib::String');
  foreach ('And','on','this','side','some','words','scrolling','upwards.') {
    $liststore->set ($liststore->append, 0 => $_);
  }
  my $ticker = Gtk2::Ex::TickerView->new (model => $liststore,
                                          orientation => 'vertical',
                                          run => 1,
                                          frame_rate => MY_FRAME_RATE);
  $hbox->pack_end ($ticker, 0,0,0);

  my $renderer = My::CellRendererText::Rotate->new (rotation => -90, # downward
                                                    ypad => 6);
  $ticker->pack_start ($renderer, 0);
  $ticker->add_attribute ($renderer, text => 0);
}

$toplevel->show_all;
Gtk2->main;
exit 0;
