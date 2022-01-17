#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM' );
    use_ok( 'HTML::Object::DOM::Collection' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM::Collection' );
};

my $p = HTML::Object::DOM->new;
my $col = HTML::Object::DOM::Collection->new;
isa_ok( $col => 'HTML::Object::DOM::Collection' );
my $doc = $p->new_document;
my $span = $doc->createElement( 'span' );
$col->push( $span );
my $form = $doc->createElement( 'form', name => 'myForm' );
$col->push( $form );
my $input = $doc->createElement( 'input', type => 'text', id => 'fullname', name => 'customer_name' );
$form->appendChild( $input );
my $button = $doc->createElement( 'button', vakue => 'Ok' );
$form->appendChild( $button );
my $div = $doc->createElement( 'div', id => 'myDiv' );
is( $div->as_string, q{<div id="myDiv"></div>}, 'div -> as_string' );
$col->push( $div );
is( $col->length, 3, 'length' );
my $elem = $col->myDiv;
isa_ok( $elem => 'HTML::Object::DOM::Element' );
SKIP:
{
    if( !defined( $elem ) )
    {
        skip( 'no div with id \"MyDiv\" could be found', 1 );
    }
    is( $elem->attr( 'id' ), 'myDiv', 'col->myDIv' );
};
my $first = $col->first;
isa_ok( $first, 'HTML::Object::DOM::Element', 'first' );
SKIP:
{
    if( !defined( $first ) )
    {
        skip( 'no span element could be found', 1 );
    }
    is( $first->getName, 'span', 'inheriting methods' );
};

done_testing();

__END__

