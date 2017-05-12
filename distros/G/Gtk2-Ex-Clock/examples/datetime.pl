#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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

datetime.pl -- Clock display using DateTime::TimeZone

=head1 SYNOPSIS

 ./datetime.pl

 LANGUAGE=de ./datetime.pl

=cut

#-----------------------------------------------------------------------------

use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::Clock;
use DateTime;
use DateTime::TimeZone;

# locale setup for DateTime, using the first of Glib's get_language_names()
# which works (you probably need the DateTime::Locale package installed)
#
foreach my $lang (Glib::get_language_names()) {
  if (eval { DateTime->DefaultLocale($lang) }) {
    print "DateTime locale    '$lang'\n";
    last;
  }
}

# DateTime::TimeZone object
#
my $timezone = DateTime::TimeZone->new (name => 'Australia/Perth');
print "DateTime::TimeZone '", $timezone->name, "'\n";


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit; });

# when using DateTime::TimeZone the format is passed to DateTime->strftime,
# so its extra %{method} forms are available.
#
my $clock = Gtk2::Ex::Clock->new (format => '%{day_name} %H:%M',
                                  timezone=> $timezone);
$toplevel->add ($clock);

$toplevel->show_all;
Gtk2->main;
exit 0;
