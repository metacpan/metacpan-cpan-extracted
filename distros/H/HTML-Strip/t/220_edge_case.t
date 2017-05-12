use Test::More tests => 5;

use HTML::Strip;

# test for RT#21008

# stripping comments 
my $hs = HTML::Strip->new();
is( $hs->parse( "a<>b" ), "a b", 'edge case with <> ok' );
$hs->eof;

is( $hs->parse( "a<>b c<>d" ), "a b c d", 'edge case with <>s ok' );
$hs->eof;

is( $hs->parse( "From: <>\n\na. Title: some text\n\nb. etc\n" ), "From: \n\na. Title: some text\n\nb. etc\n", 'test case' ); 

is( $hs->parse( "From: <>\n\na. Title: some text\n\nb. etc\n" ), "From: \n\na. Title: some text\n\nb. etc\n", 'test case' ); 
$hs->eof; 

is( $hs->parse( q{this is an "example" with 'quoted' parts that should not be stripped} ), q{this is an "example" with 'quoted' parts that should not be stripped} ); 
