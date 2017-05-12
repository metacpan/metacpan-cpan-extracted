use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;

use File::Slurp qw( read_file );

use Markdent::Handler::CaptureEvents;
use Markdent::Handler::MinimalTree;
use Markdent::Parser;

use lib 't/lib';

use Test::Markdent;

my $markdown
    = read_file('t/mdtest-data/Markdown Documentation - Basics.text');

my $ch  = Markdent::Handler::CaptureEvents->new();
my $th1 = Markdent::Handler::MinimalTree->new();

for my $handler ( $ch, $th1 ) {
    my $parser = Markdent::Parser->new( handler => $handler );
    $parser->parse( markdown => $markdown );
}

my $th2 = Markdent::Handler::MinimalTree->new();
$ch->captured_events()->replay_events($th2);

cmp_deeply(
    tree_from_handler($th1),
    tree_from_handler($th2),
    'compare parse direct to tree versus replaying captured events into a tree'
);

done_testing();
