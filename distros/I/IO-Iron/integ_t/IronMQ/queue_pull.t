#!perl -T
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Log::Any::Test;    # should appear before 'use Log::Any'!
use Log::Any qw($log);

use lib 't';
use lib 'integ_t';
require 'iron_io_integ_tests_common.pl'; ## no critic (Modules::RequireBarewordIncludes)

plan tests => 4; # Setup, Do, Verify, Cleanup

require IO::Iron::IronMQ::Client;
require IO::Iron::IronMQ::Queue;
require IO::Iron::IronMQ::Message;

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
use Data::Dumper; $Data::Dumper::Maxdepth = 2;

diag("Testing IO::Iron::IronMQ::Client, Perl $], $^X");

## Test case
diag('Testing IO::Iron::IronMQ::Queue method post_messages()');

my $iron_mq_client;
my $queue_name;
my $queue;
my @send_messages;
my %msg_body_hash_02;

subtest 'Setup for testing' => sub {
    plan tests => 2;
    # Create an IronMQ client.
    $iron_mq_client = IO::Iron::IronMQ::Client->new( 'config' => 'iron_mq.json' );
    # Create a new queue name.
    $queue_name = create_unique_queue_name();
    # Create a new queue.
    $queue = $iron_mq_client->create_and_get_queue( 'name' => $queue_name,
            'message_timeout' => 60, # When reading from queue, after timeout (in seconds), item will be placed back onto queue.
            'message_expiration' => 60, # How long in seconds to keep the item on the queue before it is deleted.
        );
    isa_ok($queue, 'IO::Iron::IronMQ::Queue', 'create_and_get_queue returns a IO::Iron::IronMQ::Queue.');
    is($queue->name(), $queue_name, 'Created queue has the given name.');
    diag('Created message queue ' . $queue_name . q{.});

    # Let's create some messages
    my $iron_mq_msg_send_01 = IO::Iron::IronMQ::Message->new(
            'body' => 'My message #01',
            );
    use YAML::Tiny; # For serializing/deserializing a hash.
    %msg_body_hash_02 = (msg_body_text => 'My message #02', msg_body_item => {sub_item => 'Sub text'});
    my $yaml = YAML::Tiny->new(); $yaml->[0] = \%msg_body_hash_02;
    my $msg_body = $yaml->write_string();
    my $iron_mq_msg_send_02 = IO::Iron::IronMQ::Message->new(
            'body' => $msg_body,
            'delay' => 0, # The item will not be available on the queue until this many seconds have passed.
            );
    my $iron_mq_msg_send_03 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #03' );
    my $iron_mq_msg_send_04 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #04' );
    my $iron_mq_msg_send_05 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #05' );
    my $iron_mq_msg_send_06 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #06' );
    diag('Created 6 messages for sending.');
    push @send_messages, $iron_mq_msg_send_01, $iron_mq_msg_send_02, $iron_mq_msg_send_03, $iron_mq_msg_send_04, $iron_mq_msg_send_05, $iron_mq_msg_send_06;
};

my @sent_msg_ids;
subtest 'Pushing' => sub {
    plan tests => 4;
    #Queue is empty
    my @msg_pulls_00 = $queue->reserve_messages( 'n' => 2, 'timeout' => 120 );
    is(scalar @msg_pulls_00, 0, 'No messages pulled from queue, size 0.');
    is($queue->size(), 0, 'Queue size is 0.');
    diag('Empty queue at the start.');

    @sent_msg_ids = $queue->post_messages( 'messages' => [ @send_messages ] );
    is(scalar @sent_msg_ids, 6, 'Six messages pushed.');
    is($queue->size(), 6, 'Queue size is 6.');
    diag('Total 6 messages pushed to queue.');

};

# Let's pull some messages.
my @msg_pulls;
subtest 'Pulled messages match with the sent messages.' => sub {
    plan tests => 15;

    # $log->clear();
    @msg_pulls = $queue->reserve_messages( 'n' => 3, 'timeout' => 120 );
    is( scalar @msg_pulls, 3, 'Pulled 3 messages.');
    my $yaml_de = YAML::Tiny->new(); $yaml_de = $yaml_de->read_string($msg_pulls[1]->body());
    is_deeply($yaml_de->[0], \%msg_body_hash_02, '#2 message body after serialization matches with the sent message body.');
    is( $msg_pulls[0]->id(), $sent_msg_ids[0], 'Pulled 3 messages, ids match with the sent ids.');
    is( $msg_pulls[1]->id(), $sent_msg_ids[1], 'Pulled 3 messages, ids match with the sent ids.');
    is( $msg_pulls[2]->id(), $sent_msg_ids[2], 'Pulled 3 messages, ids match with the sent ids.');
    is($queue->size(), 6, 'Three messages pulled in total; put queue size is still 6. (pull does not delete messages.)');
    diag('Pulled 3 messages from queue.');

    @msg_pulls = $queue->reserve_messages( 'n' => 7, 'timeout' => 120 );
    is( scalar @msg_pulls, 3, 'Pulled 3 messages but asked for 7.');
    is( $msg_pulls[0]->id(), $sent_msg_ids[3], 'Pulled 6 messages, ids match with the sent ids.');
    is( $msg_pulls[1]->id(), $sent_msg_ids[4], 'Pulled 6 messages, ids match with the sent ids.');
    is( $msg_pulls[2]->id(), $sent_msg_ids[5], 'Pulled 6 messages, ids match with the sent ids.');
    is($queue->size(), 6, 'Three messages pulled in total; put queue size is still 6. (pull does not delete messages.)');
    diag('Pulled 3 messages from queue.');

    # There is no more messages available in the queue for pull to get.
    @msg_pulls = $queue->reserve_messages( 'n' => 7, 'timeout' => 120 );
    is( scalar @msg_pulls, 0, 'Pulled 0 messages but asked for 7.');
    is($queue->size(), 6, 'Three messages pulled in total; put queue size is still 6. (pull does not delete messages.)');
    diag('Pulled 0 messages from queue.');

    my $queue_cleared = $queue->clear_messages();
    is($queue->size(), 0, 'Cleared the queue, queue size is 0.');
    diag('Cleared the queue, queue size is 0.');

    @msg_pulls = $queue->reserve_messages( 'n' => 1, 'timeout' => 120 );
    is( scalar @msg_pulls, 0, 'Pulled 0 messages but asked for 1.');
    diag('Pulled 0 messages from queue.');

};

subtest 'Clean up after us.' => sub {
    plan tests => 2;
    # Let's clear the queue
    my $queue_cleared = $queue->clear_messages();
    is($queue->size(), 0, 'Cleared the queue, queue size is 0.');
    diag('Cleared the queue, queue size is 0.');

    # Delete queue. Confirm deletion.
    $iron_mq_client->delete_queue( 'name' => $queue_name);
    throws_ok {
        my $dummy = $iron_mq_client->get_queue('name' => $queue_name);
    } '/IronHTTPCallException: status_code=404/',
    # IronHTTPCallException: status_code=404 response_message=Queue not found
    # status code 404: server could not find what was requested! Response message can change, code remains 404!
            'Throw IronHTTPCallException when no message queue of given name.';
    diag('Definately deleted message queue ' . $queue->name() . q{'.});
    diag('All cleaned up.')
};

