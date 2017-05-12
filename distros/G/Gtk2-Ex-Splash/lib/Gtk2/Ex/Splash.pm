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


package Gtk2::Ex::Splash;
use 5.008;
use strict;
use warnings;
use Gtk2;
use List::Util 'max';
use Scalar::Util;

our $VERSION = 52;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass 'Gtk2::Window',
  signals => { realize      => \&_do_realize,
               map          => \&_do_map,
               unmap        => \&_do_flush,
               unrealize    => \&_do_flush,
               expose_event => \&_do_expose_event },

  properties =>
  [ Glib::ParamSpec->object ('pixmap',
                             (do {
                               my $str = 'Pixmap';
                               eval { require Locale::Messages;
                                      Locale::Messages::dgettext('gtk20-properties',$str)
                                      } || $str }),
                             'Blurb.',
                             'Gtk2::Gdk::Pixmap',
                             Glib::G_PARAM_READWRITE),

    Glib::ParamSpec->object ('pixbuf',
                             (do {
                               my $str = 'Pixbuf';
                               eval { require Locale::Messages;
                                      Locale::Messages::dgettext('gtk20-properties',$str)
                                      } || $str }),
                             'Blurb.',
                             'Gtk2::Gdk::Pixbuf',
                             Glib::G_PARAM_READWRITE),

    Glib::ParamSpec->scalar ('filename',
                             (do {
                               # as from GtkFileSelection and
                               # GtkRecentManager
                               my $str = 'Filename';
                               eval { require Locale::Messages;
                                      Locale::Messages::dgettext('gtk20-properties',$str)
                                      } || $str }),
                             'Blurb.',
                             Glib::G_PARAM_READWRITE),
  ];

sub new {
  my $class = shift;
  return $class->SUPER::new (type => 'popup', @_);
}

my %instances;

sub INIT_INSTANCE {
  my ($self) = @_;
  ### Splash INIT_INSTANCE()
  $self->set_app_paintable (0);
  $self->set_double_buffered(0);
  $self->can_focus (0);
  Scalar::Util::weaken ($instances{Scalar::Util::refaddr($self)} = $self);
}
sub FINALIZE_INSTANCE {
  my ($self) = @_;
  delete $instances{Scalar::Util::refaddr($self)};
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### Splash SET_PROPERTY: $pname

  if ($pname eq 'filename' && defined $newval) {
    # stringize to copy possible object passed in instead of plain string
    $newval = "$newval";
  }
  $self->{$pname} = $newval;
  _update_pixmap ($self);
  if ($self->mapped) {
    _flush($self);
  }
}

sub _do_expose_event {
  # my $self = shift;
  ### Splash _do_expose(), no chain to default

  # don't chain as don't want the GtkWindow expose handler
  # gtk_window_expose() to draw the style background colour ...
}

sub _do_realize {
  my $self = shift;
  ### Splash _do_realize()

  $self->signal_chain_from_overridden();
  my $window = $self->window;
  $window->set_override_redirect (1);
  if ($window->can('set_type_hint')) { # new in Gtk 2.10
    $window->set_type_hint ('splashscreen');
  }
  ### xwininfo: do { $self->get_display->flush; $self->window && system "xwininfo -events -id ".$self->window->XID }

  _update_pixmap ($self);

  ### Splash _do_realize() finished
}

my $unmap_id;

# widget "unmap" signal emission hook, run after normal signal connections
sub _do_unmap_emission_hook {
  my ($invocation_hint, $parameters) = @_;
  my ($widget) = @$parameters;
  ### Splash _do_unmap_emission_hook()

  # ->clear() any Splash instances on the same screen as $widget
  my $keep = 0;
  foreach my $instance (values %instances) {
    if ($instance  # perhaps weakened away in global destruction
        && (my $window = $instance->window)  # when realized
        && $instance->mapped) {              # and mapped
      $keep = 1;
      if (! $widget->can('get_screen') # not in Gtk 2.0
          || $widget->get_screen == $instance->get_screen) {
        ### clear other instance: "$instance"
        $window->clear;
        _flush ($instance);
      }
    }
  }
  if (! $keep) {
    undef $unmap_id; # to be reconnected in _do_map()
  }
  ### _do_unmap_emission_hook() finished
  ### $keep
  ### $unmap_id
  return $keep; # stay connected, or not
}

sub _do_map {
  my $self = shift;
  ### Splash _do_map()
  $self->signal_chain_from_overridden ();

  # something fishy requires a clear, the background isn't drawn just by a map
  $self->window->clear;
  _flush ($self);

  $unmap_id ||= Gtk2::Widget->signal_add_emission_hook
    (unmap => \&_do_unmap_emission_hook);
  ### $unmap_id

  ### _do_map() finished
}

# "unmap" and "unrealize" class handler
# flush so as to immediately pop down the splash
# $splash->unrealize() doesn't call the unmap handler, hence unrealize handler
# $splash->destroy() does unmap then unrealize, so it gets both in fact
#
sub _do_flush {
  ### Splash _do_flush()
  my $self = shift;
  $self->signal_chain_from_overridden (@_);
  _flush ($self);
}

# set_back_pixmap() or set_background() according to the current properties
# clear the window to make the change show up too, if mapped
# if no window yet (unrealized) then do nothing
sub _update_pixmap {
  my ($self) = @_;
  ### _update_pixmap()
  ### pixmap: $self->{'pixmap'}
  ### pixbuf: $self->{'pixbuf'}
  ### filename: $self->{'filename'}

  my $window = $self->window || return;

  my $pixmap = $self->{'pixmap'};
  if (! $pixmap) {
    my $pixbuf = $self->{'pixbuf'};
    if (! $pixbuf
        && defined (my $filename = $self->{'filename'})) {
      ### $filename
      $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file ($filename);
    }

    ### $pixbuf
    if ($pixbuf) {
      ### state: $self->state
      ### style: $self->get_style
      ### bg-gc: $self->get_style->bg_gc($self->state)
      ### bg-color: $self->get_style->bg($self->state)->to_string

      my $width = $pixbuf->get_width;
      my $height = $pixbuf->get_height;
      $pixmap = Gtk2::Gdk::Pixmap->new ($window, $width,$height, -1);

      # my $bg_color = $self->get_style->bg($self->state);
      # my $gc = Gtk2::Gdk::GC->new($pixmap, { foreground => $bg_color });

      my $gc = $self->get_style->bg_gc($self->state);
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
  ### $pixmap

  my ($width, $height) = ($pixmap ? $pixmap->get_size : (100,100));
  $self->resize ($width, $height);
  ### resize to: "$width, $height"

  my $root = ($self->can('get_root_window') # new in Gtk 2.2
              ? $self->get_root_window
              : Gtk2::Gdk->default_root_window);
  my ($root_width, $root_height) = $root->get_size;
  my $x = max (0, int (($root_width - $width) / 2));
  my $y = max (0, int (($root_height - $height) / 2));
  ### move to: "$x,$y"
  $self->move ($x, $y);

  # the size is normally only applied under ->map(), or some such, force here
  $window->move_resize ($x, $y, $width, $height);

  ### Splash set_back_pixmap(): $pixmap
  $window->set_back_pixmap ($pixmap);
  if (! $pixmap) {
    # fallback to the style bg if no pixmap etc set, just "normal" as not to
    # bother following the $self->state() for this fallback
    $window->set_background ($self->get_style->bg('normal'));
  }
  if ($self->mapped) {
    $window->clear;
  }
}

# flush the X request queue on the display of $self
sub _flush {
  my ($self) = @_;
  if ($self->can('get_display')) { # new in Gtk 2.2
    ### get_display flush
    $self->get_display->flush;
  } else {
    ### flush() is XSync in Gtk 2.0.x
    Gtk2::Gdk->flush;
  }
}

1;
__END__

=for stopwords Gtk2-Ex-Splash Gtk Ryde toplevel startup filename GdkPixbuf PNG JPEG Gtk2 toplevels cron subclassed unmaps

=head1 NAME

Gtk2::Ex::Splash -- toplevel splash widget

=head1 SYNOPSIS

 use Gtk2::Ex::Splash;
 my $splash = Gtk2::Ex::Splash->new (filename => '/my/image.png');
 $splash->show;
 # do some things
 $splash->destroy;

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::Splash> is a subclass of C<Gtk2::Window> (the
usual toplevels), but don't rely on more than C<Gtk2::Widget> just yet.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Ex::Splash

=head1 DESCRIPTION

This is a toplevel splash window centred on the screen.  It can be used as a
splash at program startup if some initializations might be slow, or a
general purpose flash or splash.

A splash at program startup can be annoying.  It's often better to get the
main window up and displayed early, and finish populating or opening an
initial document while the user has something to look at, though that's not
always easy.

A splash can also show something briefly without being too intrusive.  For
example a slide-show or cron job to flash a fun image every few minutes for
just a 1/2 second or so to relieve the monotony of work.  The supplied
C<gtk2-ex-splash> for example displays an image file that way.

The splash window is not interactive and doesn't take the keyboard focus
away from whatever the user is doing.  (Is that true of "focus follows
mouse" window manager style though?)  It does consume mouse button clicks
though.

The splash contents are shown as the window background, so it doesn't
require any redraws etc from the application and so displays even if the
application is busy doing other things.

=head2 Flushing

The Splash code tries to flush the outgoing X request queue at suitable
times to ensure that a C<< $splash->show >> etc immediately shows the
splash, or a C<< $splash->destroy >> etc immediately removes it.  This seems
to work reasonably well, and hopefully there won't be any need for special
specific methods to show and hide.

=head1 FUNCTIONS

=over 4

=item C<< $splash = Gtk2::Ex::Splash->new (key=>value,...) >>

Create and return a new Splash widget.  Optional key/value pairs set initial
properties per C<< Glib::Object->new >>.

    my $splash = Gtk2::Ex::Splash->new (filename => '/my/dir/image.png');

=back

=head1 PROPERTIES

=over 4

=item C<pixmap> (C<Gtk2::Gdk::Pixmap> object, default C<undef>)

=item C<pixbuf> (C<Gtk2::Gdk::Pixbuf> object, default C<undef>)

=item C<filename> (string, default C<undef>)

The image to display in the splash.

A filename is read with C<Gtk2::Gdk::Pixbuf> so can be any file format
supported by GdkPixbuf.  PNG and JPEG are supported in all Gtk2 versions.

In the current code C<filename> is a scalar type, so it can hold a byte
string which is usual for a filename in Perl and is what's required by the
C<< Gtk2::Gdk::Pixbuf->new_from_file >> used to read the file.  Is that the
right property type and the right way to do it?

=back

The usual C<Gtk2::Window> C<screen> property determines the screen the
splash window displays on (see L<Gtk2::Window/PROPERTIES>).

=head1 IMPLEMENTATION NOTES

The splash is only a C<Gtk2::Gdk::Window> with a background, but it's done
as a widget since C<Gtk2::Gdk::Window> doesn't subclass properly, as of Gtk
circa 2.22 (notes in C<Gtk2::Gdk::Window>).

Something fishy happens when another window in the program is on top of the
splash and is unmapped.  The revealed area of the splash should
automatically clear to its background, but doesn't.  Maybe something to do
with double buffering.  Windows from other client connections don't cause
the problem.  It only normally arises if the program shows a second splash
on top of the first and is handled in the code by listening for any widget
unmaps and clearing splashes.  Unfortunately this doesn't pick up direct
C<Gtk2::Gdk::Window> hides (ie. not from a widget), though that's hopefully
unlikely.

=head1 SEE ALSO

L<Gtk2::Window>, L<gtk2-ex-splash(1)>

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
