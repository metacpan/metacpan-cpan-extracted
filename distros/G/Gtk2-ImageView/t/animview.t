# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;

BEGIN {
 use Glib qw/TRUE FALSE/;
 use Gtk2 -init;
 use_ok('Gtk2::ImageView');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $animview = Gtk2::ImageView::Anim->new;
ok(defined $animview, 'new() works');
isa_ok($animview, 'Gtk2::ImageView::Anim');

ok(defined $animview->get_is_playing, 'get_is_playing() works');
