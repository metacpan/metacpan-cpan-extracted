#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Clock.
#
# Gtk2-Ex-Clock is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Clock is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Clock.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Getopt::Long;
use Gtk2 '-init';
use Gtk2::Ex::Clock;

our $VERSION = 15;

my ($foreground, $background, $geometry, $use_noshrink);
my %clock_properties;
sub getopt_clock_property {
  my ($key, $value) = @_;
  $clock_properties{$key} = $value;
}

GetOptions
  (require_order => 1,
   version => sub {
     print "gtk2-ex-clock.pl version $VERSION\n";
     exit 0;
   },
   'help|?' => sub {
     print <<'HERE';
gtk2-ex-clock.pl [--options]
--format=STR             strftime format string for display
--timezone=STR           Timezone name (default TZ environment variable)
--datetime-timezone=STR  DateTime::TimeZone of given zone
--help-datetime-names    Print available DateTime::TimeZone zone names
--resolution=SECS
--geometry=GEOMSPEC
--help, -?               Print this help
-v, --version            Print program version
--<gtk-options>          Standard Gtk options
HERE
     exit 0;
   },


   'format=s',       \&getopt_clock_property,
   'timezone=s',     \&getopt_clock_property,
   'resolution=f',   \&getopt_clock_property,
   'geometry=s',     \$geometry,
   'use-noshrink=s', \$use_noshrink,
   'foreground=s',   \$foreground,
   'background=s',   \$background,

   'datetime-timezone=s', sub {
     my ($opt, $value) = @_;
     require DateTime::TimeZone;
     $clock_properties{'timezone'} = DateTime::TimeZone->new (name => $value);
   },
   'help-datetime-names' => sub {
     require DateTime::TimeZone;
     my @names = DateTime::TimeZone->all_names;
     { local $,="\n"; print @names,''; }
     exit 0;
   },
  )
  or exit 1; # for unknown option

if (@ARGV) {
  print "Unrecognised option '$ARGV[0]'\n";
  exit 1;
}

#------------------------------------------------------------------------------

if (defined $foreground) {
  Gtk2::Rc->parse_string (<<"HERE");
style "Gtk2_Ex_Clock_pl_style" {
  fg[NORMAL] = "$foreground"
  text[NORMAL] = "$foreground"
}
class "Gtk2__Ex__Clock" style:application "Gtk2_Ex_Clock_pl_style"
HERE
}
if (defined $background) {
  Gtk2::Rc->parse_string (<<"HERE");
style "Gtk2_Ex_Clock_pl_style" { bg[NORMAL] = "$background" }
class "GtkWindow" style:application "Gtk2_Ex_Clock_pl_style"
HERE
}

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });
$toplevel->signal_connect
  (realize => sub {
     $toplevel->window->set_accept_focus (0);
     $toplevel->window->set_decorations (['border']);
     if (defined $geometry) {
       $toplevel->parse_geometry ($geometry);
     }
   });

my $noshrink = $toplevel;
if ($use_noshrink && eval { require Gtk2::Ex::NoShrink }) {
  $noshrink = Gtk2::Ex::NoShrink->new;
  $toplevel->add ($noshrink);
}

my $clock = Gtk2::Ex::Clock->new (%clock_properties);
$noshrink->add ($clock);

my $menu = Gtk2::Menu->new;

my $quit = Gtk2::ImageMenuItem->new_from_stock ('gtk-quit');
$quit->signal_connect (activate => sub { $toplevel->destroy });
$quit->show;
$menu->add ($quit);


$toplevel->add_events (['button-press-mask','button-motion-mask']);
$toplevel->signal_connect (button_press_event => \&button_press);
$toplevel->signal_connect (motion_notify_event => \&motion_notify);
$toplevel->signal_connect (button_release_event => \&button_release);

my ($drag_last_x_root, $drag_last_y_root);
sub button_press {
  my ($toplevel, $event) = @_;
  if ($event->button == 1) {
    $drag_last_x_root = $event->x_root;
    $drag_last_y_root = $event->y_root;
  } elsif ($event->button == 3) {
    $menu->popup (undef, undef, undef, undef,
                  $event->button, $event->time);
  }
}
sub motion_notify {
  my ($toplevel, $event) = @_;
  drag ($event->x_root, $event->y_root);
}
sub button_release {
  my ($toplevel, $event) = @_;
  if ($event->button == 1) {
    drag ($event->x_root, $event->y_root);
    $drag_last_x_root = undef;
  }
}
# In theory you're meant to move with widget $toplevel->move, not its
# underlying window, but as of Gtk 2.16.1 there's some dodginess between it
# and fvwm2; a window move works, a widget move goes to the wrong place.
sub drag {
  my ($x_root, $y_root) = @_;
  defined $drag_last_x_root or return;
  my $window = $toplevel->window || return;
  my ($x, $y) = $window->get_position;
  $window->move ($x + $x_root - $drag_last_x_root,
                 $y + $y_root - $drag_last_y_root);
  $drag_last_x_root = $x_root;
  $drag_last_y_root = $y_root;
}


$toplevel->show_all;
Gtk2->main;
exit 0;


__END__

=head1 NAME

gtk2-ex-clock.pl -- simple digital clock program

=head1 SYNOPSIS

 gtk2-ex-clock.pl [--options]

=head1 DESCRIPTION

C<gtk2-ex-clock.pl> displays a digital clock using C<Gtk2::Ex::Clock>.  It's
pretty simple, and there's a dozen other clock programs doing the same
thing, but this one uses C<Gtk2::Ex::Clock>, and optionally
C<DateTime::TimeZone>.

Button-1 drags the clock around (plus any usual key/button combination the
window manager also offers for that).  Button-3 pops up a menu to quit.  On
a two-button mouse button-3 is usually the right hand button.

=head1 OPTIONS

=over 4

=item --format=STR

C<strftime> format string for the display.  See C<man strftime> or C<man
date> for possible formats.  The default is "%H:%M" for hours and minutes.

    gtk2-ex-clock.pl --format="%I:%M %P"

=item --timezone=STR

Timezone to display (default local time per TZ environment variable or
system default).

=item --datetime-timezone=STR

Timezone to display, using a given named C<DateTime::TimeZone> zone
(requires L<C<DateTime>|DateTime> and
L<C<DateTime::TimeZone>|DateTime::TimeZone> installed).

=item --help-datetime-names

Print the available C<DateTime::TimeZone> zone names.

=item --resolution=SECS

Set the resolution in seconds of the C<--format> string, as per the
C<Gtk2::Ex::Clock> C<resolution> property.  Usually C<Gtk2::Ex::Clock> gets
the right resolution from the format string.

=item --foreground=COLOUR

=item --background=COLOUR

Set the foreground and background colours.  The colours can be names from
the X RGB database (F</etc/X11/rgb.txt>), or hex style #RRGGBB.  For example
white on a shade of red,

    gtk2-ex-clock.pl --foreground=white --background=#A01010

=item --geometry=SIZE+POSITION

Set the size and position of the clock window.  See C<man X> on geometry
specification strings.  For example to start at the top-right of the screen,
leaving the size to the clock's default.

    gtk2-ex-clock.pl --geomentry=-0+0

=item --help, -?

Print a summary of the options.

=item -v, --version

Print program version.

=item --<gtk-options>

Standard Gtk options.  See C<man gtk-options> for the full list.  The only
one which does much for C<gtk2-ex-clock.pl> is C<--display> to set the X
display (default from the C<DISPLAY> environment variable).

=back

=head1 SEE ALSO

L<Gtk2::Ex::Clock>, C<strftime(3)>, L<DateTime::TimeZone>,
L<Gtk2::Ex::NoShrink>, C<gtk-options>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-clock/index.html>

=head1 LICENSE

Gtk2-Ex-Clock is Copyright 2007, 2008, 2009, 2010 Kevin Ryde

Gtk2-Ex-Clock is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-Clock is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-Clock.  If not, see L<http://www.gnu.org/licenses/>.

=cut
