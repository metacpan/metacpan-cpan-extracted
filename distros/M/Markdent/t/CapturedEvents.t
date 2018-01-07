use strict;
use warnings;

use Test2::V0;

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

is(
    [ $captured->events() ],
    \@events,
    '->events() returns expected objects'
);

my $handler = Markdent::Handler::MinimalTree->new();

$captured->replay_events($handler);

is(
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
