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

=head1 NAME

world-aatw.pl -- sample program displaying DateTimeX::AATW clocks

=head1 SYNOPSIS

 ./world-aatw.pl

=head1 DESCRIPTION

This is a bit of fun showing timezones around the world picked out by the
C<DateTimeX::AATW> "all around the world" module.  You must have it and
C<DateTime::TimeZone> to run this program.

Depending on how fast your computer is, C<DateTimeX::AATW> may take a few
seconds churning through the zones finding offsets.  In a real program you
could display a waiting message or something, but here it's just takes a
moment to start.

=head1 SEE ALSO

L<Gtk2::Ex::Clock>, L<DateTimeX::AATW>, L<DateTime::TimeZone>

=cut

#------------------------------------------------------------------------------

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Clock;
use DateTimeX::AATW;
use List::Util;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $table = Gtk2::Table->new(24, 3);
$toplevel->add ($table);

my $aatw = DateTimeX::AATW->new (DateTime->now);
my $hour_to_names = $aatw->hour_zone_names_map;

foreach my $hour (0 .. 23) {
  my $hour_label = Gtk2::Label->new ("$hour");
  $hour_label->set_alignment (0, 0.5);
  $table->attach_defaults ($hour_label, 0,1, $hour,$hour+1);

  my $names = $hour_to_names->{$hour};

  # prefer a name with a "/" in it, otherwise just the first
  my ($name) = List::Util::first {m{/}} @$names;
  if (! $name) { $name = $names->[0]; }

  if ($name) {
    my $zone = DateTime::TimeZone->new (name => $name);
    my $format = "%a %I:%M %P %Z";
    my $clock = Gtk2::Ex::Clock->new(format   => $format,
                                     timezone => $zone,
                                     xalign   => 0.0,
                                     xpad     => 15);
    $table->attach_defaults ($clock, 1,2, $hour,$hour+1);
  }

  my $zone_label = Gtk2::Label->new ($name ? $name : '[no zone]');
  $zone_label->set_alignment (0, 0.5);
  $table->attach_defaults ($zone_label, 2,3, $hour,$hour+1);
}

$toplevel->show_all;
Gtk2->main;
exit 0;
