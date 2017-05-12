# http://rt.cpan.org/Public/Bug/Display.html?id=32355

use Test::More tests => 2;

use HTML::Strip;

subtest declarations => sub {
    plan tests => 1;

    my $hs = HTML::Strip->new();
    is( $hs->parse( q{<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"><html>Text</html>} ),
        "Text", 'decls are stripped' );
    $hs->eof;
};

subtest comments => sub {
    plan tests => 5;

    my $hs = HTML::Strip->new();
    is( $hs->parse( q{<html><!-- a comment to be stripped -->Hello World!</html>} ),
        "Hello World!", "comments are stripped" );
    $hs->eof;

    is( $hs->parse( q{<html><!-- comment with a ' apos -->Hello World!</html>} ), 
        "Hello World!", q{comments may contain '} );
    $hs->eof;

    is( $hs->parse( q{<html><!-- comment with a " quote -->Hello World!</html>} ), 
        "Hello World!", q{comments may contain "} );
    $hs->eof;

    is( $hs->parse( q{<html><!-- comment -- "quote" >Hello World!</html>} ), 
        "Hello World!", "weird decls are stripped" );
    $hs->eof;

    is( $hs->parse( "a<>b" ),
        "a b", 'edge case with <> ok' );
};
