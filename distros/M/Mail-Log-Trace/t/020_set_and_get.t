#!/usr/bin/perl

use strict;
use warnings;
use Test::Warn;
use Test::More tests => 132;
use Test::Exception;
use Test::Deep;

use Mail::Log::Trace;
use Mail::Log::Trace::Postfix;
use Mail::Log::Exceptions;

#local $TODO = 'help!';

TRACE: {
### Test the working. ###
my $object = Mail::Log::Trace->new({'log_file' => 't/data/log'});

is($object->get_log(), 't/data/log', 'Mail::Log::Trace inital log');

# Test overloads.
is("$object", 'Mail::Log::Trace File: t/data/log', 'Mail::Log::Trace stringification.');
ok(!$object, 'Mail::Log::Trace boolean coersion.');
throws_ok { $object + 1 } 'Mail::Log::Exceptions';

# Build another one.  Just to make sure we aren't clobbering ourselves...
my $object2 = Mail::Log::Trace->new({'log_file' => 't/data/log'});


# 'Before' tests.
is($object->get_log(), 't/data/log', 'Mail::Log::Trace before set log');
is($object->get_from_address(), undef, 'Mail::Log::Trace before from address');
is($object->get_to_address(), undef, 'Mail::Log::Trace before to address');
is($object->get_message_id(), undef, 'Mail::Log::Trace before message ID');
is($object->get_recieved_time(), undef, 'Mail::Log::Trace before recieved time.');
is($object->get_sent_time(), undef, 'Mail::Log::Trace before sent time.');
is($object->get_relay(), undef, 'Mail::Log::Trace before sent relay.');
is($object->get_connect_time(), undef, 'Mail::Log::Trace before connect time.');
is($object->get_disconnect_time(), undef, 'Mail::Log::Trace before disconnect time.');
is($object->get_delay(), undef, 'Mail::Log::Trace before delay.');
is($object->get_all_info(), undef, 'Mail::Log::Trace before all info.');
is($object->get_subject(), undef, 'Mail::Log::Trace before subject.');
# Private gets.
is($object->_get_parser_class(), undef, 'Mail::Log::Trace before parser.');

# Set some values.
$object->set_log('t/data/log2');
$object->set_from_address('from@example.com');
$object->set_to_address([qw(to@example.com to2@example to3@example.com)]);
$object->set_message_id('message.id.test');
$object->set_recieved_time('time');
$object->set_sent_time('time');
$object->set_relay('mail.example.com');
$object->set_parser_class('Mail::Log::Parse::Test');
$object->set_subject('Test Subject');
# These are 'private', local to the object tree.
$object->_set_connect_time(19088445);
$object->_set_disconnect_time(29884455);
$object->_set_delay(0.4);
$object->_set_message_raw_info({to_address => [qw(hello hi)]});

# 'After' tests.
is($object->get_log(), 't/data/log2', 'Mail::Log::Trace set log');
is($object->get_from_address(), 'from@example.com', 'Mail::Log::Trace From address');
cmp_deeply($object->get_to_address(), bag(qw(to@example.com to2@example to3@example.com)), 'Mail::Log::Trace To address');
is($object->get_message_id(), 'message.id.test', 'Mail::Log::Trace message ID');
is($object->get_recieved_time(), 'time', 'Mail::Log::Trace recieved time.');
is($object->get_sent_time(), 'time', 'Mail::Log::Trace sent time.');
is($object->get_relay(), 'mail.example.com', 'Mail::Log::Trace relay.');
is($object->get_connect_time(), 19088445, 'Mail::Log::Trace connect time.');
is($object->get_disconnect_time(), 29884455, 'Mail::Log::Trace disconnect time.');
is($object->get_delay(), 0.4, 'Mail::Log::Trace delay.');
is_deeply($object->get_all_info(), {to_address => [qw(hello hi)]}, 'Mail::Log::Trace all info.');
is($object->get_subject(), 'Test Subject', 'Mail::Log::Trace subject.');
# Private gets.
is($object->_get_parser_class(), 'Mail::Log::Parse::Test', 'Mail::Log::Trace parser.');

# And test the other object.  Just to be sure.
is($object2->get_log(), 't/data/log', 'Mail::Log::Trace object2 set log');
is($object2->get_from_address(), undef, 'Mail::Log::Trace object2 from address');
is($object2->get_to_address(), undef, 'Mail::Log::Trace object2 to address');
is($object2->get_message_id(), undef, 'Mail::Log::Trace object2 message ID');
is($object2->get_recieved_time(), undef, 'Mail::Log::Trace object2 recieved time.');
is($object2->get_sent_time(), undef, 'Mail::Log::Trace object2 sent time.');
is($object2->get_relay(), undef, 'Mail::Log::Trace object2 sent relay.');
is($object2->get_connect_time(), undef, 'Mail::Log::Trace object2 connect time.');
is($object2->get_disconnect_time(), undef, 'Mail::Log::Trace object2 disconnect time.');
is($object2->get_delay(), undef, 'Mail::Log::Trace object2 delay.');
is($object2->get_all_info(), undef, 'Mail::Log::Trace object2 all info.');
is($object2->get_subject(), undef, 'Mail::Log::Trace object2 subject.');
# Private gets.
is($object2->_get_parser_class(), undef, 'Mail::Log::Trace before parser.');


# Test the constructor shortcut.
$object = Mail::Log::Trace->new({log_file 		=> 't/data/log'
								,from_address	=> 'from2@example.com'
								,to_address		=> 'to2@example.com'
								,message_id		=> 'message2.id.test'
								,recieved_time	=> 'rtime2'
								,sent_time		=> 'stime3'
								,relay			=> 'mail2.example.com'
								});

# 'After' tests.
is($object->get_log(), 't/data/log', 'Mail::Log::Trace set log, constructor.');
is($object->get_from_address(), 'from2@example.com', 'Mail::Log::Trace From address, constructor.');
is_deeply($object->get_to_address(), ['to2@example.com'], 'Mail::Log::Trace To address, constructor.');
is($object->get_message_id(), 'message2.id.test', 'Mail::Log::Trace message ID, constructor.');
is($object->get_recieved_time(), 'rtime2', 'Mail::Log::Trace recieved time, constructor.');
is($object->get_sent_time(), 'stime3', 'Mail::Log::Trace sent time, constructor.');
is($object->get_relay(), 'mail2.example.com', 'Mail::Log::Trace relay, constructor.');
is($object->get_connect_time(), undef, 'Mail::Log::Trace connect time, constructor.');
is($object->get_disconnect_time(), undef, 'Mail::Log::Trace disconnect, time, constructor.');


# Something slightly complicated with the 'to' address.
$object->add_to_address('to2@example.com');
is_deeply($object->get_to_address(), ['to2@example.com'], 'Mail::Log::Trace To address, after dupe.');
$object->add_to_address('to3@example.com');
is_deeply($object->get_to_address(), ['to2@example.com','to3@example.com'], 'Mail::Log::Trace To address, after addition.');
$object->add_to_address('to4@example.com');
$object->add_to_address(\'to5@example.com');
is_deeply($object->get_to_address(), ['to2@example.com','to3@example.com','to4@example.com'], 'Mail::Log::Trace To address, after second addition.');
$object->remove_to_address('to3@example.com');
is_deeply($object->get_to_address(), ['to2@example.com','to4@example.com'], 'Mail::Log::Trace To address, after dupe.');

### Test the non-working. ###
throws_ok {$object = Mail::Log::Trace->new()} 'Mail::Log::Exceptions::InvalidParameter';
throws_ok {$object = Mail::Log::Trace->new({'log_file' => 't/log'})} 'Mail::Log::Exceptions::LogFile';
throws_ok {$object = Mail::Log::Trace->new({parser_class => 'Log::Parser', log_file => 't/data/log'})} 'Mail::Log::Exceptions';

	# This is going to test
	# a file that exists, but we can't read...
chmod (0000, 't/data/log');
throws_ok {$object = Mail::Log::Trace->new({'log_file' => 't/data/log'})} 'Mail::Log::Exceptions::LogFile';
chmod (0644, 't/data/log');	# Make sure we set it back at the end.

### Test the private. ###
# (We've tested some private stuff above; this is _really_ private.)
$object = Mail::Log::Trace->new({'log_file' => 't/data/log'});
my $result = $object->_parse_args({to_address => 'example@example.com'});
cmp_deeply($result, {to_address => [qw(example@example.com)], sent_time => undef, recieved_time => undef, relay  => undef, from_address => undef, message_id => undef, from_start => bool(0), subject => undef}, 'Mail::Log::Exceptions _parse_args test.');
$object = Mail::Log::Trace->new({'log_file' => 't/data/log'});
$result = $object->_parse_args({from_address => 'example@example.com'});
cmp_deeply($result, {to_address => undef, sent_time => undef, recieved_time => undef, relay  => undef, from_address => 'example@example.com', message_id => undef, from_start => bool(0), subject => undef}, 'Mail::Log::Exceptions _parse_args test 2.');
$object = Mail::Log::Trace->new({'log_file' => 't/data/log'});
$result = $object->_parse_args({to_address => [qw(example@example.com example2@example.com)]});
cmp_deeply($result, {to_address => [qw(example@example.com example2@example.com)], sent_time => undef, recieved_time => undef, relay => undef, from_address => undef, message_id => undef, from_start => bool(0), subject => undef}, 'Mail::Log::Exceptions _parse_args test 3.');

}

# Test the constructor.
TRACE_CONSTRUCTOR: {
my $object = Mail::Log::Trace->new({log_file		=> 't/data/log',
									from_address	=> 'from@example.com',
									to_address		=> 'to@example.com',
									message_id		=> 'message.id.test',
									recieved_time	=> 'time',
									sent_time		=> 'time',
									relay		=> 'mail.example.com',
									parser_class	=> 'Mail::Log::Parse::Test',
									subject			=> 'Test subject',
								   });

is($object->get_log(), 't/data/log', 'Mail::Log::Trace log');
is($object->get_from_address(), 'from@example.com', 'Mail::Log::Trace From address');
is_deeply($object->get_to_address(), ['to@example.com'], 'Mail::Log::Trace To address');
is($object->get_message_id(), 'message.id.test', 'Mail::Log::Trace message ID');
is($object->get_recieved_time(), 'time', 'Mail::Log::Trace recieved time.');
is($object->get_sent_time(), 'time', 'Mail::Log::Trace sent time.');
is($object->get_relay(), 'mail.example.com', 'Mail::Log::Trace relay.');
is($object->get_subject(), 'Test subject', 'Mail::Log::Trace subject.');
# Private gets.
is($object->_get_parser_class(), 'Mail::Log::Parse::Test', 'Mail::Log::Trace parser.');
}

#
# Start Mail::Log::Trace::Postfix tests.
#

POSTFIX: {
my $object = Mail::Log::Trace::Postfix->new({'log_file' => 't/data/log'});

# A quick re-test of the above... 
is($object->get_log(), 't/data/log', 'Mail::Log::Trace::Postfix inital log');

# Test overloads.
is("$object", 'Mail::Log::Trace::Postfix File: t/data/log', 'Mail::Log::Trace::Postfix stringification.');
ok(!$object, 'Mail::Log::Trace boolean coersion.');
throws_ok { $object + 1 } 'Mail::Log::Exceptions';

# 'Before' tests.
is($object->get_log(), 't/data/log', 'Mail::Log::Trace::Postfix before set log');
is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix before from address');
is_deeply($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix before to address');
is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix before message ID');
is($object->get_recieved_time(), undef, 'Mail::Log::Trace::Postfix before recieved time.');
is($object->get_sent_time(), undef, 'Mail::Log::Trace::Postfix before sent time.');
is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix before sent relay.');
is($object->get_connect_time(), undef, 'Mail::Log::Trace::Postfix before connect time.');
is($object->get_disconnect_time(), undef, 'Mail::Log::Trace::Postfix before disconnect, time.');
is($object->get_all_info(), undef, 'Mail::Log::Trace::Postfix before all info.');
# Private gets.
is($object->_get_parser_class(), undef, 'Mail::Log::Trace::Postfix before parser.');

$object->set_log('t/data/log2');
$object->set_from_address('from@example.com');
$object->set_to_address([qw(to@example.com to2@example to3@example.com)]);
$object->set_message_id('message.id.test');
$object->set_recieved_time('time');
$object->set_sent_time('time');
$object->set_relay('mail.example.com');
$object->set_parser_class('Mail::Log::Parse::Test');
# These are 'private', local to the object tree.
$object->_set_connect_time(19088445);
$object->_set_disconnect_time(29884455);
$object->_set_delay(1.7);
$object->_set_message_raw_info({to_address => [qw(hello hi)]});

# 'After' tests
is($object->get_log(), 't/data/log2', 'Mail::Log::Trace::Postfix set log');
is($object->get_from_address(), 'from@example.com', 'Mail::Log::Trace::Postfix From address');
cmp_deeply($object->get_to_address(), bag(qw(to@example.com to2@example to3@example.com)), 'Mail::Log::Trace To address');
is($object->get_message_id(), 'message.id.test', 'Mail::Log::Trace::Postfix message ID');
is($object->get_recieved_time(), 'time', 'Mail::Log::Trace::Postfix recieved time.');
is($object->get_sent_time(), 'time', 'Mail::Log::Trace::Postfix sent time.');
is($object->get_relay(), 'mail.example.com', 'Mail::Log::Trace::Postfix relay.');
is($object->get_connect_time(), 19088445, 'Mail::Log::Trace::Postfix connect time.');
is($object->get_disconnect_time(), 29884455, 'Mail::Log::Trace::Postfix disconnect, time.');
is($object->get_delay(), 1.7, 'Mail::Log::Trace::Postfix delay.');
is_deeply($object->get_all_info(), {to_address => [qw(hello hi)]}, 'Mail::Log::Trace all info.');
# Private gets.
is($object->_get_parser_class(), 'Mail::Log::Parse::Test', 'Mail::Log::Trace::Postfix before parser.');


### Test the non-working. ###
eval {$object = Mail::Log::Trace::Postfix->new({'log_file' => 't/log'});};
my $exception = Mail::Log::Exceptions->caught();
isa_ok ($exception, 'Mail::Log::Exceptions::LogFile', 'Mail::Log::Trace::Postfix nonexistant logfile');
is($exception->message(), 'Log file t/log does not exist.', 'Mail::Log::Trace::Postfix nonexistant logfile description');

	# This is going to test a file that exists, but we can't read...
chmod (0000, 't/data/log');
eval {$object = Mail::Log::Trace::Postfix->new({'log_file' => 't/data/log'});};
$exception = Mail::Log::Exceptions->caught();
isa_ok ($exception, 'Mail::Log::Exceptions::LogFile', 'Mail::Log::Trace::Postfix non-readable logfile');
is($exception->message(), 'Log file t/data/log is not readable.', 'Mail::Log::Trace::Postfix non-readable logfile description');
chmod (0644, 't/data/log');	# Make sure we set it back at the end.

### Postfix-specific tests. ###
is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix before connection ID');
is($object->get_process_id(), undef, 'Mail::Log::Trace::Postfix before process ID.');
is($object->get_status(), undef, 'Mail::Log::Trace::Postfix before status.');
is($object->get_year(), undef, 'Mail::Log::Trace::Postfix before year.');

$object->set_connection_id('F2345D');
$object->set_process_id('3541');
$object->set_status('unknown');
lives_ok { $object->set_year(1990); } 'Set year to integer.';

is($object->get_connection_id(), 'F2345D', 'Mail::Log::Trace::Postfix connection ID');
is($object->get_process_id(),'3541', 'Mail::Log::Trace::Postfix process ID.');
is($object->get_status(), 'unknown', 'Mail::Log::Trace::Postfix status.');
is($object->get_year(), '1990', 'Mail::Log::Trace::Postfix integer year.');

# Some alternate forms.
lives_ok { $object->set_year('1991'); } 'Set year to string.';
is($object->get_year(), '1991', 'Mail::Log::Trace::Postfix string year.');


eval {$object->set_year(1969);};
$exception = Mail::Log::Exceptions->caught();
isa_ok( $exception, 'Mail::Log::Exceptions::InvalidParameter', 'Mail::Log::Trace::Postfix invalid year.');
is($object->get_year(), '1991', 'Mail::Log::Trace::Postfix after exception year.');


}

# Test the Postfix constructor
POSTFIX_CONSTRUCTOR: {
my $object = Mail::Log::Trace::Postfix->new({log_file		=> 't/data/log',
											from_address	=> 'from@example.com',
											to_address		=> 'to@example.com',
											message_id		=> 'message.id.test',
											recieved_time	=> 'time',
											parser_class	=> 'Mail::Log::Parse::Test',
											sent_time		=> 'time',
											relay			=> 'mail.example.com',
											connection_id	=> 'F2345D',
											process_id		=> '3541',
											status			=> 'unknown',
											year			=> 2008,
											});

is($object->get_log(), 't/data/log', 'Mail::Log::Trace::Postfix set log');
is($object->get_from_address(), 'from@example.com', 'Mail::Log::Trace::Postfix From address');
is_deeply($object->get_to_address(), ['to@example.com'], 'Mail::Log::Trace::Postfix To address');
is($object->get_message_id(), 'message.id.test', 'Mail::Log::Trace::Postfix message ID');
is($object->get_recieved_time(), 'time', 'Mail::Log::Trace::Postfix recieved time.');
is($object->get_sent_time(), 'time', 'Mail::Log::Trace::Postfix sent time.');
is($object->get_relay(), 'mail.example.com', 'Mail::Log::Trace::Postfix relay.');
is($object->get_connection_id(), 'F2345D', 'Mail::Log::Trace::Postfix connection ID');
is($object->get_process_id(),'3541', 'Mail::Log::Trace::Postfix process ID.');
is($object->get_status(), 'unknown', 'Mail::Log::Trace::Postfix status.');
is($object->get_connect_time(), undef, 'Mail::Log::Trace::Postfix connect time.');
is($object->get_disconnect_time(), undef, 'Mail::Log::Trace::Postfix disconnect, time.');
is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix delay.');
is($object->get_year(), 2008, 'Mail::Log::Trace::Postfix set year.');
# Private gets.
is($object->_get_parser_class(), 'Mail::Log::Parse::Test', 'Mail::Log::Trace::Postfix before parser.');
}

# Postfix Constructor 2.
POSTFIX_CONSTRUCTOR_BAD_YEAR: {
my $object;
throws_ok { $object = Mail::Log::Trace::Postfix->new({year => 1900}); }
			'Mail::Log::Exceptions::InvalidParameter', 'Mail::Log::Trace::Postfix bad year in constructor.';
}

