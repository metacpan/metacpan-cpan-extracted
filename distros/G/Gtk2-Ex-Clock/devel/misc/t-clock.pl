# Copyright 2007, 2012 Kevin Ryde

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

use strict;
use warnings;
use Gtk2;
use Gtk2::Ex::Clock;

$ENV{'DISPLAY'}=':0';
Gtk2->init;

my $window = Gtk2::Window->new('toplevel');
my $vbox = Gtk2::VBox->new();
$window->add ($vbox);

if (0) {
  $vbox->add (Gtk2::Ex::Clock->new());
}
if (0) {
  my $hbox = Gtk2::HBox->new();
  $vbox->add ($hbox);
  $hbox->add (Gtk2::Label->new('hello'));
  $hbox->add (Gtk2::Ex::Clock->new( # format => '%a %I:%M:%S<sup>%P</sup>',
                                   timezone => 'Europe/London'));
}
if (1) {
  my $hbox = Gtk2::HBox->new();
  $vbox->add ($hbox);
  $hbox->add (Gtk2::Label->new('hello'));
  my $clock = Gtk2::Ex::Clock->new (format   => "%M:%S\nblah",
                                    timezone => 'America/New_York');
  $clock->set_direction ('rtl');
  $hbox->add ($clock);
}

if (0) {
  my $timezone = 'America/New_York';
  $vbox->add (Gtk2::Ex::Clock->new(timezone => $timezone,
                                   ypad => 30));
  $vbox->add (Gtk2::Ex::Clock->new(format => 'NYC-TZ %a %I:%M%p',
                                   timezone => $timezone));
  require DateTime::TimeZone;
  $timezone = DateTime::TimeZone->new(name => $timezone);
  $vbox->add (Gtk2::Ex::Clock->new(format => 'NYC-DT %a %I:%M%p',
                                   timezone => $timezone));
}

if (0) {
  $vbox->add (Gtk2::Ex::Clock->new(format => '%T'));
  $vbox->add (Gtk2::Ex::Clock->new(format => '%s'));
  $vbox->add (Gtk2::Ex::Clock->new(format => "%d %b\n%H:%M"));
}

$window->show_all;
my ($width, $height) = $window->window->get_size;
print "window ${width}x$height\n";

# use Module::Versions::Report;
# print Module::Versions::Report::report();

Gtk2->main();
exit 0;

# Local variables:
# compile-command: "perl -I/home/gg/clock/lib /home/gg/clock/misc/t-clock.pl"
# End:
