use strict;
use warnings;
use Test2::V0;

use IO::Async::Pg::PubSub;

subtest 'constructor' => sub {
    my $pubsub = IO::Async::Pg::PubSub->new();

    isa_ok $pubsub, 'IO::Async::Pg::PubSub';
    is $pubsub->subscribed_channels, 0, 'no channels initially';
    ok !$pubsub->is_connected, 'not connected initially';
};

subtest 'channel name validation' => sub {
    my $pubsub = IO::Async::Pg::PubSub->new();

    # Valid channel names
    ok $pubsub->_validate_channel('my_channel'), 'valid: lowercase and underscore';
    ok $pubsub->_validate_channel('Channel123'), 'valid: mixed case and numbers';
    ok $pubsub->_validate_channel('a'), 'valid: single char';

    # Invalid channel names
    ok !$pubsub->_validate_channel(''), 'invalid: empty';
    ok !$pubsub->_validate_channel('has space'), 'invalid: contains space';
    ok !$pubsub->_validate_channel('has;semicolon'), 'invalid: contains semicolon';
    ok !$pubsub->_validate_channel("has\nnewline"), 'invalid: contains newline';
};

done_testing;
