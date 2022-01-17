#!perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( "Cannot load HTML::Object::DOM" );
};

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
    $e->setHTML = $new;
    my $expect = <<EOT;
<div id="main">
            <p id="hello"><div id="coucou"></div></p>
            <p>world !</p>
        </div>
EOT
    chomp( $expect );
    is( $parent->as_string, $expect, '$e->setHTML = $new' );
    
    my $new2 = $p->new_element( tag => 'span' );
    $new2->close;
    $new2->id( 'my-id' );
    
    $e->setHTML( $new2 );
    my $expect2 = <<EOT;
<div id="main">
            <p id="hello"><span id="my-id"></span></p>
            <p>world !</p>
        </div>
EOT
    chomp( $expect2 );
    is( $parent->as_string, $expect2, '$e->setHTML( $new )' );
    
    $e->setHTML = q{<span lang="en-GB"><img src="https://example.org" alt="My Logo" /></span>};
    my $expect3 = <<EOT;
<div id="main">
            <p id="hello"><span lang="en-GB"><img src="https://example.org" alt="My Logo" /></span></p>
            <p>world !</p>
        </div>
EOT
    chomp( $expect3 );
    is( $parent->as_string, $expect3, '$e->setHTML = q{<span></span>}' );
    
    $e->setHTML( q{<h1>Done !</h1>} );
    my $expect4 = <<EOT;
<div id="main">
            <p id="hello"><h1>Done !</h1></p>
            <p>world !</p>
        </div>
EOT
    chomp( $expect4 );
    is( $parent->as_string, $expect4, '$e->setHTML( q{<h1>Done !</h1>} )' );
};

done_testing();

__END__

