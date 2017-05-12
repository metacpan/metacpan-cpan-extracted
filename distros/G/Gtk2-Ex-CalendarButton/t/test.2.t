use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 qw/-init/;
use Gtk2::Ex::CalendarButton;
use Data::Dumper;

use Gtk2::TestHelper tests => 1;

my $date = [2007,3,14];

my $calbutton = Gtk2::Ex::CalendarButton->new($date);
is(Dumper($calbutton->{date}), Dumper($date));

my $window = Gtk2::Window->new;
$window->signal_connect('destroy', sub {Gtk2->main_quit;});

$window->show_all;
