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

my $parser = HTML::Object::DOM->new;
diag( "inserting an element" ) if( $DEBUG );
my $container = $parser->new_element( tag => 'div' );
$container->close;
my $p = $parser->new_element( tag => 'p' );
$p->close;
$container->appendChild( $p ) || do
{
    diag( "Error with appendChild: ", $container->error ) if( $DEBUG );
};
my $span = $parser->new_element( tag => 'span' );
$span->close;

$p->after( $span );

is( $container->outerHTML, q{<div><p></p><span></span></div>}, '$e->after( $element )' );

$container = $parser->new_element( tag => 'div' );
$container->close;
$p = $parser->new_element( tag => 'p' );
$p->close;
$container->appendChild( $p );
$span = $parser->new_element( tag => 'span' );
$span->close;

$p->after( $span, "Text" );

is( $container->outerHTML, q{<div><p></p><span></span>Text</div>}, '$e->after( $element, "Text" )' );

done_testing();

__END__

