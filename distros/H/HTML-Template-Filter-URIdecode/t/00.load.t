# -*- perl -*-

# t/00.load.t - check module loading and create testing directory

use Test::More tests => 1;
BEGIN {
    use_ok( 'HTML::Template::Filter::URIdecode' );
}
