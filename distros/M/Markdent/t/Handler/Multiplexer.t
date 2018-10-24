use strict;
use warnings;

use Test2::V0;

use File::Slurper qw( read_text );

use Markdent::Handler::CaptureEvents;
use Markdent::Handler::MinimalTree;
use Markdent::Handler::Multiplexer;
use Markdent::Parser;

use lib 't/lib';

use Test::Markdent;

my $markdown
    = read_text('t/mdtest-data/Markdown Documentation - Basics.text');

my $th1 = Markdent::Handler::MinimalTree->new();
my $th2 = Markdent::Handler::MinimalTree->new();

my $multi = Markdent::Handler::Multiplexer->new( handlers => [ $th1, $th2 ] );

my $parser = Markdent::Parser->new( handler => $multi );
$parser->parse( markdown => $markdown );

is(
    tree_from_handler($th1),
    tree_from_handler($th2),
    'compare parsing from trees generated from multiplexer'
);

done_testing();
