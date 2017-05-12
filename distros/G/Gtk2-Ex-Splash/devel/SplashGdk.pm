# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Splash.
#
# Gtk2-Ex-Splash is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Splash is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Splash.  If not, see <http://www.gnu.org/licenses/>.


package Gtk2::Ex::SplashGdk;
use 5.008;
use strict;
use warnings;
use Glib 1.220;
use List::Util 'max';

our $VERSION = 52;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass 'Glib::Object',
  signals => { # realize => \&_do_realize,
              # expose_event => \&_do_expose_event,
             },
  properties => [ Glib::ParamSpec->object ('pixmap',
                                           'Pixmap',
                                           'Blurb.',
                                           'Gtk2::Gdk::Pixmap',
                                           Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object ('pixbuf',
                                           'Pixbuf',
                                           'Blurb.',
                                           'Gtk2::Gdk::Pixbuf',
                                           Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->string ('filename',
                                           'Filename',
                                           'Blurb.',
                                           (eval {Glib->VERSION(1.240);1}
                                            ? undef # default
                                            : ''),  # no undef/NULL before Perl-Glib 1.240
                                           Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  ### Splash INIT_INSTANCE

}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### Splash SET_PROPERTY
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;
  _update_window ($self);
}

sub _update_window {
  my ($self) = @_;
  ### _update_window()

  my $window = $self->{'window'} || return;

  my $pixmap = $self->{'pixmap'};
  if (! $pixmap) {
    my $pixbuf = $self->{'pixbuf'};
    if (! $pixbuf
        && defined (my $filename = $self->{'filename'})) {
      ### $filename
      $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file ($filename);
    }

    if ($pixbuf) {
      ### $pixbuf
      my $width = $pixbuf->get_width;
      my $height = $pixbuf->get_height;
      $pixmap = Gtk2::Gdk::Pixmap->new ($window, $width,$height, -1);

      my $gc = Gtk2::Gdk::GC->new($pixmap);
      $pixmap->draw_rectangle ($gc,
                               1, # filled
                               0,0,
                               $width,$height);
      $pixbuf->render_to_drawable ($pixmap,
                                   $gc,
                                   0,0,
                                   0,0,
                                   $width, $height,
                                   'none',  # dither
                                   0,0);
    }
  }

  my ($width, $height) = ($pixmap ? $pixmap->get_size : (1,1));
  my ($root_width, $root_height) = $window->get_screen->get_root_window->get_size;
  my $x = max (0, int (($root_width - $width) / 2));
  my $y = max (0, int (($root_height - $height) / 2));
  ### move to: "$x,$y $width,$height"
  $window->move_resize ($x, $y, $width, $height);

  ### set_back_pixmap(): $pixmap
  $window->set_back_pixmap ($pixmap);
  $window->clear;
}

# sub _do_expose_event {
#   my $self = shift;
#   ### _do_expose(), no chain to default
# }

sub show {
  my ($self) = @_;
  ### show()

  # $self->window ($window);
  # $self->get_display->flush;
  # system "xwininfo -events -id ".$window->XID;

  my $window = $self->{'window'};
  if (! $window) {
    my $rootwin = ($self->{'root_window'}
                   || ($self->{'screen'} && $self->{'screen'}->get_root_window)
                   || Gtk2::Gdk->get_default_root_window);
    $window = $self->{'window'}
      = Gtk2::Gdk::Window->new ($rootwin,
                                { window_type => 'temp',
                                  width => 1,
                                  height => 1,
                                  override_redirect => 1,
                                  event_mask => [],
                                });
    $window->set_type_hint ('splashscreen');
    _update_window ($self);
  }
  $window->show;

  if ($window->can('get_display')) { # new in Gtk 2.2
    ### display flush
    $window->get_display->flush;
  } else {
    ### flush
    Gtk2::Gdk->flush;
  }

  $self->{'map_event'} = 0;
# && ! $self->{'map_event'}
  while (Gtk2->events_pending) {
    my $event = Gtk2::Gdk::Event->peek;
    ### event: $event
    ### type: $event && $event->type
    Gtk2->main_iteration_do(0);
  }

}

sub hide {
  my ($self) = @_;
  if (my $window = $self->{'window'}) {
    $window->hide;
  }
}

sub run {
  my ($class, %options) = @_;
  ### Splash run()
  my $time = delete $options{'time'};
  my $self = $class->new (%options);
  $self->show;
  Glib::Timeout->add (($time||.75) * 1000, sub {
                        Gtk2->main_quit;
                        return Glib::SOURCE_REMOVE();
                      });
  Gtk2->main;
}

# sub _window_invalidate_all {
#   my ($window, $invalidate_children) = @_;
#   $window->invalidate_rect (Gtk2::Gdk::Rectangle->new (0,0, $window->get_size),
#                             $invalidate_children);
# }


1;
__END__

=for stopwords Gtk2-Ex-Splash enum ParamSpec GType pspec Enum Ryde toplevel

=head1 NAME

Gtk2::Ex::SplashGdk -- toplevel splash widget

=head1 SYNOPSIS

 use Gtk2::Ex::Splash;
 my $splash = Gtk2::Ex::Splash->new;
 $splash->present;
 ...
 $splash->hide;

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::Splash> is a subclass of C<Gtk2::Window>, but
don't rely on more than C<Gtk2::Widget> for now.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Ex::Splash

=head1 DESCRIPTION

...

=head1 FUNCTIONS

=over 4

=item C<< $splash = Gtk2::Ex::Splash->new (key=>value,...) >>

Create and return a new Splash widget.  Optional key/value pairs set initial
properties per C<< Glib::Object->new >>.

    my $splash = Gtk2::Ex::Splash->new;

=back

=head1 PROPERTIES

=over 4

=item C<pixmap> (C<Gtk2::Gdk::Pixmap> object, default C<undef>)

=back

=head1 SEE ALSO

L<Gtk2::Window>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-splash/index.html>

=head1 LICENSE

Copyright 2010, 2011 Kevin Ryde

Gtk2-Ex-Splash is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-Splash is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-Splash.  If not, see L<http://www.gnu.org/licenses/>.

=cut
