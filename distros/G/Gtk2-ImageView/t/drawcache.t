# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 19;

BEGIN {
 use Glib qw/TRUE FALSE/;
 use Gtk2 -init;
 use_ok('Gtk2::ImageView');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $cache = Gtk2::Gdk::Pixbuf::Draw::Cache->new;
ok(defined $cache, 'new() works');

ok(defined $cache->{last_pixbuf}, '$cache{last_pixbuf} defined');
ok(defined $cache->{old}, '$cache{old} defined');
ok(defined $cache->{check_size}, '$cache{check_size} defined');

can_ok('Gtk2::Gdk::Pixbuf::Draw::Cache', 'new', 'free', 'invalidate', 'draw');

my $opts = $cache->{old};
ok(defined $opts->{zoom}, '$opts{zoom} defined');
ok(defined $opts->{zoom_rect}, '$opts{zoom_rect} defined');
ok(defined $opts->{widget_x}, '$opts{widget_x} defined');
ok(defined $opts->{widget_y}, '$opts{widget_y} defined');
ok(defined $opts->{interp}, '$opts{interp} defined');
ok(defined $opts->{pixbuf}, '$opts{pixbuf} defined');
ok(defined $opts->{check_color1}, '$opts{check_color1} defined');
ok(defined $opts->{check_color2}, '$opts{check_color2} defined');

my $method = Gtk2::Gdk::Pixbuf::Draw::Cache->get_method($opts, $opts);
ok(($method eq 'contains' or $method eq 'scale' or $method eq 'scroll'), 'get_method');

eval{Gtk2::Gdk::Pixbuf::Draw::Cache->get_method(undef, undef)};
like($@, qr/Expected/, 'A TypeError is raised when get_method() is called with an argument that is not a PixbufDrawOpts object.');

eval{Gtk2::Gdk::Pixbuf::Draw::Cache->get_method($opts, undef)};
like($@, qr/Expected/, 'A TypeError is raised when get_method() is called with an argument that is not a PixbufDrawOpts object.');

eval{Gtk2::Gdk::Pixbuf::Draw::Cache->get_method(undef, $opts)};
like($@, qr/Expected/, 'A TypeError is raised when get_method() is called with an argument that is not a PixbufDrawOpts object.');

eval{Gtk2::Gdk::Pixbuf::Draw::Cache->get_method('Hello', 'Foo')};
like($@, qr/Expected/, 'A TypeError is raised when get_method() is called with an argument that is not a PixbufDrawOpts object.');
