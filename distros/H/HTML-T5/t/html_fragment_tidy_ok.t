#!perl

use 5.010001;
use warnings;
use strict;

use Test::More tests => 3;

use Test::Builder::Tester;
use Test::HTML::T5;

subtest 'html_fragment_tidy_ok fails on undef' => sub {
    plan tests => 1;

    my $msg = 'Fails on undef';
    test_out( "not ok 1 - $msg" );
    test_fail( +2 );
    test_diag( 'Error: html_fragment_tidy_ok() got undef' );
    html_fragment_tidy_ok( undef, $msg );
    test_test( $msg );
};


subtest 'html_tidy_ok fails on a fragment, but html_fragment_tidy_ok is OK' => sub {
    plan tests => 2;

    my $html = <<'HTML';
<p>
    This is an incomplete document but it's structurally OK.
    <img src="alpha.jpg" height="21" width="12" alt="alpha">
    <input type="image">
</p>
HTML

    my $msg = 'Called html_tidy_ok on incomplete document';
    test_out( "not ok 1 - $msg" );
    test_fail( +6 );
    test_diag( "Errors: $msg" );
    test_diag( '(1:1) Warning: missing <!DOCTYPE> declaration' );
    test_diag( '(1:1) Warning: inserting implicit <body>' );
    test_diag( '(1:1) Warning: inserting missing \'title\' element' );
    test_diag( '3 messages on the page' );
    html_tidy_ok( $html, $msg );
    test_test( $msg );

    $msg = 'html_fragment_tidy_ok can handle it';
    test_out( "ok 1 - $msg" );
    html_fragment_tidy_ok( $html, $msg );
    test_test( $msg );
};


subtest 'html_fragment_tidy_ok gets the same errors as html_tidy_ok' => sub {
    plan tests => 2;

    my $html = <<'HTML';
<p>
    This is an incomplete document, and it has structural </td> errors.
    <img src="alpha.jpg" height="21" width="12">
</p>
HTML

    my $msg = 'html_tidy_ok on sloppy doc';
    test_out( "not ok 1 - $msg" );
    test_fail( +8 );
    test_diag( "Errors: $msg" );
    test_diag( '(1:1) Warning: missing <!DOCTYPE> declaration' );
    test_diag( '(1:1) Warning: inserting implicit <body>' );
    test_diag( '(2:59) Warning: discarding unexpected </td>' );
    test_diag( '(1:1) Warning: inserting missing \'title\' element' );
    test_diag( '(3:5) Warning: <img> lacks "alt" attribute' );
    test_diag( '5 messages on the page' );
    html_tidy_ok( $html, $msg );
    test_test( $msg );

    # Note that the line numbers are the same between html_tidy_ok and html_fragment_tidy_ok.
    $msg = 'html_fragment_tidy_ok on sloppy doc';
    test_out( "not ok 1 - $msg" );
    test_fail( +5 );
    test_diag( "Errors: $msg" );
    test_diag( '(2:59) Warning: discarding unexpected </td>' );
    test_diag( '(3:5) Warning: <img> lacks "alt" attribute' );
    test_diag( '2 messages on the page' );
    html_fragment_tidy_ok( $html, $msg );
    test_test( $msg );
};

exit 0;
