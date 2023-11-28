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

my $doc = $parser->parse_data( q{<div id="divA">This is <span>some</span> text!</div>} ) || 
    BAIL_OUT( $parser->error );

my $div = $doc->getElementById('divA');
# diag( "div is -> ", $div->as_string ) if( $DEBUG );
# $div->debug( $DEBUG );
my $text = $div->textContent;
# The text variable is now: 'This is some text!'
is( $text, 'This is some text!', 'textContent initial value' );

$div->textContent = 'This text is different!';
# The HTML for divA is now:
# <div id="divA">This text is different!</div>
is( $div->textContent, 'This text is different!', 'textContent' );

done_testing();

__END__

