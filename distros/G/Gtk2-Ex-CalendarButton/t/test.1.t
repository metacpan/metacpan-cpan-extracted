use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 qw/-init/;
use Gtk2::Ex::CalendarButton;
use Data::Dumper;

use Gtk2::TestHelper tests => 7;

my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
my $year = 1900 + $yearOffset;
my $date = [$year, $month, $dayOfMonth];

my $calbutton = Gtk2::Ex::CalendarButton->new;
isa_ok($calbutton, "Gtk2::Ex::CalendarButton");
isa_ok($calbutton->{calendar}, "Gtk2::Calendar");
isa_ok($calbutton->{button}, "Gtk2::Button");

isa_ok($calbutton->get_calendar, "Gtk2::Calendar");
isa_ok($calbutton->get_button, "Gtk2::Button");

is(Dumper($calbutton->{date}), Dumper($date));
is(Dumper($calbutton->get_date), Dumper($date));

my $window = Gtk2::Window->new;
$window->signal_connect('destroy', sub {Gtk2->main_quit;});

$window->show_all;
