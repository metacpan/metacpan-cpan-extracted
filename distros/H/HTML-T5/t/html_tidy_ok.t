#!perl

use 5.010001;
use warnings;
use strict;

use Test::More tests => 5;

use Test::Builder::Tester;
use Test::HTML::T5;


subtest 'html_tidy_ok fails on undef' => sub {
    plan tests => 1;

    my $msg = 'Fails on undef';
    test_out( "not ok 1 - $msg" );
    test_fail( +2 );
    test_diag( 'Error: html_tidy_ok() got undef' );
    html_tidy_ok( undef, $msg );
    test_test( $msg );
};


subtest 'html_tidy_ok without errors' => sub {
    plan tests => 1;

    my $html = <<'HTML';
<!DOCTYPE html>
<html>
    <head>
        <title> </title>
    </head>
    <body>
        <p>
            This is a full document.
            <img src="alpha.jpg" height="21" width="12" alt="alpha">
            <input type="image">
        </p>
    </body>
</html>
HTML

    test_out( 'ok 1 - Called html_tidy_ok on full document' );
    html_tidy_ok( $html, 'Called html_tidy_ok on full document' );
    test_test( 'html_tidy_ok on full document works' );
};


subtest 'html_tidy_ok with failures' => sub {
    plan tests => 1;

    my $html = <<'HTML';
<p>
    This is an incomplete document, and it has some errors besides that as well.
    <img src="alpha.jpg" height="21" width="12">
    <input type="image">
</p>
<p>
HTML

    test_out( 'not ok 1 - Called html_tidy_ok on incomplete document' );
    test_fail( +8 );
    test_diag( 'Errors: Called html_tidy_ok on incomplete document' );
    test_diag( '(1:1) Warning: missing <!DOCTYPE> declaration' );
    test_diag( '(1:1) Warning: inserting implicit <body>' );
    test_diag( '(1:1) Warning: inserting missing \'title\' element' );
    test_diag( '(3:5) Warning: <img> lacks "alt" attribute' );
    test_diag( '(6:1) Warning: trimming empty <p>' );
    test_diag( '5 messages on the page' );
    html_tidy_ok( $html, 'Called html_tidy_ok on incomplete document' );
    test_test( 'html_tidy_ok works on incomplete document' );
};


subtest 'Test passing our own Tidy object' => sub {
    plan tests => 3;

    my $html = <<'HTML';
<!DOCTYPE html>
<html>
    <head>
        <title> </title>
    </head>
    <body>
        <p>
            This is a complete document, with an empty paragraph.
            <img src="alpha.jpg" height="21" width="12" alt="alpha">
            <input type="image">
        </p>
        <p>
    </body>
</html>
HTML

    # Default html_tidy_ok() complains about empty paragraph.
    test_out( 'not ok 1 - Empty paragraph' );
    test_fail( +4 );
    test_diag( 'Errors: Empty paragraph' );
    test_diag( '(12:9) Warning: trimming empty <p>' );
    test_diag( '1 message on the page' );
    html_tidy_ok( $html, 'Empty paragraph' );
    test_test( 'html_tidy_ok works on empty paragraph' );

    # Now make our own more relaxed Tidy object and it should pass.
    my $tidy = HTML::T5->new( { drop_empty_elements => 0 } );
    isa_ok( $tidy, 'HTML::T5' );
    test_out( 'ok 1 - Relaxed tidy' );
    html_tidy_ok( $tidy, $html, 'Relaxed tidy' );
    test_test( 'html_tidy_ok with user-specified tidy works' );
};


subtest 'Reusing a tidy object' => sub {
    plan tests => 7;

    my $tidy = HTML::T5->new();
    isa_ok( $tidy, 'HTML::T5' );

    my $very_bad_html = <<'HTML';
<!DOCTYPE html>
<html>
    <head>
        <title> One error </title>
    </head>
    <body>
        <p>
            This is just bad.
            <img bingo="Bango">
        <table>
    </body>
</html>
HTML

    # Very bad HTML.
    test_out( 'not ok 1 - Very bad HTML' );
    test_fail( +7 );
    test_diag( 'Errors: Very bad HTML' );
    test_diag( '(10:9) Warning: missing </table> before </body>' );
    test_diag( '(9:13) Warning: <img> lacks "alt" attribute' );
    test_diag( '(9:13) Warning: <img> lacks "src" attribute' );
    test_diag( '(10:9) Warning: trimming empty <table>' );
    test_diag( '4 messages on the page' );
    html_tidy_ok( $tidy, $very_bad_html, 'Very bad HTML' );
    test_test( 'html_tidy_ok works on very bad HTML' );
    is( scalar $tidy->messages, 4, 'We have four messages' );

    # Make sure the next use of html_tidy_ok() and the tidy doesn't have leftover messages.
    my $kinda_bad_html = <<'HTML';
<!DOCTYPE html>
<html>
    <head>
        <title> One error </title>
    </head>
    <body>
        <p>
            This is a complete document with an extra unclosed paragraph.
            <img src="alpha.jpg" height="21" width="12" alt="alpha">
            <input type="image">
        </p>
        <p>
    </body>
</html>
HTML

    # Kinda bad HTML only has one error.
    test_out( 'not ok 1 - Empty paragraph' );
    test_fail( +4 );
    test_diag( 'Errors: Empty paragraph' );
    test_diag( '(12:9) Warning: trimming empty <p>' );
    test_diag( '1 message on the page' );
    html_tidy_ok( $tidy, $kinda_bad_html, 'Empty paragraph' );
    test_test( 'html_tidy_ok works on empty paragraph' );
    is( scalar $tidy->messages, 1, 'We have one message' );

    my $good_html = <<'HTML';
<!DOCTYPE html>
<html>
    <head>
        <title> All good </title>
    </head>
    <body>
        <p>
            Good HTML
        </p>
    </body>
</html>
HTML

    # The good HTML should have no warnings at all.
    test_out( 'ok 1 - Good HTML' );
    html_tidy_ok( $tidy, $good_html, 'Good HTML' );
    test_test( 'Reusing tidy object with good HTML works' );
    is( scalar $tidy->messages, 0, 'We have no messages' );
};


done_testing();
exit 0;
