use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Data::Dumper;
use Gtk2::Ex::DateRange;

use Gtk2::TestHelper tests => 2;

my $daterange = Gtk2::Ex::DateRange->new;
isa_ok($daterange, "Gtk2::Ex::DateRange");
$daterange->set_model([ 'after', '1965-03-12', 'and', 'before', '1989-02-14' ]);

my $label = Gtk2::Label->new('Click-Here');
my $popup = $daterange->attach_popup_to($label);

isa_ok($popup, "Gtk2::Ex::PopupWindow");


