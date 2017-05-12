#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Log::Any qw($log);

use lib 't';
use lib 'integ_t';
require 'iron_io_integ_tests_common.pl'; ## no critic (Modules::RequireBarewordIncludes)

plan tests => 4; # Setup, Do, Verify, Cleanup

require IO::Iron::IronMQ::Client;

#     Attn! Do not use the "use Log::Any" and "use Log::Any::Adapter" at the same time!!
#     Otherwise can't use Log::Any::Test
# use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
#use Data::Dumper; $Data::Dumper::Maxdepth = 2;

diag("Testing IO::Iron::IronMQ::Client, Perl $], $^X");

## Test case
diag('Testing IO::Iron::IronMQ::Client method create_and_get_queue().');

my $iron_mq_client;
my $queue_name;
my $created_queue;
my $queried_queue;

subtest 'Setup for testing. Confirm queue not exists.' => sub {
    # Create an IronMQ client.
    $iron_mq_client = IO::Iron::IronMQ::Client->new( 'config' => 'iron_mq.json' );
    # Create a new queue name.
    $queue_name = create_unique_queue_name();
    is(1, 1, 'Everything ok.');
    throws_ok { $iron_mq_client->get_queue( 'name' => $queue_name) } 'IronHTTPCallException', 'Received exception because queue not exists.';
    diag("Setup ready. Queue name: '$queue_name'. Queue not exists.");

    done_testing;
};

subtest 'Create queue' => sub {
    # Create a new queue.
    $iron_mq_client->create_and_get_queue( 'name' => $queue_name );
    $created_queue = $iron_mq_client->get_queue( 'name' => $queue_name );
    isa_ok($created_queue, 'IO::Iron::IronMQ::Queue', 'Method create_and_get_queue() returns a IO::Iron::IronMQ::Queue.');
    is($created_queue->name(), $queue_name, 'Created queue has the given name.');
    # Queue is empty
    is($created_queue->size(), 0, 'Created queue size is 0.');
    diag("Created message queue '$queue_name'.");

    done_testing;
};

subtest 'Confirm result' => sub {
    $queried_queue = $iron_mq_client->get_queue( 'name' => $queue_name );
    is($queried_queue->name(), $created_queue->name(), 'Queried queue has the same name as created queue.');
    is($queried_queue->size(), 0, 'Queried queue size is 0.');
    my $previous = q{};
    my @all_queue_names;
    while ( my @queue_names = $iron_mq_client->list_queues( 'per_page' => 5, 'previous' => $previous ) ) {
        push @all_queue_names, @queue_names;
        $previous = $queue_names[-1];
    }
    my $found = grep { $_ eq $created_queue->name() } @all_queue_names;
    isnt $found, undef, 'Queue not found.';
    diag('Confirmed result.');

    done_testing;
};

subtest 'Clean up' => sub {
    # Delete queue. Confirm deletion.
    $iron_mq_client->delete_queue(  'name' => $queue_name );
    throws_ok { $iron_mq_client->get_queue( 'name' => $queue_name) } 'IronHTTPCallException', 'Received exception because queue not exists.';
    diag('All cleaned up.');

    done_testing;
};

