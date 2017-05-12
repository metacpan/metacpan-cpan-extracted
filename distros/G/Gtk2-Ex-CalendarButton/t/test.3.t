use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 qw/-init/;
use Gtk2::Ex::CalendarButton;
use Data::Dumper;

use Gtk2::TestHelper tests => 3;

my $year = 2007;
my $month = 3;
my $day = 14;
my $date = [$year, $month, $day];

my $calbutton = Gtk2::Ex::CalendarButton->new();
my $event_count = 0;
$calbutton->signal_connect('date-changed' => 
    sub {
        my ($self) = @_;
        is(Dumper($self), Dumper($calbutton));
        $event_count++;
        is($event_count, 1);
    }
);

$calbutton->{calendar}->select_month($month, $year);
$calbutton->{calendar}->select_day($day);
$calbutton->_update_button_label;

is(Dumper($calbutton->{date}), Dumper($date));


my $window = Gtk2::Window->new;
$window->signal_connect('destroy', sub {Gtk2->main_quit;});

$window->show_all;
