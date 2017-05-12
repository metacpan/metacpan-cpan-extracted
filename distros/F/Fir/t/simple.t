#!perl
use strict;
use warnings;
use Test::More tests => 8;
use_ok('Fir');

my $fir  = Fir->new;
my $home = Fir::Major->new();
$home->name('Home');
$home->path('/');
my $about = Fir::Major->new();
$about->name('About');
$about->path('/about/');
my $leon = Fir::Minor->new();
$leon->name('Leon');
$leon->path('/about/leon/');
my $jake = Fir::Minor->new();
$jake->name('Jake');
$jake->path('/about/jake/');
$fir->add_major($home);
$fir->add_major( $about, $leon, $jake );

$fir->path('/');
is( $fir->as_string, '*Home* /
About /about/
', '/'
);

$fir->path('/xyzzy/');
is( $fir->as_string, '*Home* /
About /about/
', '/xyzzy/'
);

$fir->path('/about/');
is( $fir->as_string, 'Home /
*About* /about/
  Leon /about/leon/
  Jake /about/jake/
', '/about/'
);

$fir->path('/about/leon/');
is( $fir->as_string, 'Home /
About /about/
  *Leon* /about/leon/
  Jake /about/jake/
', '/about/leon/'
);

$fir->path('/about/leon/more/');
is( $fir->as_string, 'Home /
About /about/
  *Leon* /about/leon/
  Jake /about/jake/
', '/about/leon/more/'
);

$fir->path('/about/jake/');
is( $fir->as_string, 'Home /
About /about/
  Leon /about/leon/
  *Jake* /about/jake/
', '/about/jake/'
);

$fir->path('/about/dangermouse/');
is( $fir->as_string, 'Home /
*About* /about/
  Leon /about/leon/
  Jake /about/jake/
', '/about/dangermouse/'
);

my $root = $fir->root;
foreach my $major ( $root->daughters ) {
    if ( $major->is_selected ) {
        print '*' . $major->name . '* ' . $major->path . "\n";
    } else {
        print $major->name . ' ' . $major->path . "\n";
    }
    if ( $major->is_open ) {
        foreach my $minor ( $major->daughters ) {
            if ( $minor->is_selected ) {
                print $minor->name . '* ' . $minor->path . "\n";
            } else {
                print $minor->name . ' ' . $minor->path . "\n";
            }
        }
    }
}

