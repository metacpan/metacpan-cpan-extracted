#!/usr/bin/perl

use strict;
use warnings;
use Mail::Log::Trace::Postfix;
use Time::Local;
use Test::More tests => 209;
use Test::Exception;
use Test::Deep;

#local $TODO = 'help!';

# We'll need this value over and over.
( undef, undef, undef, undef, undef, my $year) = localtime;

# Start with some things that _can't_ be found.
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_connect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", connect_time before.');
	is($object->get_recieved_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", received_time before.');
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", status before.');
	is($object->get_sent_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", sent_time before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", delay before.');
	is($object->get_disconnect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", disconnect_time before.');
	is($object->get_all_info(), undef, 'Mail::Log::Trace::Postfix Trace message from "unfindable" field, all info before.');
	
	my $result;
	lives_ok { $result = $object->find_message_info({connection_id => 'ZZZZZZZZ'} ) } 'Should exit clean';
	ok(!$result, 'Mail::Log::Trace::Postfix: Trace message from "connection_id".');
	
	# Check that we've got the right data back.
	is($object->get_connect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", connect_time.');
	is($object->get_recieved_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", received_time.');
	is_deeply($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", result "to".');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", result "from".');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", result "message_id".');
	is($object->get_connection_id(), 'ZZZZZZZZ', 'Mail::Log::Trace::Postfix: Trace message from "unfindable", result "connection_id".');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", result "relay".');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", result "status".');
	is($object->get_sent_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", sent_time.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", delay.');
	is($object->get_disconnect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "unfindable", disconnect_time.');
	is($object->get_all_info(), undef, 'Mail::Log::Trace::Postfix Trace message from "unfindable" field, all info.');
}

# Find all info: Connection ID.
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_connect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", connect_time before.');
	is($object->get_recieved_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", received_time before.');
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", status before.');
	is($object->get_sent_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", sent_time before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", delay before.');
	is($object->get_disconnect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", disconnect_time before.');
	is($object->get_all_info(), undef, 'Mail::Log::Trace::Postfix Trace message from "connection_id", all info before.');
	
	my $result;
	lives_ok { $result = $object->find_message_info({connection_id => '7918B29DA'} ) } 'Should exit clean';
	ok($result, 'Mail::Log::Trace::Postfix: Trace message from "connection_id".');
	
	# Check that we've got the right data back.
	my $timestamp = timelocal(38, 01, 00, 18, 7, $year);
	is($object->get_connect_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", connect_time.');
	$timestamp = timelocal(38, 01, 00, 18, 7, $year);
	is($object->get_recieved_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", received_time.');
	is_deeply($object->get_to_address(), [qw(<00000008@associates.acme.gov> <00000009@associates.acme.gov> <00000010@associates.acme.gov> <00000011@associates.acme.gov> <00000012@associates.acme.gov> <00000013@associates.acme.gov> <00000014@associates.acme.gov> <00000015@acme.gov> <00000016@acme.gov> <00000017@acme.gov> <00000018@acme.gov> <00000019@acme.gov> <00000020@acme.gov> <00000021@acme.gov> <00000022@acme.gov> <00000023@acme.gov> <00000024@acme.gov> <00000025@acme.gov> <00000026@acme.gov> <00000027@acme.gov> <00000028@acme.gov> <00000029@acme.gov> <00000030@acme.gov> <00000031@acme.gov> <00000032@acme.gov> <00000033@acme.gov> <00000034@acme.gov> <00000035@acme.gov> <00000036@acme.gov> <00000037@acme.gov> <00000038@acme.gov> <00000039@acme.gov> <00000040@acme.gov> <00000041@acme.gov> <00000042@acme.gov> <00000043@acme.gov> <00000044@acme.gov> <00000045@acme.gov> <00000046@acme.gov> <00000047@acme.gov> <00000048@acme.gov> <00000049@acme.gov> <00000050@acme.gov> <00000051@acme.gov> <00000052@acme.gov> <00000053@acme.gov> <00000054@acme.gov> <00000055@acme.gov> <00000056@acme.gov> <00000057@acme.gov>)], 'Mail::Log::Trace::Postfix: Trace message from "connection_id", result "to".');
	is($object->get_from_address(), '<00000001@baz.acme.gov>', 'Mail::Log::Trace::Postfix: Trace message from "connection_id", result "from".');
	is($object->get_message_id(), '<D31A582E5B6A2B45902C41C643D99A5A01399D5C@K001MB101.network.ad.baz.gov>', 'Mail::Log::Trace::Postfix: Trace message from "connection_id", result "message_id".');
	is($object->get_connection_id(), '7918B29DA', 'Mail::Log::Trace::Postfix: Trace message from "connection_id", result "connection_id".');
	is($object->get_relay(), '10.0.0.1[10.0.0.1]:1025', 'Mail::Log::Trace::Postfix: Trace message from "connection_id", result "relay".');
	is($object->get_status(), 'sent (250 Message received and queued)', 'Mail::Log::Trace::Postfix: Trace message from "connection_id", result "status".');
	is($object->get_delay(), 0.08, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", delay.');
	$timestamp = timelocal(38, 01, 00, 18, 7, $year);
	is($object->get_sent_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", sent_time.');
	$timestamp = timelocal(38, 01, 00, 18, 7, $year);
	is($object->get_disconnect_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "connection_id", disconnect_time.');
	cmp_deeply($object->get_all_info(), superhashof({to => bag(qw(<00000008@associates.acme.gov> <00000009@associates.acme.gov> <00000010@associates.acme.gov> <00000011@associates.acme.gov> <00000012@associates.acme.gov> <00000013@associates.acme.gov> <00000014@associates.acme.gov> <00000015@acme.gov> <00000016@acme.gov> <00000017@acme.gov> <00000018@acme.gov> <00000019@acme.gov> <00000020@acme.gov> <00000021@acme.gov> <00000022@acme.gov> <00000023@acme.gov> <00000024@acme.gov> <00000025@acme.gov> <00000026@acme.gov> <00000027@acme.gov> <00000028@acme.gov> <00000029@acme.gov> <00000030@acme.gov> <00000031@acme.gov> <00000032@acme.gov> <00000033@acme.gov> <00000034@acme.gov> <00000035@acme.gov> <00000036@acme.gov> <00000037@acme.gov> <00000038@acme.gov> <00000039@acme.gov> <00000040@acme.gov> <00000041@acme.gov> <00000042@acme.gov> <00000043@acme.gov> <00000044@acme.gov> <00000045@acme.gov> <00000046@acme.gov> <00000047@acme.gov> <00000048@acme.gov> <00000049@acme.gov> <00000050@acme.gov> <00000051@acme.gov> <00000052@acme.gov> <00000053@acme.gov> <00000054@acme.gov> <00000055@acme.gov> <00000056@acme.gov> <00000057@acme.gov>)),
													relay => '10.0.0.1[10.0.0.1]:1025',
													msgid => '<D31A582E5B6A2B45902C41C643D99A5A01399D5C@K001MB101.network.ad.baz.gov>',
													status => 'sent (250 Message received and queued)',
													}), 'Mail::Log::Trace::Postfix Trace message from "connection_id", all info.');
}

# Find all info: From address.
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_connect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "from address", connect_time before.');
	is($object->get_recieved_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "from address", received_time before.');
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "from address", before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "from address", before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "from address", before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "from address", result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "from address", result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Trace message from "from address", status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "from address", delay before.');
	is($object->get_sent_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "from address", sent_time before.');
	is($object->get_disconnect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "from address", disconnect_time before.');
	
	my $result;
	lives_ok { $result = $object->find_message_info({from_address => '<00000096@O0OlII.gov>'} ) } 'Should exit clean';
	ok($result, 'Mail::Log::Trace::Postfix: Trace message from "from address".');
	
	# Check that we've got the right data back.
	my $timestamp = timelocal(47, 01, 00, 18, 7, $year);
	is($object->get_connect_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "from address", connect_time.');
	$timestamp = timelocal(47, 01, 00, 18, 7, $year);
	is($object->get_recieved_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "from address", received_time.');
	is_deeply($object->get_to_address(), [qw(<00000097@aadvantage.email.aa.com>)], 'Mail::Log::Trace::Postfix: Trace message from "from address", result "to".');
	is($object->get_from_address(), '<00000096@O0OlII.gov>', 'Mail::Log::Trace::Postfix: Trace message from "from address", result "from".');
	is($object->get_message_id(), '<0AF44B6ABCC6B140AEB436E48466B416163FF7@MWEX3M4.O0OlII.net>', 'Mail::Log::Trace::Postfix: Trace message from "from address", result "message_id".');
	is($object->get_connection_id(), '78C112259', 'Mail::Log::Trace::Postfix: Trace message from "from address", result "connection_id".');
	is($object->get_relay(), '127.0.0.1[127.0.0.1]:10025', 'Mail::Log::Trace::Postfix: Trace message from "from address", result "relay".');
	is($object->get_status(), 'sent (250 OK, sent 48A8F42B_13989_69090_1 8E198214B)', 'Mail::Log::Trace::Postfix: Trace message from "from address", result "status".');
	is($object->get_delay(), 0.14, 'Mail::Log::Trace::Postfix: Trace message from "from address", delay.');
	$timestamp = timelocal(47, 01, 00, 18, 7, $year);
	is($object->get_sent_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "from address", sent_time.');
	$timestamp = timelocal(47, 01, 00, 18, 7, $year);
	is($object->get_disconnect_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "from address", disconnect_time.');
}

# Find all info: To address.
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_connect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "to address", connect_time before.');
	is($object->get_recieved_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "to address", received_time before.');
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address", before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address", before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address", before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address", result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address", result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address", status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address", delay before.');
	is($object->get_sent_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "to address", sent_time before.');
	is($object->get_disconnect_time, undef, 'Mail::Log::Trace::Postfix: Trace message to "from address", disconnect_time before.');
	
	my $result;
	lives_ok { $result = $object->find_message_info({to_address => '<00000094@sapdb07.cpb.acme.gov>'} ) } 'Should exit clean';
	ok($result, 'Mail::Log::Trace::Postfix: Trace message from "to address".');
	
	# Check that we've got the right data back.
	my $timestamp = timelocal(39, 01, 00, 18, 7, $year);
	is($object->get_connect_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "to address", connect_time.');
	$timestamp = timelocal(39, 01, 00, 18, 7, $year);
	is($object->get_recieved_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "to address", received_time.');
	is_deeply($object->get_to_address(), [qw(<00000094@sapdb07.cpb.acme.gov>)], 'Mail::Log::Trace::Postfix: Trace message from "to address", result "to".');
	is($object->get_from_address(), '<00000094@sapdb07.cpb.acme.gov>', 'Mail::Log::Trace::Postfix: Trace message from "to address", result "from".');
	is($object->get_message_id(), '<200808180401.m7I41cGe029201@sapdb07.cpb.acme.gov>', 'Mail::Log::Trace::Postfix: Trace message from "to address", result "message_id".');
	is($object->get_connection_id(), '8180D2BBE', 'Mail::Log::Trace::Postfix: Trace message from "to address", result "connection_id".');
	is($object->get_relay(), '127.0.0.1[127.0.0.1]:10025', 'Mail::Log::Trace::Postfix: Trace message from "to address", result "relay".');
	is($object->get_status(), 'sent (250 OK, sent 48A8F423_13987_12169_1 8A19A2E68)', 'Mail::Log::Trace::Postfix: Trace message from "to address", result "status".');
	is($object->get_delay(), 0.07, 'Mail::Log::Trace::Postfix: Trace message from "to address", delay.');
	$timestamp = timelocal(39, 01, 00, 18, 7, $year);
	is($object->get_sent_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "to address", sent_time.');
	$timestamp = timelocal(39, 01, 00, 18, 7, $year);
	is($object->get_disconnect_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "to address", disconnect_time.');
}

# Find all info: To address, part of a list.
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_connect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", connect_time before.');
	is($object->get_recieved_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", received_time before.');
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", delay before.');
	is($object->get_sent_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", sent_time before.');
	is($object->get_disconnect_time, undef, 'Mail::Log::Trace::Postfix: Trace message to "from address 2", disconnect_time before.');
	
	my $result;
	lives_ok { $result = $object->find_message_info({to_address => '<00000128@acme.gov>'} ) } 'Should exit clean';
	ok($result, 'Mail::Log::Trace::Postfix: Trace message from "to address 2".');
	
	# Check that we've got the right data back.
	my $timestamp = timelocal(54, 2, 00, 18, 7, $year);
	is($object->get_connect_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", connect_time.');
	$timestamp = timelocal(56, 2, 00, 18, 7, $year);
	is($object->get_recieved_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", received_time.');
	cmp_bag($object->get_to_address(), [qw(<00000125@acme.gov> <00000126@acme.gov> <00000127@acme.gov> <00000124@acme.gov> <00000128@acme.gov> <00000117@acme.gov>)], 'Mail::Log::Trace::Postfix: Trace message from "to address 2", result "to".');
	is($object->get_from_address(), '<00000110@fins3.acme.gov>', 'Mail::Log::Trace::Postfix: Trace message from "to address 2", result "from".');
	is($object->get_message_id(), '<6CA0AABDDBF6D04BAE5E7EB6EC6AC8AD03748140@Z02EXISPM03.irmnet.ds2.acme.gov>', 'Mail::Log::Trace::Postfix: Trace message from "to address 2", result "message_id".');
	is($object->get_connection_id(), '94D0029DA', 'Mail::Log::Trace::Postfix: Trace message from "to address 2", result "connection_id".');
	is($object->get_relay(), '127.0.0.1[127.0.0.1]:10025', 'Mail::Log::Trace::Postfix: Trace message from "to address 2", result "relay".');
	is($object->get_status(), 'sent (250 OK, sent 48A8F471_13989_69117_1 6549D2B13)', 'Mail::Log::Trace::Postfix: Trace message from "to address 2", result "status".');
	is($object->get_delay(), 0.87, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", delay.');
	$timestamp = timelocal(57, 2, 00, 18, 7, $year);
	is($object->get_sent_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", sent_time.');
	$timestamp = timelocal(57, 2, 00, 18, 7, $year);
	is($object->get_disconnect_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "to address 2", disconnect_time.');
}

# A couple of odd conditions...

# Find all info: To address, at start.
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_connect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, connect_time before.');
	is($object->get_recieved_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, received_time before.');
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, delay before.');
	is($object->get_sent_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "to address", sent_time before.');
	is($object->get_disconnect_time, undef, 'Mail::Log::Trace::Postfix: Trace message to "from address" start of file, disconnect_time before.');
	
	my $result;
	throws_ok { $result = $object->find_message_info({to_address => '<00000002@acme.gov>'} ) } 'Mail::Log::Exceptions::Message::IncompleteLog', 'Should die at beginning of file.';
	ok(!$result, 'Mail::Log::Trace::Postfix: Trace message from "to address".');
	
	# Check that we've got the right data back.
	is($object->get_connect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, connect_time.');
	is($object->get_recieved_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, received_time.');
	is_deeply($object->get_to_address(), [qw(<00000002@acme.gov> <00000003@acme.gov> <00000004@acme.gov> <00000005@acme.gov> <00000006@acme.gov> <00000007@acme.gov> <00000000@acme.gov>)], 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, result "to".');
	is($object->get_from_address(), '<00000001@baz.acme.gov>', 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, result "from".');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, result "message_id".');
	is($object->get_connection_id(), '6B1B62259', 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, result "connection_id".');
	is($object->get_relay(), '10.0.0.1[10.0.0.1]:1025', 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, result "relay".');
	is($object->get_status(), 'sent (250 Message received and queued)', 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, result "status".');
	is($object->get_delay(), 0.06, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, delay.');
	my $timestamp = timelocal(38, 01, 00, 18, 7, $year);
	is($object->get_sent_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, sent_time.');
	is($object->get_disconnect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "to address" start of file, disconnect_time.');
}

# Find all info: To address, at end.
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_connect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, connect_time before.');
	is($object->get_recieved_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, received_time before.');
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, delay before.');
	is($object->get_sent_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, sent_time before.');
	is($object->get_disconnect_time, undef, 'Mail::Log::Trace::Postfix: Trace message to "message_id" end of file, disconnect_time before.');
	
	my $result;
	throws_ok { $result = $object->find_message_info({message_id => '<D31A582E5B6A2B45902C41C643D99A5A01399D5D@K001MB101.network.ad.baz.gov>'} ) } 'Mail::Log::Exceptions::Message::IncompleteLog', 'Should die at end of file.';
	ok(!$result, 'Mail::Log::Trace::Postfix: Trace message from "message_id", end of file.');
	
	# Check that we've got the right data back.
	my $timestamp = timelocal(29, 03, 00, 18, 7, $year);
	is($object->get_connect_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, connect_time.');
	$timestamp = timelocal(29, 03, 00, 18, 7, $year);
	is($object->get_recieved_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, received_time.');
	is_deeply($object->get_to_address(), [qw(<00000060@acme.gov> <00000056@acme.gov> <00000057@acme.gov> <00000002@acme.gov> <00000003@acme.gov> <00000063@acme.gov> <00000140@acme.gov> <00000005@acme.gov> <00000064@acme.gov> <00000006@acme.gov> <00000007@acme.gov> <00000000@acme.gov>)], 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, result "to".');
	is($object->get_from_address(), '<00000001@baz.acme.gov>', 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, result "from".');
	is($object->get_message_id(), '<D31A582E5B6A2B45902C41C643D99A5A01399D5D@K001MB101.network.ad.baz.gov>', 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, result "message_id".');
	is($object->get_connection_id(), '1B91C2259', 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, result "connection_id".');
	is($object->get_relay(), '127.0.0.1[127.0.0.1]:10025', 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, result "relay".');
	is($object->get_status(), 'sent (250 OK, sent 48A8F491_13987_12174_1 69842214B)', 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, result "status".');
	is($object->get_delay(), 0.4, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, delay.');
	$timestamp = timelocal(29, 03, 00, 18, 7, $year);
	is($object->get_sent_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, sent_time.');
	is($object->get_disconnect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id" end of file, disconnect_time.');
}


# Find, and then find from that find...
{
	my $object = Mail::Log::Trace::Postfix->new({log_file => 't/data/log'});
	
	#Check it inited correctly.
	is($object->get_connect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id", connect_time before.');
	is($object->get_recieved_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id", received_time before.');
	is($object->get_to_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id", before.');
	is($object->get_from_address(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id", before.');
	is($object->get_message_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id", before.');
	is($object->get_connection_id(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id", result before.');
	is($object->get_relay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id", result before.');
	is($object->get_status(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id", status before.');
	is($object->get_delay(), undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id", delay before.');
	is($object->get_sent_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id", sent_time before.');
	is($object->get_disconnect_time, undef, 'Mail::Log::Trace::Postfix: Trace message from "message_id", disconnect_time before.');
	
	my $result;
	lives_ok { $result = $object->find_message_info({message_id => '<10719543.1219032118209.JavaMail.default@10.159.39.63>'} ) } 'Should exit clean';
	ok($result, 'Mail::Log::Trace::Postfix: Trace message from "message_id".');
	
	# Check that we've got the right data back.
	my $timestamp = timelocal(58, 01, 00, 18, 7, $year);
	is($object->get_connect_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "message_id", connect_time.');
	$timestamp = timelocal(58, 01, 00, 18, 7, $year);
	is($object->get_recieved_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "message_id", received_time.');
	is_deeply($object->get_to_address(), [qw(<00000099@OLYMPIC-AIRWAYS.GR>)], 'Mail::Log::Trace::Postfix: Trace message from "message_id", result "to".');
	is($object->get_from_address(), '<00000098@acme.gov>', 'Mail::Log::Trace::Postfix: Trace message from "message_id", result "from".');
	is($object->get_message_id(), '<10719543.1219032118209.JavaMail.default@10.159.39.63>', 'Mail::Log::Trace::Postfix: Trace message from "message_id", result "message_id".');
	is($object->get_connection_id(), '66AE6214B', 'Mail::Log::Trace::Postfix: Trace message from "message_id", result "connection_id".');
	is($object->get_relay(), '127.0.0.1[127.0.0.1]:10025', 'Mail::Log::Trace::Postfix: Trace message from "message_id", result "relay".');
	is($object->get_status(), 'sent (250 OK, sent 48A8F436_13989_69091_1 7338B2259)', 'Mail::Log::Trace::Postfix: Trace message from "message_id", result "status".');
	is($object->get_delay(), 0.1, 'Mail::Log::Trace::Postfix: Trace message from "message_id", delay.');
	$timestamp = timelocal(58, 01, 00, 18, 7, $year);
	is($object->get_sent_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "message_id", sent_time.');
	$timestamp = timelocal(58, 01, 00, 18, 7, $year);
	is($object->get_disconnect_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "message_id", disconnect_time.');

	# Now we find a recurrance...
	$object->clear_message_info();
	lives_ok { $result = $object->find_message_info({connection_id => '7338B2259'} ) } 'Should exit clean';
	ok($result, 'Mail::Log::Trace::Postfix: Trace message from "message_id".');

	# Check that we've got the right data back.
	$timestamp = timelocal(58, 01, 00, 18, 7, $year);
	is($object->get_connect_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "message_id", connect_time.');
	$timestamp = timelocal(58, 01, 00, 18, 7, $year);
	is($object->get_recieved_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "message_id", received_time.');
	is_deeply($object->get_to_address(), [qw(<00000099@OLYMPIC-AIRWAYS.GR>)], 'Mail::Log::Trace::Postfix: Trace message from "message_id", result "to".');
	is($object->get_from_address(), '<00000098@acme.gov>', 'Mail::Log::Trace::Postfix: Trace message from "message_id", result "from".');
	is($object->get_message_id(), '<10719543.1219032118209.JavaMail.default@10.159.39.63>', 'Mail::Log::Trace::Postfix: Trace message from "message_id", result "message_id".');
	is($object->get_connection_id(), '7338B2259', 'Mail::Log::Trace::Postfix: Trace message from "message_id", result "connection_id".');
	is($object->get_relay(), '10.0.0.1[10.0.0.1]:1025', 'Mail::Log::Trace::Postfix: Trace message from "message_id", result "relay".');
	is($object->get_status(), 'sent (250 Message received and queued)', 'Mail::Log::Trace::Postfix: Trace message from "message_id", result "status".');
	is($object->get_delay(), 0.09, 'Mail::Log::Trace::Postfix: Trace message from "message_id", delay.');
	$timestamp = timelocal(58, 01, 00, 18, 7, $year);
	is($object->get_sent_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "message_id", sent_time.');
	$timestamp = timelocal(58, 01, 00, 18, 7, $year);
	is($object->get_disconnect_time, $timestamp, 'Mail::Log::Trace::Postfix: Trace message from "message_id", disconnect_time.');

}
