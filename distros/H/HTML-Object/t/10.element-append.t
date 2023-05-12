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
diag( "appending an element" ) if( $DEBUG );
my $div = $parser->new_element( tag => 'div' );
$div->close;
my $p = $parser->new_element( tag => 'p' );
$p->close;
$div->append( $p );
is( $div->childNodes->length, 1, 'p appended to div' );
is( $div->as_string, '<div><p></p></div>', '$div->append( $element )' );

$div = $parser->new_element( tag => 'div' );
$div->close;
$p = $parser->new_element( tag => 'p' );
$p->close;
# $div->debug( $DEBUG ) if( $DEBUG );
$div->append( "Some text", $p );
is( $div->childNodes->length, 2, 'text and p appended to div' );
is( $div->as_string, '<div>Some text<p></p></div>', '$div->append( "Some text", $element )' );

done_testing();

__END__

