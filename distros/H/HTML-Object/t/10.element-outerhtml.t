#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( "Cannot load HTML::Object::DOM" );
};

use strict;
use warnings;

my $p = HTML::Object::DOM->new;
my $html = <<EOT;
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <title>outerHTML demo</title>
    </head>
    <body>
        <div id="main">
            <p id="hello">Hello</p>
            <p>world !</p>
        </div>
    </body>
</html>
EOT
my $doc = $p->parse( $html );
isa_ok( $doc, 'HTML::Object::Document' );
# $doc->debug( $DEBUG );
my $e = $doc->getElementById( 'hello' );
isa_ok( $e, 'HTML::Object::Element' );
SKIP:
{
    if( !defined( $e ) )
    {
        skip( "cannot find HTML::Object::Element object with id 'hello'", 3 );
        diag( "Error is: ", $doc->error ) if( $DEBUG );
    }
    my $str = $e->outerHTML;
    is( $str, q{<p id="hello">Hello</p>}, '$e->outerHTML' );
    my $new = $p->new_element( tag => 'div' );
    $new->close;
    $new->id( 'coucou' );
    # $new->debug($DEBUG);
    my $parent = $e->parent;
    $str = $e->as_string;
    # diag( $str ) if( $DEBUG );
    diag( "Replacing '$str' with '", $new->as_string, "'" ) if( $DEBUG );
    $e->outerHTML = $new;
    # diag( $parent->as_string ) if( $DEBUG );
    my $expect = <<EOT;
<div id="main">
            <div id="coucou"></div>
            <p>world !</p>
        </div>
EOT
    chomp( $expect );
    is( $parent->as_string, $expect, '$e->outerHTML = $new' );
    
    my $new2 = $p->new_element( tag => 'div' );
    $new2->close;
    $new2->id( 'my-id' );
    my $e2 = $doc->getElementById( 'coucou' );
    if( !defined( $e2 ) )
    {
        skip( "cannot find HTML::Object::Element object with id 'my-id'", 1 );
    }
    $e2->outerHTML( $new2 );
    my $expect2 = <<EOT;
<div id="main">
            <div id="my-id"></div>
            <p>world !</p>
        </div>
EOT
    chomp( $expect2 );
    is( $parent->as_string, $expect2, '$e->outerHTML( $new )' );
};

done_testing();

__END__

