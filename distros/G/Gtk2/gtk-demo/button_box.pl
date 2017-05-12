#!/usr/bin/perl -w
#
# Button Boxes
#
# The Button Box widgets are used to arrange buttons with padding.
#

package button_box;

use Glib qw(TRUE FALSE);
use Gtk2;

sub create_bbox {
  my ($horizontal, $spacing, $layout) = @_;

  my $title = ucfirst $layout;

  my $frame = Gtk2::Frame->new ($title);

  my $bbox = $horizontal
           ? Gtk2::HButtonBox->new
	   : Gtk2::VButtonBox->new;

  $bbox->set_border_width (5);
  $frame->add ($bbox);

  $bbox->set_layout ($layout);
  $bbox->set_spacing ($spacing);
  
  my $button = Gtk2::Button->new_from_stock ('gtk-ok');
  $bbox->add ($button);
  
  $button = Gtk2::Button->new_from_stock ('gtk-cancel');
  $bbox->add ($button);
  
  $button = Gtk2::Button->new_from_stock ('gtk-help');
  $bbox->add ($button);

  return $frame;
}

my $window = undef;

sub do {
  if (!$window) {
    $window = Gtk2::Window->new;
    $window->set_title ("Button Boxes");
    
    $window->signal_connect (destroy => sub { $window = undef; 1 });
    
    $window->set_border_width (10);

    my $main_vbox = Gtk2::VBox->new (FALSE, 0);
    $window->add ($main_vbox);
    
    my $frame_horz = Gtk2::Frame->new ("Horizontal Button Boxes");
    $main_vbox->pack_start ($frame_horz, TRUE, TRUE, 10);
    
    my $vbox = Gtk2::VBox->new (FALSE, 0);
    $vbox->set_border_width (10);
    $frame_horz->add ($vbox);

    $vbox->pack_start (create_bbox (TRUE, 40, 'spread'), TRUE, TRUE, 0);
    $vbox->pack_start (create_bbox (TRUE, 40, 'edge'),   TRUE, TRUE, 5);
    $vbox->pack_start (create_bbox (TRUE, 40, 'start'),  TRUE, TRUE, 5);
    $vbox->pack_start (create_bbox (TRUE, 40, 'end'),    TRUE, TRUE, 5);

    my $frame_vert = Gtk2::Frame->new ("Vertical Button Boxes");
    $main_vbox->pack_start ($frame_vert, TRUE, TRUE, 10);
    
    my $hbox = Gtk2::HBox->new (FALSE, 0);
    $hbox->set_border_width (10);
    $frame_vert->add ($hbox);

    $hbox->pack_start (create_bbox (FALSE, 30, 'spread'), TRUE, TRUE, 0);
    $hbox->pack_start (create_bbox (FALSE, 30, 'edge'),   TRUE, TRUE, 5);
    $hbox->pack_start (create_bbox (FALSE, 30, 'start'),  TRUE, TRUE, 5);
    $hbox->pack_start (create_bbox (FALSE, 30, 'end'),    TRUE, TRUE, 5);
  }

  if (!$window->visible) {
      $window->show_all;
  } else {	 
      $window->destroy;
      $window = undef;
  }

  return $window;
}

1;
__END__
Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
