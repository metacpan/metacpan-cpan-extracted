use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;

use lib 't/lib';

use Test::Markdent;

use Markdent::CapturedEvents;
use Markdent::Event::StartDocument;
use Markdent::Event::EndDocument;
use Markdent::Event::Text;
use Markdent::Handler::MinimalTree;

my @events = (
    Markdent::Event::StartDocument->new(),
    Markdent::Event::Text->new( text => 'some text' ),
    Markdent::Event::EndDocument->new(),
);

my $captured = Markdent::CapturedEvents->new( events => \@events );

cmp_deeply(
    [ $captured->events() ],
    \@events,
    '->events() returns expected objects'
);

my $handler = Markdent::Handler::MinimalTree->new();

$captured->replay_events($handler);

cmp_deeply(
    tree_from_handler($handler),
    [
        {
            type => 'text',
            text => 'some text',
        },
    ],
    'replay_events generates expected tree'
);

done_testing();
