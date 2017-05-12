#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

require IO::Iron;
require IO::Iron::IronMQ::Client;
require IO::Iron::IronMQ::Queue;
require IO::Iron::IronMQ::Message;

BEGIN {
	use_ok('IO::Iron::IronMQ::Client') || BAIL_OUT('Cannot find class!');
	can_ok('IO::Iron::IronMQ::Client', 'new');
	can_ok('IO::Iron::IronMQ::Client', 'get_queue');
	can_ok('IO::Iron::IronMQ::Client', 'get_queues');
	can_ok('IO::Iron::IronMQ::Client', 'create_and_get_queue');
	can_ok('IO::Iron::IronMQ::Client', 'create_queue');
	can_ok('IO::Iron::IronMQ::Client', 'get_queue_info');
	can_ok('IO::Iron::IronMQ::Client', 'update_queue');
	can_ok('IO::Iron::IronMQ::Client', 'delete_queue');
	can_ok('IO::Iron::IronMQ::Client', 'list_queues');
	can_ok('IO::Iron::IronMQ::Client', 'add_subscribers');
	can_ok('IO::Iron::IronMQ::Client', 'delete_subscribers');
	can_ok('IO::Iron::IronMQ::Client', 'add_alerts');
	can_ok('IO::Iron::IronMQ::Client', 'replace_alerts');
	can_ok('IO::Iron::IronMQ::Client', 'delete_alerts');

	use_ok('IO::Iron::IronMQ::Queue') || BAIL_OUT('Cannot find class!');
	can_ok('IO::Iron::IronMQ::Queue', 'new');
	can_ok('IO::Iron::IronMQ::Queue', 'size');
	can_ok('IO::Iron::IronMQ::Queue', 'post_messages');
	can_ok('IO::Iron::IronMQ::Queue', 'reserve_messages');
	can_ok('IO::Iron::IronMQ::Queue', 'peek_messages');
	can_ok('IO::Iron::IronMQ::Queue', 'delete_message');
	can_ok('IO::Iron::IronMQ::Queue', 'delete_messages');
	can_ok('IO::Iron::IronMQ::Queue', 'touch_message');
	can_ok('IO::Iron::IronMQ::Queue', 'release_message');
	can_ok('IO::Iron::IronMQ::Queue', 'clear_messages');
	can_ok('IO::Iron::IronMQ::Queue', 'get_push_statuses');
	# Attributes
	can_ok('IO::Iron::IronMQ::Queue', 'ironmq_client');
	can_ok('IO::Iron::IronMQ::Queue', 'name');
	can_ok('IO::Iron::IronMQ::Queue', 'connection');
	can_ok('IO::Iron::IronMQ::Queue', 'last_http_status_code');

	use_ok('IO::Iron::IronMQ::Message') || BAIL_OUT('Cannot find class!');
	can_ok('IO::Iron::IronMQ::Message', 'new');
	# Attributes
	can_ok('IO::Iron::IronMQ::Message', 'body');
	can_ok('IO::Iron::IronMQ::Message', 'delay');
	can_ok('IO::Iron::IronMQ::Message', 'push_headers');
	can_ok('IO::Iron::IronMQ::Message', 'id');
	can_ok('IO::Iron::IronMQ::Message', 'reserved_count');
	can_ok('IO::Iron::IronMQ::Message', 'reservation_id');
}

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.

diag(
    'Testing IO::Iron::IronMQ::Client '
      . (
        $IO::Iron::IronMQ::Client::VERSION
        ? "($IO::Iron::IronMQ::Client::VERSION)"
        : '(no version)'
      )
      . ", Perl $], $^X"
);

done_testing();

