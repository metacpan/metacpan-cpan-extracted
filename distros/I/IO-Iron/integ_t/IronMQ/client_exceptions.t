#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;

use lib q{.};
use lib 'integ_t';
require 'iron_io_integ_tests_common.pl'; ## no critic (Modules::RequireBarewordIncludes)

plan tests => 13;

require IO::Iron::IronMQ::Client;

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
#use Data::Dumper; $Data::Dumper::Maxdepth = 1;

diag("Testing IO::Iron::IronMQ::Client, Perl $], $^X");

## Test case
## Create queue, query queue, delete queue.
## Test with multiple queues.
diag('Testing IO::Iron::IronMQ::Client');

# Create an IronMQ client.
my $iron_mq_client = IO::Iron::IronMQ::Client->new( 'config' => 'iron_mq.json' );

# Create a new queue names.
my $unique_queue_name_01 = create_unique_queue_name();
my $faulty_queue_name = $unique_queue_name_01 . q{!&[};

throws_ok {
    my $queried_iron_mq_queue_01 = $iron_mq_client->create_and_get_queue( 'name' => $faulty_queue_name );
} '/RFC 3986 reserved character check/',
        'Params::Validate throws exception when creating a message queue with faulty characters (RFC 3986 reserved character check) in its name.';
diag('Creating a queue with forbidden characters (RFC 3986 reserved characters) in name \'' . $unique_queue_name_01 . '\' fails.');


throws_ok {
    my $queried_iron_mq_queue_01 = $iron_mq_client->get_queue( 'name' => $unique_queue_name_01 );
} 'IronHTTPCallException',
        'Throw IO::Iron::IronMQ::Exceptions::HTTPException when no message queue of given name.';
throws_ok {
    my $queried_iron_mq_queue_01 = $iron_mq_client->get_queue( 'name' => $unique_queue_name_01 );
} '/IronHTTPCallException: status_code=404 response_message=Queue not found/',
        'Throw IO::Iron::IronMQ::Exceptions::HTTPException when no message queue of given name.';
diag('Tried to get queue ' . $unique_queue_name_01 . ' which doesn\'t exist.');

## Create a new queue.
my $created_iron_mq_queue_01;
lives_ok {
    $created_iron_mq_queue_01 = $iron_mq_client->create_and_get_queue( 'name' => $unique_queue_name_01 );
} 'Creating queue should not fail.';
isa_ok($created_iron_mq_queue_01, 'IO::Iron::IronMQ::Queue', 'create_and_get_queue returns a IO::Iron::IronMQ::Queue.');
is($created_iron_mq_queue_01->name(), $unique_queue_name_01, 'Created queue has the given name.');
diag('Created message queue ' . $unique_queue_name_01 . q{.});

# Query the created queue.
my $queried_iron_mq_queue_01 = $iron_mq_client->get_queue( 'name' => $unique_queue_name_01 );
isa_ok($queried_iron_mq_queue_01 , 'IO::Iron::IronMQ::Queue', 'create_and_get_queue returns a IO::Iron::IronMQ::Queue.');
is($queried_iron_mq_queue_01->size(), 0, 'Queried queue size is 0.');
my $queried_iron_mq_queue_info_01 = $iron_mq_client->get_queue_info( 'name' => $unique_queue_name_01 )->{'queue'};
is($queried_iron_mq_queue_01->size(), $queried_iron_mq_queue_info_01->{'size'}, 'Queried queue size matches with queried info.');

diag('Queried message queue ' . $unique_queue_name_01 . q{.});


## Query all queues.
my @all_queues = $iron_mq_client->get_queues();
my @found_queues;
foreach my $queue (@all_queues) {
    if($queue->name() eq $unique_queue_name_01
        #|| $queue->name() eq $unique_queue_name_02 
        #|| $queue->name() eq $unique_queue_name_03
        ) {
        push @found_queues, $queue;
    }
}
is(scalar @found_queues, 1, 'get_queues returned the one created queue.');

# Delete queue. Confirm deletion.
throws_ok {
    my $delete_queue_ret_01 = $iron_mq_client->delete_queue( 'name' => 'Non_existing_queue_name' );
} 'IronHTTPCallException',
        'Throw IO::Iron::IronMQ::Exceptions::HTTPException when no message queue of given name.';
throws_ok {
    my $delete_queue_ret_01 = $iron_mq_client->delete_queue( 'name' => 'Non_existing_queue_name' );
} '/IronHTTPCallException: status_code=404 response_message=Queue not found/',
        'Throw IO::Iron::IronMQ::Exceptions::HTTPException when no message queue of given name.';
diag('Tried to delete a non-existing message queue \'Non_existing_queue_name\'' . q{.});

$iron_mq_client->delete_queue( 'name' => $unique_queue_name_01 );
throws_ok {
    my $delete_queue_ret_01 = $iron_mq_client->get_queue( 'name' => $unique_queue_name_01 );
} 'IronHTTPCallException',
        'Throw IO::Iron::IronMQ::Exceptions::HTTPException when no message queue of given name.';
diag('Deleted message queue ' . $created_iron_mq_queue_01->name() . q{.});

