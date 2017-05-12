# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;

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

my $iimagetool = Gtk2::ImageView::Tool::Dragger->new($imageview);
ok(defined $iimagetool, 'new() works');
isa_ok($iimagetool, 'Gtk2::ImageView::Tool::Dragger');

