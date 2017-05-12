#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
require JSON::MaybeXS;

use lib 't';
use lib 'integ_t';
require 'iron_io_integ_tests_common.pl'; ## no critic (Modules::RequireBarewordIncludes)

require IO::Iron::IronMQ::Client;
require IO::Iron::IronMQ::Message;

# use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
use Data::Dumper; $Data::Dumper::Maxdepth = 2;

diag("Testing IO::Iron::IronMQ::Client, Perl $], $^X");

## Test case
diag('Testing IO::Iron::IronMQ::Client');
diag('This test is deactivated because Alerts are not part of free plan anymore, maybe!');

my $iron_mq_client;
my $unique_queue_name_01;
my $unique_queue_name_02;
my $unique_queue_name_03;
my @send_messages;
my $normal_queue;
my $alert_queue;
subtest 'Setup for testing' => sub {
    # Create an IronMQ client.
    $iron_mq_client = IO::Iron::IronMQ::Client->new( 'config' => 'iron_mq.json' );

    # Create new queue names.
    $unique_queue_name_01 = create_unique_queue_name() . '_normal';
    $unique_queue_name_02 = create_unique_queue_name() . '_push_to';
    $unique_queue_name_03 = create_unique_queue_name() . '_alert';

    # Create new queues.
    $normal_queue = $iron_mq_client->create_and_get_queue(
    		'name' => $unique_queue_name_01,
    	);
    isa_ok($normal_queue, 'IO::Iron::IronMQ::Queue', 'create_and_get_queue returns a IO::Iron::IronMQ::Queue.');
    is($normal_queue->name(), $unique_queue_name_01, 'Created queue has the given name.');
    diag('Created push_from (normal) message queue \'' . $unique_queue_name_01 . q{\'.});
    $alert_queue = $iron_mq_client->create_and_get_queue( 'name' => $unique_queue_name_03 );
    isa_ok($alert_queue, 'IO::Iron::IronMQ::Queue', 'create_and_get_queue returns a IO::Iron::IronMQ::Queue.');
    is($alert_queue->name(), $unique_queue_name_03, 'Created queue has the given name.');
    diag('Created alert message queue \'' . $unique_queue_name_03 . q{\'.});

    # Let's add an alert to normal_queue.
    my $alert_added = $iron_mq_client->add_alerts(
    	'name' => $normal_queue->name(),
    	'alerts' => [
    			{
    				'type' => 'fixed',
    				'queue' => $alert_queue->name(),
    				'trigger' => 1,
    				'direction' => 'asc',
    				'snooze' => 0,
    			}
    		],
    	);
    # my $normal_queue_info = $iron_mq_client->get_queue_info(
    # 	'name' => $normal_queue->name()
    # 	);
    # #diag('normal_queue_info: ' . Dumper($normal_queue_info) );
    # #diag('normal_queue_info(alerts): ' . Dumper($normal_queue_info->{'alerts'}) );
    # is(scalar @{$normal_queue_info->{'queue'}->{'alerts'}}, 1, 'Number of alerts is 1.');

    # Let's create some messages
    my $iron_mq_msg_send_01 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #01' );
    my $iron_mq_msg_send_02 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #02' );
    my $iron_mq_msg_send_03 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #03' );
    my $iron_mq_msg_send_04 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #04' );
    my $iron_mq_msg_send_05 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #05' );
    my $iron_mq_msg_send_06 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #06' );
    push @send_messages, $iron_mq_msg_send_01, $iron_mq_msg_send_02, $iron_mq_msg_send_03,
    	$iron_mq_msg_send_04, $iron_mq_msg_send_05, $iron_mq_msg_send_06;
    diag('Created 6 messages for sending.');

    done_testing;
};

# my @send_message_ids;
# subtest 'Push the first message' => sub {
#     #Queue is empty
#     my @msg_pulls_00 = $alert_queue->reserve_messages( 'n' => 2, 'timeout' => 120 );
#     is(scalar @msg_pulls_00, 0, 'No messages pulled from alert queue, size 0.');
#     is($alert_queue->size(), 0, 'alert Queue size is 0.');
#     diag('Empty alert queue at the start.');
#
#     # Let's send the messages.
#     my $msg_send_id_01 = $normal_queue->post_messages( 'messages' => [ $send_messages[0] ] );
#     diag('Waiting until alert queue has a message...');
#     until ($alert_queue->size() > 0) { ## no critic (ControlStructures::ProhibitUntilBlocks, ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions)
#     	sleep 1;
#     	diag('Waiting until alert queue has a message...');
#     }
#     is($alert_queue->size(), 1, 'One message pushed, alert queue size is 1.');
#     push @send_message_ids, $msg_send_id_01;
#
#     done_testing;
# };

# my @msg_pulls_01;
# subtest 'Push and pull' => sub {
#     # Let's pull some messages.
#     @msg_pulls_01 = $alert_queue->reserve_messages();
#     #diag('IO::Iron::IronMQ::Message: ' . Dumper($msg_pulls_01[0]));
#     my $json = JSON::MaybeXS->new(utf8 => 1, pretty => 1);
#     my $alert_msg_content = $json->decode($msg_pulls_01[0]->body());
#     #diag(Dumper($alert_msg_content));
#     is($alert_msg_content->{'queue_size'}, 1, 'Alert message says queue size was 1.');
#     is($alert_msg_content->{'source_queue'}, $normal_queue->name(), 'Error came from normal queue.');
#     $alert_queue->delete( 'ids' => [ $msg_pulls_01[0]->id() ]);
#     is($alert_queue->size(), 0, 'One message pulled and deleted, error queue size is 0.');
#
#     # Reconfigure alerts.
#     # Change the one alert to two alerts.
#     my $alert_replaced = $iron_mq_client->replace_alerts(
#     	'name' => $normal_queue->name(),
#     	'alerts' => [
#     			{
#     				'type' => 'fixed',
#     				'queue' => $alert_queue->name(),
#     				'trigger' => 2,
#     				'direction' => 'desc',
#     				'snooze' => 0,
#     			},
#     			{
#     				'type' => 'fixed',
#     				'queue' => $alert_queue->name(),
#     				'trigger' => 5,
#     				'direction' => 'desc',
#     				'snooze' => 5,
#     			},
#     		],
#     	);
#     # my $normal_queue_info = $iron_mq_client->get_queue_info(
#     # 	'name' => $normal_queue->name()
#     # 	);
#     # #diag('normal_queue_info: ' . Dumper($normal_queue_info) );
#     # #diag('normal_queue_info(alerts): ' . Dumper($normal_queue_info->{'alerts'}) );
#     # is(scalar @{$normal_queue_info->{'queue'}->{'alerts'}}, 2, 'Number of alerts is 2.');
#     # is($normal_queue_info->{'queue'}->{'alerts'}->[0]->{'trigger'}, 2, 'Alert trigger is now 2.');
#     # my $alert_id = $normal_queue_info->{'queue'}->{'alerts'}->[0]->{'id'};
#     # diag('normal_queue_info(alert id): ' . $alert_id );
#
#     # Delete alert
#     throws_ok {
#     	my $alert_deleted = $iron_mq_client->delete_alerts(
#     	'name' => $normal_queue->name(),
#     	'alerts' => [
#     			{ 'id' => $alert_id, },
#     		],
#     	'id' => $alert_id,
#     	);
#     } '/Either parameter/',
#     		'Params::Validate throws exception when when using both \'alerts\' and \'id\' parameters.';
#
#     # First delete by giving a list of id. Then by id.
#     my $alert_deleted = $iron_mq_client->delete_alerts(
#     	'name' => $normal_queue->name(),
#     	'alerts' => [
#     			{ 'id' => $alert_id, },
#     		],
#     	);
#     # $normal_queue_info = $iron_mq_client->get_queue_info(
#     # 	'name' => $normal_queue->name()
#     # 	);
#     # #diag('normal_queue_info: ' . Dumper($normal_queue_info) );
#     # #diag('normal_queue_info(alerts): ' . Dumper($normal_queue_info->{'alerts'} ) );
#     # is(scalar @{$normal_queue_info->{'queue'}->{'alerts'}}, 1, 'Number of alerts is 1.');
#     # $alert_id = $normal_queue_info->{'queue'}->{'alerts'}->[0]->{'id'};
#     # diag('normal_queue_info(alert id): ' . $alert_id );
#
#     $alert_deleted = $iron_mq_client->delete_alerts(
#     	'name' => $normal_queue->name(),
#     	'id' => $alert_id,
#     	);
#     # $normal_queue_info = $iron_mq_client->get_queue_info(
#     # 	'name' => $normal_queue->name()
#     # 	);
#     # #diag('normal_queue_info: ' . Dumper($normal_queue_info) );
#     # is($normal_queue_info->{'queue'}->{'alerts'}, undef, 'No alerts array item => no alerts.');
#
#
# #    # Update the first queue to a normal queue (from a push queue).
# #    $normal_queue = $iron_mq_client->update_queue(
# #    		'name' => $unique_queue_name_01,
# #    		'push_type' => 'pull',
# #    	);
# #    isa_ok($normal_queue, 'IO::Iron::IronMQ::Queue', 'create_and_get_queue returns a IO::Iron::IronMQ::Queue.');
# #    is($normal_queue->name(), $unique_queue_name_01, 'Created queue has the given name.');
# #    diag('Updated push_from message queue ' . $unique_queue_name_01 . ' to a normal queue.');
#
#     done_testing;
# };

subtest 'Clean up.' => sub {
    # Let's clear the queues
    $normal_queue->clear_messages();
    is($normal_queue->size(), 0, 'Cleared the normal queue, queue size is 0.');
    diag('Cleared the normal queue, queue size is 0.');
    $alert_queue->clear_messages();
    is($alert_queue->size(), 0, 'Cleared the error queue, queue size is 0.');
    diag('Cleared the error queue, queue size is 0.');

    # Delete queues. Confirm deletion.
    $iron_mq_client->delete_queue( 'name' => $unique_queue_name_01 );
    diag('Deleted message queue \'' . $normal_queue->name() . q{\'.});
    $iron_mq_client->delete_queue( 'name' => $unique_queue_name_03 );
    diag('Deleted message queue \'' . $alert_queue->name() . q{\'.});

    done_testing;
};

done_testing;

