#!perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( "Cannot load HTML::Object::DOM" );
    use_ok( 'HTML::Object::DOM::Element' ) || BAIL_OUT( "Cannot load HTML::Object::DOM::Element" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

my $p = HTML::Object::DOM->new;
my $doc = $p->new_document;
my $e = HTML::Object::DOM::Element->new( tag => 'div' );
isa_ok( $e, 'HTML::Object::DOM::Element' );
SKIP:
{
    if( !defined( $e ) )
    {
        skip( "cannot create HTML::Object::DOM::Element object", 4 );
    }
    $doc->children->push( $e );
    $e->parent( $doc );
    # $e->debug( $DEBUG );
    # Se the closing tag
    $e->close;
    my $rv = $e->id( 'hello' );
    ok( $rv, '$e->id( "hello" )' );
    is( $e->id, 'hello', '$e->id eq "hello"' );
    $rv = $e->id = 'bye';
    ok( $rv, '$e->id = "bye"' );
    is( $e->id, 'bye', '$e->id eq "bye"' );
};

done_testing();

__END__

