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
my $doc = $parser->new_document;
my $div = $doc->createElement("div");
my $p = $doc->createElement("p");
my $span = $doc->createElement("span");
$div->append($p);
$div->prepend($span);

# Array object containing <span>, <p>
my $list = $div->childNodes;
is( $list->first->tag, 'span', 'prepend -> first element' );
is( $list->second->tag, 'p', 'prepend -> second element' );

done_testing();

__END__

