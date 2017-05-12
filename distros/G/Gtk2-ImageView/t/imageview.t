# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 29;

BEGIN {
 use Glib qw/TRUE FALSE/;
 use Gtk2 -init;
 use_ok('Gtk2::ImageView');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $version = Gtk2::ImageView->library_version;
ok(defined $version, "library version $version");

$version = $Gtk2::ImageView::VERSION;
ok(defined $version, "bindings version $version");

my $view = Gtk2::ImageView->new;
ok(defined $view, 'new() works');
isa_ok($view, 'Gtk2::ImageView');

ok(defined $view->get_tool, 'get_tool() works');

# The default tool is Gtk2::ImageView::Tool::Dragger.
isa_ok($view->get_tool, 'Gtk2::ImageView::Tool::Dragger');

$view->set_pixbuf(Gtk2::Gdk::Pixbuf->new_from_file ('t/gnome_logo.jpg'), TRUE);

isa_ok($view->get_viewport, 'Gtk2::Gdk::Rectangle');

isa_ok($view->get_draw_rect, 'Gtk2::Gdk::Rectangle');

ok($view->get_check_colors, 'get_check_colors() works');

ok(defined $view->get_fitting, 'get_fitting() works');

ok(defined $view->get_pixbuf, 'get_pixbuf() works');

ok(defined $view->get_zoom, 'get_zoom() works');

ok(Gtk2::ImageView::Zoom->get_min_zoom < Gtk2::ImageView::Zoom->get_max_zoom, 'Ensure that the gtkimageview.zooms_* functions are present and work as expected.');

ok(defined $view->get_black_bg, 'get_black_bg() works');

ok(defined $view->get_show_frame, 'get_show_frame() works');

ok(defined $view->get_interpolation, 'get_interpolation() works');

ok(defined $view->get_show_cursor, 'get_show_cursor() works');

eval{$view->set_pixbuf('Hi mom!', TRUE)};
like($@, qr/type/, 'A TypeError is raised when set_pixbuf() is called with something that is not a pixbuf.');

$view->set_pixbuf(undef, TRUE);
ok(! $view->get_pixbuf, 'correctly cleared pixbuf');

ok(! $view->get_viewport, 'correctly cleared viewport');

ok(! $view->get_draw_rect, 'correctly cleared draw rectangle');

$view->size_allocate(Gtk2::Gdk::Rectangle->new(0, 0, 100, 100));
$view->set_pixbuf(Gtk2::Gdk::Pixbuf->new(GDK_COLORSPACE_RGB, FALSE, 8, 50, 50));
my $rect = $view->get_viewport;
ok(($rect->x == 0 and $rect->y == 0
    and $rect->width == 50 and $rect->height == 50),
    'Ensure that getting the viewport of the view works as expected.');

can_ok($view, qw(get_check_colors));

$rect = $view->get_draw_rect;
ok(($rect->x == 25 and $rect->y == 25
   and $rect->width == 50 and $rect->height == 50),
   'Ensure that getting the draw rectangle works as expected.');

$view->set_pixbuf(Gtk2::Gdk::Pixbuf->new(GDK_COLORSPACE_RGB, FALSE, 8, 200, 200));
$view->set_zoom(1);
$view->set_offset(0, 0);
$rect = $view->get_viewport;
ok(($rect->x == 0 and $rect->y == 0), 'Ensure that setting the offset works as expected.');

$view->set_offset(100, 100, TRUE);
$rect = $view->get_viewport;
ok(($rect->x == 100 and $rect->y == 100), 'Ensure that setting the offset works as expected.');

$view->set_transp('color', 0xff0000);
my ($col1, $col2) = $view->get_check_colors;
ok(($col1 == 0xff0000 and $col2 == 0xff0000), 'Ensure that setting the views transparency settings works as expected.');
$view->set_transp('grid');

ok(defined Glib::Type->list_values ('Gtk2::ImageView::Transp'), 'Check GtkImageTransp enum.');
