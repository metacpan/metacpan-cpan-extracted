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
    use_ok( 'HTML::Object::DOM::Element' ) || BAIL_OUT( "Cannot load HTML::Object::Element::DOM" );
    use_ok( 'HTML::Object::ElementDataMap' ) || BAIL_OUT( "Cannot load HTML::Object::ElementDataMap" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

my $p = HTML::Object::DOM->new;
my $doc = $p->new_document;
my $e = $p->new_element( tag => 'div' );
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
    my $data = $e->dataset;
    isa_ok( $data, 'HTML::Object::ElementDataMap' );
    my $rv = $data->dateOfBirth( '1989-12-01' );
    ok( $rv, 'data attribute set' );
    diag( $doc->as_string ) if( $DEBUG );
    my $str = $doc->as_string;
    is( $str, q{<div data-date-of-birth="1989-12-01"></div>}, 'resulting string' );
    my $val = $e->dataset->dateOfBirth;
    is( $val, '1989-12-01' );
};

done_testing();

__END__

