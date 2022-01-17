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
        skip( "cannot find HTML::Object::Element object with id 'hello'", 1 );
        diag( "Error is: ", $doc->error ) if( $DEBUG );
    }
    # $e->xp->debug(4);
    ok( $e->matches( '#hello' ), '$e->matches( "#hello" )' );
    my $nodes = $e->parentElement->find( '#hello', { root => '.' } );
    if( $nodes )
    {
        diag( "Found ", $nodes->length, " matches: '", $nodes->first, "' -> ", $nodes->first->as_string ) if( $DEBUG );
    }
    else
    {
        diag( "Error: ", $doc->error ) if( $DEBUG );
    }
}

SKIP:
{
    my $div = $doc->getElementById( 'main' );
    if( !defined( $div ) )
    {
        skip( "cannot find HTML::Object::Element object with id 'main'", 1 );
    }
    ok( !$div->matches( '#hello' ), '$div->matches( "#hello" )' );
};

SKIP:
{
    my $e2 = $e->nextElementSibling();
    if( !defined( $e2 ) )
    {
        skip( "cannot find sibling of element with id 'hello'", 1 );
    }
    diag( "Checking match for id 'hello' against element '", $e2->as_string, "'" ) if( $DEBUG );
    ok( !$e2->matches( '#hello' ), '$div->matches( "#hello" )' );
};

done_testing();

__END__

