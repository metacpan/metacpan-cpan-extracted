#!perl

use warnings;
use strict;

use Test::More tests => 4;

use Test::Builder::Tester;
use Test::HTML::Lint;

my $not_so_good_html = <<'HTML';
<p>
    This is a valid fragment (with some errors), but an incomplete document.
    <img src="alpha.jpg" height="21" width="12">
    <input type="image">
</p>
HTML

HTML_OK: {
    test_out( 'not ok 1 - Called html_ok' );
    test_fail( +8 );
    test_diag( 'Errors: Called html_ok' );
    test_diag( ' (3:5) <img src="alpha.jpg"> does not have ALT text defined' );
    test_diag( ' (4:5) <input name="" type="image"> does not have non-blank ALT text defined' );
    test_diag( ' (5:1) <body> tag is required' );
    test_diag( ' (5:1) <head> tag is required' );
    test_diag( ' (5:1) <html> tag is required' );
    test_diag( ' (5:1) <title> tag is required' );
    html_ok( $not_so_good_html, 'Called html_ok' );
    test_test( 'html_ok works on wonky fragment' );
}

HTML_FRAGMENT_OK: {
    test_out( 'not ok 1 - Called html_fragment_ok' );
    test_fail( +4 );
    test_diag( 'Errors: Called html_fragment_ok' );
    test_diag( ' (3:5) <img src="alpha.jpg"> does not have ALT text defined' );
    test_diag( ' (4:5) <input name="" type="image"> does not have non-blank ALT text defined' );
    html_fragment_ok( $not_so_good_html, 'Called html_fragment_ok' );
    test_test( 'html_fragment_ok works on wonky fragment' );
}


# HTML that is a valid fragment, but not a valid document.
my $ok_fragment = <<'HTML';
<p>
    This is a valid fragment (with some errors), but an incomplete document.
    <img src="alpha.jpg" height="21" width="12" alt="alpha">
    <input type="image" alt="foo">
</p>
HTML

HTML_OK: {
    test_out( 'not ok 1 - Called html_ok' );
    test_fail( +6 );
    test_diag( 'Errors: Called html_ok' );
    test_diag( ' (5:1) <body> tag is required' );
    test_diag( ' (5:1) <head> tag is required' );
    test_diag( ' (5:1) <html> tag is required' );
    test_diag( ' (5:1) <title> tag is required' );
    html_ok( $ok_fragment, 'Called html_ok' );
    test_test( 'html_ok gets back doc-level errors on fragment' );
}

HTML_FRAGMENT_OK: {
    test_out( 'ok 1 - Called html_fragment_ok' );
    html_fragment_ok( $ok_fragment, 'Called html_fragment_ok' );
    test_test( 'html_fragment_ok passes on fragment' );
}
