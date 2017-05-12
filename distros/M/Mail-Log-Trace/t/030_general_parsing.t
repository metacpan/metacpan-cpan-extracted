#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests => 205;
use Test::Deep;
use Mail::Log::Trace;
use Mail::Log::Trace::Postfix;
use Time::Local;
use Mail::Log::Exceptions;

#local $TODO = 'help!';

# We'll need this value over and over.
( undef, undef, undef, undef, undef, my $year) = localtime;

TRACE:{
my $object = Mail::Log::Trace->new({log_file => 't/data/log'});

# 'Find_Message' needs to be implemented by a subclass.
my $result = eval {$object->find_message();};
is($result, undef, 'Mail::Log::Trace: Base class find_message()');
my $exception = Mail::Log::Exceptions->caught();
isa_ok ($exception, 'Mail::Log::Exceptions::Unimplemented', 'Base class find_message() exception class.');
is($exception->message(), "Method 'find_message' needs to be implemented by subclass.\n"
						, 'Base class find_message() text.'
						);
						
# 'Find_message_info' needs to be implemented by a subclass.
$result = eval {$object->find_message_info();};
is($result, undef, 'Mail::Log::Trace: Base class find_message()');
$exception = Mail::Log::Exceptions->caught();
isa_ok ($exception, 'Mail::Log::Exceptions::Unimplemented', 'Base class find_message() exception class.');
is($exception->message(), "Method 'find_message_info' needs to be implemented by subclass.\n"
						, 'Base class find_message() text.'
						);

}

POSTFIX: {
# Tests for missing message info on find.
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	my $result = eval {$object->find_message();};
	is($result, undef,'Mail::Log::Trace::Postfix: Find no message.');
	my $exception = Mail::Log::Exceptions->caught();
	isa_ok ($exception, 'Mail::Log::Exceptions::Message', 'Mail::Log::Trace::Postfix: No message data exception.');
	is($exception->message(), "Warning: Trying to search for a message with no message-specific data.\n"
							, 'Mail::Log::Trace::Postfix: No message data exception message.'
							);
}
						
#Ok, let's give it an actual, real, findable message.  "to" field.
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "to" field, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "to" field, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "to" field, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "to" field, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "to" field, result before.');
	is($object->get_sent_time(), undef, 'Mail::Log::Trace::Postfix: Find message from "to" field, sent_time before.');
	is($object->get_recieved_time(), undef, 'Mail::Log::Trace::Postfix: Find message from "to" field, recieved_time before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "to" field, status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "to" field, delay before.');
	is($object->get_all_info(), undef, 'Mail::Log::Trace::Postfix Find message from "to" field, all info before.');
	
	my $result = $object->find_message({to_address => '<00000002@acme.gov>'});
	is($result, 1, 'Mail::Log::Trace::Postfix: Find message from "to" field.');
	
	# Check that we've got the right data back.
	is_deeply($object->get_to_address(), ['<00000002@acme.gov>'], 'Mail::Log::Trace::Postfix: Find message from "to" field, result "to".');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "to" field, result "from".');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "to" field, result "message_id".');
	is($object->get_connection_id(), '6B1B62259', 'Mail::Log::Trace::Postfix: Find message from "to" field, result "connection_id".');
	is($object->get_relay(), '10.0.0.1[10.0.0.1]:1025', 'Mail::Log::Trace::Postfix: Find message from "to" field, result "relay".');
	my $timestamp = timelocal(38, 01, 00, 18, 7, $year);
	is($object->get_sent_time(), $timestamp, 'Mail::Log::Trace::Postfix: Find message from "to" field, sent_time result.');
	is($object->get_recieved_time(), undef, 'Mail::Log::Trace::Postfix: Find message from "to" field, recieved_time result.');
	is($object->get_status(), 'sent (250 Message received and queued)', 'Mail::Log::Trace::Postfix: Find message from "to", result "status".');
	is($object->get_delay(), 0.06, 'Mail::Log::Trace::Postfix Find message from "to" field, delay.');
	cmp_deeply($object->get_all_info(), superhashof({to => [qw(<00000002@acme.gov>)],
													relay => '10.0.0.1[10.0.0.1]:1025',
													}), 'Mail::Log::Trace::Postfix Find message from "to" field, all info.');

# Another. "from"

	$object->clear_message_info();
	
	#Check it inited correctly.
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "from" field, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "from" field, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "from" field, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "from" field, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "from" field, result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "from" field, status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "from" field, delay before.');
	
	$result = $object->find_message({from_address => '<00000094@sapdb07.cpb.acme.gov>'});
	is($result, 1, 'Mail::Log::Trace::Postfix: Find message from "from" field.');
	
	# Check that we've got the right data back.
	is_deeply($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "from" field, result "to".');
	is($object->get_from_address(), '<00000094@sapdb07.cpb.acme.gov>', 'Mail::Log::Trace::Postfix: Find message from "from" field, result "from".');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "from" field, result "message_id".');
	is($object->get_connection_id(), '8180D2BBE', 'Mail::Log::Trace::Postfix: Find message from "from" field, result "connection_id".');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "from" field, result "relay".');
	is($object->get_sent_time(), undef, 'Mail::Log::Trace::Postfix: Find message from "from" field, sent_time result.');
	is($object->get_recieved_time(), undef, 'Mail::Log::Trace::Postfix: Find message from "from" field, recieved_time result.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "from", result "status".');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "from" field, delay.');


# Another. "message_id", from start, with new year.

	$object->clear_message_info();
	$object->set_year(1998);
	
	#Check it inited correctly.
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id" field, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id" field, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id" field, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id" field, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id" field, result before.');
	is($object->get_sent_time(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id" field, sent_time before.');
	is($object->get_recieved_time(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id" field, recieved_time before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id", status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "message_id" field, delay before.');
	
	$result = $object->find_message({message_id => '<200808180401.m7I41cGe029201@sapdb07.cpb.acme.gov>', from_start => 1 });
	ok($result, 'Mail::Log::Trace::Postfix: Find message from "message_id" field.');
	
	# Check that we've got the right data back.
	is_deeply($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id" field, result "to".');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id" field, result "from".');
	is($object->get_message_id(), '<200808180401.m7I41cGe029201@sapdb07.cpb.acme.gov>', 'Mail::Log::Trace::Postfix: Find message from "message_id" field, result "message_id".');
	is($object->get_connection_id(), '8180D2BBE', 'Mail::Log::Trace::Postfix: Find message from "message_id" field, result "connection_id".');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id" field, result "relay".');
	is($object->get_sent_time(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id" field, sent_time result.');
	$timestamp = timelocal(39, 01, 00, 18, 7, 1998);
	is($object->get_recieved_time(), $timestamp, 'Mail::Log::Trace::Postfix: Find message from "message_id" field, recieved_time result.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id", result "status".');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "message_id" field, delay.');
}

# Another. "connection_id"
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log', parser_class => 'Mail::Log::Parse::Postfix'});
	
	#Check it inited correctly.
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id" field, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id" field, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id" field, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id" field, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id" field, result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id", status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "connection_id" field, delay before.');
	
	my $result = $object->find_message({connection_id => '6B1B62259'});
	is($result, 1, 'Mail::Log::Trace::Postfix: Find message from "connection_id" field.');
	
	# Check that we've got the right data back.
	is_deeply($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id" field, result "to".');
	is($object->get_from_address(), '<00000001@baz.acme.gov>', 'Mail::Log::Trace::Postfix: Find message from "connection_id" field, result "from".');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id" field, result "message_id".');
	is($object->get_connection_id(), '6B1B62259', 'Mail::Log::Trace::Postfix: Find message from "connection_id" field, result "connection_id".');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id" field, result "relay".');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id", result "status".');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "connection_id" field, delay.');
}

# Another. "relay", with year.
{ #local $TODO = 'testing';
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log', year => 2001});
	
	#Check it inited correctly.
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "relay" field, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "relay" field, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "relay" field, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "relay" field, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "relay" field, result before.');
	is($object->get_sent_time(), undef, 'Mail::Log::Trace::Postfix: Find message from "relay" field, sent_time before.');
	is($object->get_recieved_time(), undef, 'Mail::Log::Trace::Postfix: Find message from "relay" field, recieved_time before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "relay", status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "relay" field, delay before.');
	
	my $result = $object->find_message({relay => '127.0.0.1[127.0.0.1]:10025'});
	is($result, 1, 'Mail::Log::Trace::Postfix: Find message from "relay" field.');
	
	# Check that we've got the right data back.
	is_deeply($object->get_to_address(), ['<00000000@acme.gov>'], 'Mail::Log::Trace::Postfix: Find message from "relay" field, result "to".');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "relay" field, result "from".');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "relay" field, result "message_id".');
	is($object->get_connection_id(), 'CF6C9214B', 'Mail::Log::Trace::Postfix: Find message from "relay" field, result "connection_id".');
	is($object->get_relay(), '127.0.0.1[127.0.0.1]:10025', 'Mail::Log::Trace::Postfix: Find message from "relay" field, result "relay".');
	my $timestamp = timelocal(38, 01, 00, 18, 7, 2001);
	is($object->get_sent_time(), $timestamp, 'Mail::Log::Trace::Postfix: Find message from "relay" field, sent_time result.');
	is($object->get_recieved_time(), undef, 'Mail::Log::Trace::Postfix: Find message from "relay" field, recieved_time result.');
	is($object->get_status(), 'sent (250 OK, sent 48A8F422_13987_12168_1 6B1B62259)', 'Mail::Log::Trace::Postfix: Find message from "relay", result "status".');
	is($object->get_delay(), 0.63, 'Mail::Log::Trace::Postfix Find message from "relay" field, delay.');
}

# Another. "status"
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "status" field, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "status" field, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "status" field, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "status" field, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "status" field, result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "status", status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "status" field, delay before.');
	
	my $result = $object->find_message({status => 'sent (250 OK, sent 48A8F423_13989_69086_1 3FF792A76)'});
	is($result, 1, 'Mail::Log::Trace::Postfix: Find message from "status" field.');
	
	# Check that we've got the right data back.
	is_deeply($object->get_to_address(), ['<00000093@acme.gov>'], 'Mail::Log::Trace::Postfix: Find message from "status" field, result "to".');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "status" field, result "from".');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "status" field, result "message_id".');
	is($object->get_connection_id(), 'ECF422BE6', 'Mail::Log::Trace::Postfix: Find message from "status" field, result "connection_id".');
	is($object->get_relay(), '127.0.0.1[127.0.0.1]:10025', 'Mail::Log::Trace::Postfix: Find message from "status" field, result "relay".');
	is($object->get_status(), 'sent (250 OK, sent 48A8F423_13989_69086_1 3FF792A76)', 'Mail::Log::Trace::Postfix: Find message from "status", result "status".');
	is($object->get_delay(), 0.33, 'Mail::Log::Trace::Postfix Find message from "status" field, delay.');
}


# Another. "connection_id, from_address"
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, from_address" field, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, from_address" field, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, from_address" field, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, from_address" field, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, from_address" field, result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, from_address", status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "connection_id, from_address" field, delay before.');
	
	my $result = $object->find_message({connection_id => '8180D2BBE', from_address => '<00000094@sapdb07.cpb.acme.gov>' });
	is($result, 1, 'Mail::Log::Trace::Postfix: Find message from "connection_id, from_address" field.');
	
	# Check that we've got the right data back.
	is_deeply($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, from_address" field, result "to".');
	is($object->get_from_address(), '<00000094@sapdb07.cpb.acme.gov>', 'Mail::Log::Trace::Postfix: Find message from "connection_id, from_address" field, result "from".');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, from_address" field, result "message_id".');
	is($object->get_connection_id(), '8180D2BBE', 'Mail::Log::Trace::Postfix: Find message from "connection_id, from_address" field, result "connection_id".');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, from_address" field, result "relay".');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, from_address", result "status".');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "connection_id, from_address" field, delay.');
}

# Another. "message_id, connection_id"
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id, connection_id" field, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id, connection_id" field, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id, connection_id" field, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id, connection_id" field, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id, connection_id" field, result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id, connection_id", status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "message_id, connection_id" field, delay before.');
	
	my $result = $object->find_message({message_id => '<200808180401.m7I41cGe029201@sapdb07.cpb.acme.gov>', connection_id => '8180D2BBE'} );
	is($result, 1, 'Mail::Log::Trace::Postfix: Find message from "message_id, connection_id" field.');
	
	# Check that we've got the right data back.
	is_deeply($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id, connection_id" field, result "to".');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id, connection_id" field, result "from".');
	is($object->get_message_id(), '<200808180401.m7I41cGe029201@sapdb07.cpb.acme.gov>', 'Mail::Log::Trace::Postfix: Find message from "message_id, connection_id" field, result "message_id".');
	is($object->get_connection_id(), '8180D2BBE', 'Mail::Log::Trace::Postfix: Find message from "message_id, connection_id" field, result "connection_id".');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id, connection_id" field, result "relay".');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "message_id, connection_id", result "status".');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "message_id, connection_id" field, delay.');
}

# Another, a bogus one.  "from_address, to_address"
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus" field, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus" field, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus" field, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus" field, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus" field, result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus", status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "bogus" field, delay before.');
	
	my $result = $object->find_message({to_address => 'A35678d5IJNB@dh.govaaa', from_address => '<qs1adm@sapdb07.cp.acme.gov>', connection_id => 'm7I41cGe029201'});
	is($result, 0, 'Mail::Log::Trace::Postfix: Find message from "bogus" field.');
	
	# Check that we've got the right data back.
	is_deeply($object->get_to_address(), ['A35678d5IJNB@dh.govaaa'], 'Mail::Log::Trace::Postfix: Find message from "bogus" field, result "to".');
	is($object->get_from_address(), '<qs1adm@sapdb07.cp.acme.gov>', 'Mail::Log::Trace::Postfix: Find message from "bogus" field, result "from".');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus" field, result "message_id".');
	is($object->get_connection_id(), 'm7I41cGe029201', 'Mail::Log::Trace::Postfix: Find message from "bogus" field, result "connection_id".');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus" field, result "relay".');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus", result "status".');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "bogus" field, delay.');
}

# Another, a bogus one.  "to_address"
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus to" to field, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus to" from field, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus to" id field, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus to" connection_id field, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus to" field, result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus to", status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "bogus to" field, delay before.');
	
	my $result = $object->find_message({to_address => 'test@example.com'});
	is($result, 0, 'Mail::Log::Trace::Postfix: Find message from "bogus to" field.');
	
	# Check that we've got the right data back.
	is_deeply($object->get_to_address(), ['test@example.com'], 'Mail::Log::Trace::Postfix: Find message from "bogus to" to field, result "to".');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus to" field, result "from".');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus to" field, result "message_id".');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus to" field, result "connection_id".');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus to" field, result "relay".');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "bogus to", result "status".');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "bogus to" field, delay before.');
}

# Another bogus. "connection_id, emtpy log"
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log2'});
	
	#Check it inited correctly.
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, empty log" field, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, empty log" field, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, empty log" field, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, empty log" field, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, empty log" field, result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, empty log", status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "connection_id, empty log" field, delay before.');
	
	my $result = $object->find_message({connection_id => '6B1B62259'});
	is($result, 0, 'Mail::Log::Trace::Postfix: Find message from "connection_id, empty log" field.');
	
	# Check that we've got the right data back.
	is_deeply($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, empty log" field, result "to".');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, empty log" field, result "from".');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, empty log" field, result "message_id".');
	is($object->get_connection_id(), '6B1B62259', 'Mail::Log::Trace::Postfix: Find message from "connection_id, empty log" field, result "connection_id".');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, empty log" field, result "relay".');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "connection_id, empty log", result "status".');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "connection_id empty log" field, delay before.');
}

# Ok, something a little tricky...  This can be partial-matched, and all matches must be full.
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});

	#Check it inited correctly.
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "partial match" to field, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "partial match" from field, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "partial match" id field, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "partial match" connection_id field, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Find message from "partial match" host field, result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Find message from "partial match" status field, result before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix Find message from "partial match" field, delay before.');
	
	my $result = $object->find_message({relay => '10.0.0.1[10.0.0.1]:1025', connection_id => '7918B29DA'});
	is($result, 1, 'Mail::Log::Trace::Postfix: Find message from "partial match".');
	
	# Check that we've got the right data back.
	is_deeply($object->get_to_address(), ['<00000008@associates.acme.gov>'], 'Mail::Log::Trace::Postfix: Find message from "partial match" to field, result "to".');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Find message from "partial match" field, result "from".');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Find message from "partial match" field, result "message_id".');
	is($object->get_connection_id(), '7918B29DA', 'Mail::Log::Trace::Postfix: Find message from "partial match" field, result "connection_id".');
	is($object->get_relay(), '10.0.0.1[10.0.0.1]:1025', 'Mail::Log::Trace::Postfix: Find message from "partial match" field, result "relay".');
	is($object->get_status(), 'sent (250 Message received and queued)', 'Mail::Log::Trace::Postfix: Find message from "partial match", result "status".');
	is($object->get_delay(), 0.08, 'Mail::Log::Trace::Postfix Find message from "partial match" field, delay.');
}

}
