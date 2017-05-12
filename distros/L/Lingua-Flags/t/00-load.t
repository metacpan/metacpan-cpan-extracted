#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'Lingua::Flags' );
}

ok(!as_gif("XPTO"));
ok(!as_html_img("XPTO"));
ok(as_gif("PT"));
ok(as_html_img("PT"));
