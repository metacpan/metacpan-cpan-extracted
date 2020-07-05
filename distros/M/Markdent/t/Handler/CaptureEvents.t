use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/../../t/lib";

use File::Slurper qw( read_text );
use Markdent::Handler::CaptureEvents;
use Markdent::Handler::MinimalTree;
use Markdent::Parser;
use Test2::V0;
use Test::Markdent;

my $markdown
    = read_text(
    "$Bin/../../t/mdtest-data/Markdown Documentation - Basics.text");

my $ch  = Markdent::Handler::CaptureEvents->new();
my $th1 = Markdent::Handler::MinimalTree->new();

for my $handler ( $ch, $th1 ) {
    my $parser = Markdent::Parser->new( handler => $handler );
    $parser->parse( markdown => $markdown );
}

my $th2 = Markdent::Handler::MinimalTree->new();
$ch->captured_events()->replay_events($th2);

is(
    tree_from_handler($th1),
    tree_from_handler($th2),
    'compare parse direct to tree versus replaying captured events into a tree'
);

done_testing();
