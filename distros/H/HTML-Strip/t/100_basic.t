use Test::More tests => 7;

use HTML::Strip;

my $hs = HTML::Strip->new();

is( $hs->parse( 'test' ), 'test', 'works with plain text' );
$hs->eof;

is( $hs->parse( '<em>test</em>' ), 'test', 'works with <em>|</em> tags' );
$hs->eof;

is( $hs->parse( 'foo<br>bar' ), 'foo bar', 'works with <br> tag' );
$hs->eof;

is( $hs->parse( '<p align="center">test</p>' ), 'test', 'works with tags with attributes' );
$hs->eof;

is( $hs->parse( '<foo>bar' ), 'bar', 'strips <foo> tags' );
is( $hs->parse( '</foo>baz' ), ' baz', 'strips </foo> tags' );
$hs->eof;

is( $hs->parse( '<!-- <p>foo</p> bar -->baz' ), 'baz', 'strip comments' );
$hs->eof;
