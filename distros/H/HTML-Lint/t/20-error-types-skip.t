#!perl -Tw

use strict;
use warnings;
use Test::More tests => 8;

use HTML::Lint;
use HTML::Lint::Error ':types';

my $text = do { local $/ = undef; <DATA> };

FUNC_METHOD: {
    my $lint = HTML::Lint->new();
    isa_ok( $lint, 'HTML::Lint' );
    $lint->parse( $text );
    $lint->eof;
    is( scalar $lint->errors, 1, 'One error with a clean lint' );

    $lint->newfile();
    $lint->clear_errors();
    $lint->only_types( HELPER, FLUFF );
    $lint->parse( $text );
    $lint->eof;
    is( scalar $lint->errors, 0, 'No errors if helper & fluff' );

    $lint->newfile();
    $lint->clear_errors();
    $lint->only_types( STRUCTURE );
    $lint->parse( $text );
    $lint->eof;
    my @errors = $lint->errors;
    if ( !is( scalar @errors, 1, 'One error if we specify STRUCTURE if we turn it off' ) ) {
        diag( $_->as_string ) for @errors;
    }
}

CONSTRUCTOR_METHOD_SCALAR: {
    my $lint = HTML::Lint->new( only_types => STRUCTURE );
    isa_ok( $lint, 'HTML::Lint' );

    $lint->parse( $text );
    my @errors = $lint->errors;
    if ( !is( scalar @errors, 1, 'One error if we specify STRUCTURE if we turn it off' ) ) {
        diag( $_->as_string ) for @errors;
    }
}

CONSTRUCTOR_METHOD_ARRAYREF: {
    my $lint = HTML::Lint->new( only_types => [HELPER, FLUFF] );
    isa_ok( $lint, 'HTML::Lint' );
    $lint->parse( $text );
    is( scalar $lint->errors, 0, 'No errors if helper & fluff' );
}



__DATA__
<HTML>
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
        <TABLE>This is my paragraph
    </BODY>
</HTML>
