# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;

BEGIN {
 use Glib qw/TRUE FALSE/;
 use Gtk2 -init;
 use_ok('Gtk2::ImageView');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $imageview = Gtk2::ImageView->new;

$imageview->set_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file ('t/gnome_logo.jpg'), TRUE);

my $selector = Gtk2::ImageView::Tool::Selector->new($imageview);
ok(defined $selector, 'new() works');
isa_ok($selector, 'Gtk2::ImageView::Tool::Selector');

my $rectangle = $selector->get_selection;
ok(! defined $rectangle, 'get_selection() initially undefined');

ok(! eval {$selector->set_selection(undef)}, '$selector->set_selection(undef) throws error' );

$rectangle = Gtk2::Gdk::Rectangle->new(0,0,10,10);
$selector->set_selection($rectangle);

$rectangle = $selector->get_selection;
ok(defined $rectangle, 'get_selection() works');

isa_ok($rectangle, 'Gtk2::Gdk::Rectangle');

