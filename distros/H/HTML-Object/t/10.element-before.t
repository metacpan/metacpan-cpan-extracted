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

my $parser = HTML::Object::DOM->new;
diag( "inserting an element" ) if( $DEBUG );
my $container = $parser->new_element( tag => 'div' );
$container->close;
my $p = $parser->new_element( tag => 'p' );
$p->close;
$container->appendChild( $p );
my $span = $parser->new_element( tag => 'span' );
$span->close;

$p->before( $span );

is( $container->outerHTML, q{<div><span></span><p></p></div>}, '$e->before( $element )' );

$container = $parser->new_element( tag => 'div' );
$container->close;
$p = $parser->new_element( tag => 'p' );
$p->close;
$container->appendChild( $p );
$span = $parser->new_element( tag => 'span' );
$span->close;

$p->before( $span, "Text" );

is( $container->outerHTML, q{<div><span></span>Text<p></p></div>}, '$e->before( $element, "Text" )' );

done_testing();

__END__

