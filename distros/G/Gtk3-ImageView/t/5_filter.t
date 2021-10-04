use warnings;
use strict;
use File::Temp;
use Image::Magick;
use Test::More tests => 10;
use MIME::Base64;

BEGIN {
    use Glib qw/TRUE FALSE/;
    use Gtk3 -init;
    use_ok('Gtk3::ImageView');
    Glib::Object::Introspection->setup(
        basename => 'GdkX11',
        version  => '3.0',
        package  => 'Gtk3::GdkX11',
    );
}

my $window = Gtk3::Window->new('toplevel');
$window->set_size_request( 300, 200 );
my $view = Gtk3::ImageView->new;
$view->set_pixbuf( Gtk3::Gdk::Pixbuf->new_from_file('t/2color.svg'), TRUE );

$window->add($view);
$window->show_all;
my $xid = $window->get_window->get_xid;
$view->set_zoom(15);

$view->set_interpolation('bilinear');
my $image = Image::Magick->new( magick => 'png' );

Glib::Timeout->add(
    1000,
    sub {
        $image->Read("x:$xid");
        Gtk3::main_quit;
        return FALSE;
    }
);
Gtk3::main;

diag('PNG of the blurred window:');
diag( encode_base64( $image->ImageToBlob ) );

my $x      = $image->Get('width') / 2;
my $y      = $image->Get('height') / 2;
my @middle = $image->GetPixel( x => $x, y => $y );
is_deeply( \@middle, [ 1, 0, 0 ], 'middle pixel should be red' );

my $found;
my @pixel;

$found = 0;
while ( $x > 0 ) {
    @pixel = $image->GetPixel( x => $x, y => $y );
    if ( join( ',', @pixel ) ne '1,0,0' ) {
        $found = 1;
        last;
    }
    $x--;
}
is( $found, 1, 'there is non-red outside' );
my $blurred_x = $x;

$found = 0;
while ( $x > 0 ) {
    @pixel = $image->GetPixel( x => $x, y => $y );
    if ( join( ',', @pixel ) eq '0,0,1' ) {
        $found = 1;
        last;
    }
    $x--;
}
is( $found, 1, 'there is blue outside' );
my $fullblue_x = $x;
cmp_ok( $fullblue_x, '<', $blurred_x );

$view->set_interpolation('nearest');
$image = Image::Magick->new( magick => 'png' );

Glib::Timeout->add(
    1000,
    sub {
        $image->Read("x:$xid");
        Gtk3::main_quit;
        return FALSE;
    }
);
Gtk3::main;

diag('PNG of the crisp window:');
diag( encode_base64( $image->ImageToBlob ) );

@pixel = $image->GetPixel( x => $fullblue_x, y => $y );
is_deeply( \@pixel, [ 0, 0, 1 ], 'blue pixel should still be blue' );

$found = 0;
while ( $x <= $blurred_x ) {
    @pixel = $image->GetPixel( x => $x, y => $y );
    if ( join( ',', @pixel ) ne '0,0,1' ) {
        $found = 1;
        last;
    }
    $x++;
}
is( $found, 1, 'there is non-blue inside' );
is_deeply(
    \@pixel,
    [ 1, 0, 0 ],
    'red pixel should be immediatelly near blue one'
);

cmp_ok( $fullblue_x, '<', $x, 'sharp edge should be within blurred edge (1)' );
cmp_ok( $x, '<', $blurred_x,  'sharp edge should be within blurred edge (2)' );
