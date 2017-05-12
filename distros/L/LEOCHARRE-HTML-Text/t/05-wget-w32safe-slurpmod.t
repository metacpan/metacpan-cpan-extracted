use Config::Auto;
use FindBin qw/$Bin/;
use lib './lib';
use LEOCHARRE::HTML::Text ':all';

use Test::More tests => 4;



my $test_url = "http://yahoo.com";
ok( LEOCHARRE::HTML::Text::_slurp_url_safe_w32($test_url), "called _slurp_url_safe_w32");
ok( LEOCHARRE::HTML::Text::_slurp_url_linux($test_url), "called _slurp_url_linux()");
ok( LEOCHARRE::HTML::Text::_slurp_url($test_url), "called _slurp_url(), alias to _slurp_url_safe_w32");
ok( LEOCHARRE::HTML::Text::slurp_url($test_url), "called slurp_url(), alias to _slurp_url_safe_w32");

