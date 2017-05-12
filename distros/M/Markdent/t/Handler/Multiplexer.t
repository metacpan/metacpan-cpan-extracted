use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;

use File::Slurp qw( read_file );

use Markdent::Handler::CaptureEvents;
use Markdent::Handler::MinimalTree;
use Markdent::Handler::Multiplexer;
use Markdent::Parser;

use lib 't/lib';

use Test::Markdent;

my $markdown
    = read_file('t/mdtest-data/Markdown Documentation - Basics.text');

my $th1 = Markdent::Handler::MinimalTree->new();
my $th2 = Markdent::Handler::MinimalTree->new();

my $multi = Markdent::Handler::Multiplexer->new( handlers => [ $th1, $th2 ] );

my $parser = Markdent::Parser->new( handler => $multi );
$parser->parse( markdown => $markdown );

cmp_deeply(
    tree_from_handler($th1),
    tree_from_handler($th2),
    'compare parsing from trees generated from multiplexer'
);

done_testing();
