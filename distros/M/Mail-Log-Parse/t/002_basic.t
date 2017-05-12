#!/usr/bin/perl

use warnings;
use strict;
use Test::More tests=> 268;
use Test::Exception; 
use Time::Local;
use Mail::Log::Parse;
use Mail::Log::Parse::Postfix;
use Mail::Log::Exceptions;

#use Test::Differences;

# A quick test of Mail::Log::Parse.
{
	my $object;
	lives_ok { $object = Mail::Log::Parse->new() } 'Create Mai::Log::Parse object.';
	throws_ok { $object->next() } 'Mail::Log::Exceptions::Unimplemented';
}

# We'll need this value over and over.
( undef, undef, undef, undef, undef, my $year) = localtime;

# The keys list.
my @keys = sort qw(to from relay pid msgid program host status id timestamp text size delay_before_queue 
					delay_in_queue delay_connect_setup delay_message_transmission delay connect
					disconnect previous_host previous_host_name previous_host_ip);

### Test the non-working. ###
{
my $object;
throws_ok {$object = Mail::Log::Parse::Postfix->new({'log_file' => 't/log'})} 'Mail::Log::Exceptions::LogFile';
$object = Mail::Log::Parse::Postfix->new({'logfile' => 't/data'});

# Boolean coercion: False condition.
ok(!($object), 'False boolean coercion.');

throws_ok {my $line = $object->next()} 'Mail::Log::Exceptions::LogFile';

# The next test doesn't work for root.  Try to skip if we need to.
SKIP:  {
	skip 'This test cannot be run as root.', 1 if ( $> == 0 );
	
	# This is going to test
	# a file that exists, but we can't read...
chmod (0000, 't/data/log');
throws_ok {$object = Mail::Log::Parse::Postfix->new({'log_file' => 't/data/log'})} 'Mail::Log::Exceptions::LogFile';
chmod (0644, 't/data/log');	# Make sure we set it back at the end.
}
}

my $object = Mail::Log::Parse::Postfix->new();

$object->set_logfile('t/data/log');

is($object->get_line_number(), 0, 'Starting line number.');

# A quick test of the coercions.
is("$object", 'Mail::Log::Parse::Postfix File: t/data/log Line: 0', 'String coercion.');
ok($object, 'True boolean coercion.');
throws_ok { 1 + $object } 'Mail::Log::Exceptions';

# Back from the beginning.
{
	my $result = $object->previous();
	is($result, undef, 'Previous from start.');
	ok(!$object->go_backward(3), 'Backward from start.');
}

# A quick test of the first line.
{
my $result = $object->next();

my @result_keys = sort keys %$result;
is_deeply( \@result_keys, \@keys, 'Hash key list.');
is($object->get_line_number(), 1, 'Read one line.');
is_deeply($result->{to}, ['<00000000@acme.gov>'], 'Read first to.');
is($result->{relay}, '127.0.0.1[127.0.0.1]:10025', 'Read first relay.');
is($result->{program}, 'postfix/smtp', 'Read first program.');
is($result->{pid}, '5727', 'Read first process ID.');
is($result->{host}, 'acmemail1', 'Read first hostname.');
is($result->{status}, 'sent (250 OK, sent 48A8F422_13987_12168_1 6B1B62259)', 'Read first status.');
is($result->{id}, 'CF6C9214B', 'Read first ID.');
my $timestamp = timelocal(38, 01, 00, 18, 7, $year);
is($result->{timestamp}, $timestamp, 'Read first timestamp');
is($result->{text}, 'to=<00000000@acme.gov>, relay=127.0.0.1[127.0.0.1]:10025, delay=0.63, delays=0.54/0/0/0.09, dsn=2.0.0, status=sent (250 OK, sent 48A8F422_13987_12168_1 6B1B62259)', 'Read first text.');
is($result->{delay_before_queue}, '0.54', 'Read first delay before queue.');
is($result->{delay_in_queue}, '0', 'Read first delay in queue.');
is($result->{delay_connect_setup}, '0', 'Read first delay connect setup.');
is($result->{delay_message_transmission}, '0.09', 'Read first delay message transmission.');
is($result->{delay}, '0.63', 'Read first total delay.');
is($result->{size}, undef, 'Read first size.');
is($result->{previous_host}, undef, 'Read first: Remote Host');
ok(!($result->{connect}), 'Read first Connect');
ok(!($result->{disconnect}), 'Read first disconnect');
}

# Go forward, testing iterator.
{
	lives_ok { is($object->go_forward(2), 1, 'Going forward.') } 'Going forwards.';
	is($object->get_line_number(), 3, 'Go forward line number.');
	
	my $result = <$object>;

	my @result_keys = sort keys %$result;
	is_deeply( \@result_keys, \@keys, 'Read after skip: Hash key list.');
	is($object->get_line_number(), 4, 'Read after skip: Line number.');
	is_deeply($result->{to}, [], 'Read after skip: To');
	is($result->{relay}, undef, 'Read after skip: Relay');
	is($result->{program}, 'postfix/smtpd', 'Read after skip: Program');
	is($result->{pid}, '5819', 'Read after skip: pid');
	is($result->{host}, 'acmemail1', 'Read after skip: hostname');
	is($result->{status}, undef, 'Read after skip: status');
	is($result->{id}, '7326D2B54', 'Read after skip: id');
	my $timestamp = timelocal(38, 01, 00, 18, 7, $year);
	is($result->{timestamp}, $timestamp, 'Read after skip: timestamp');
	is($result->{text}, 'client=unknown[10.0.80.60]', 'Read after skip: text');
	is($result->{delay_before_queue}, undef, 'Read after skip delay before queue.');
	is($result->{delay_in_queue}, undef, 'Read after skip delay in queue.');
	is($result->{delay_connect_setup}, undef, 'Read after skip delay connect setup.');
	is($result->{delay_message_transmission}, undef, 'Read after skip delay message transmission.');
	is($result->{delay}, undef, 'Read after skip total delay.');
	is($result->{size}, undef, 'Read after skip: size');
	is($result->{previous_host}, undef, 'Read after skip: Remote Host');
	ok(!($result->{connect}), 'Read after skip: Connect');
	ok(!($result->{disconnect}), 'Read after skip: disconnect');
}

# Read another line.  (This happens to be a connect, which are odd.)
{
	my $result = $object->next();

	my @result_keys = sort keys %$result;
	is_deeply( \@result_keys, \@keys, 'Read connect: Hash key list.');
	is($object->get_line_number(), 5, 'Read connect: Line number.');
	is_deeply($result->{to}, [], 'Read connect: To');
	is($result->{relay}, undef, 'Read connect: Relay');
	is($result->{program}, 'postfix/smtpd', 'Read connect: Program');
	is($result->{pid}, '5748', 'Read connect: pid');
	is($result->{host}, 'acmemail1', 'Read connect: hostname');
	is($result->{status}, undef, 'Read connect: status');
	is($result->{id}, undef, 'Read connect: id');
	my $timestamp = timelocal(38, 01, 00, 18, 7, $year);
	is($result->{timestamp}, $timestamp, 'Read connect: timestamp');
	is($result->{text}, 'connect from localhost.localdomain[127.0.0.1]', 'Read connect: text');
	is($result->{size}, undef, 'Read connect: size');
	is($result->{previous_host}, 'localhost.localdomain[127.0.0.1]', 'Read connect: Remote Host');
	is($result->{previous_host_name}, 'localhost.localdomain', 'Read connect: Remote host name');
	is($result->{previous_host_ip}, '127.0.0.1', 'Read connect: Remote host ip');
	ok($result->{connect}, 'Read connect: Connect');
	ok(!($result->{disconnect}), 'Read connect: disconnect');
}

# Let's go back again...
{
	lives_ok {is($object->go_backward(), 1, 'Going backward.') } 'Going backwards.';
	is($object->get_line_number(), 4, 'Go back line number.');

	my $result = $object->next();

	my @result_keys = sort keys %$result;
	is_deeply( \@result_keys, \@keys, 'Read after back: Hash key list.');
	is($object->get_line_number(), 5, 'Read after back: Line number.');
	is_deeply($result->{to}, [], 'Read after back: To');
	is($result->{from}, undef, 'Read after back: From');
	is($result->{relay}, undef, 'Read after back: Relay');
	is($result->{program}, 'postfix/smtpd', 'Read after back: Program');
	is($result->{pid}, '5748', 'Read after back: pid');
	is($result->{host}, 'acmemail1', 'Read after back: hostname');
	is($result->{status}, undef, 'Read after back: status');
	is($result->{id}, undef, 'Read after back: id');
	my $timestamp = timelocal(38, 01, 00, 18, 7, $year);
	is($result->{timestamp}, $timestamp, 'Read after backs timestamp');
	is($result->{text}, 'connect from localhost.localdomain[127.0.0.1]');
	is($result->{size}, undef, 'Read after back: size');
	is($result->{previous_host}, 'localhost.localdomain[127.0.0.1]', 'Read after back: Remote Host');
	ok(($result->{connect}), 'Read after back: Connect');
	ok(!($result->{disconnect}), 'Read after back: disconnect');
}

# Seek further back.
{
	lives_ok {ok(!$object->go_backward(6), 'All the way back.') } 'All the way back lives.';
	is($object->get_line_number(), 0, 'Back to start line number.');

	my $result = $object->next();

	my @result_keys = sort keys %$result;
	is_deeply( \@result_keys, \@keys, 'Read after backskip: Hash key list.');
	is($object->get_line_number(), 1, 'Read after backskip: Line number.');
	is_deeply($result->{to}, ['<00000000@acme.gov>'], 'Read after backskip: To');
	is($result->{from}, undef, 'Read after backskip: From');
	is($result->{relay}, '127.0.0.1[127.0.0.1]:10025', 'Read after backskip: Relay');
	is($result->{program}, 'postfix/smtp', 'Read after backskip: Program');
	is($result->{pid}, '5727', 'Read after backskip: pid');
	is($result->{host}, 'acmemail1', 'Read after backskip: hostname');
	is($result->{status}, 'sent (250 OK, sent 48A8F422_13987_12168_1 6B1B62259)', 'Read after backskip: status');
	is($result->{id}, 'CF6C9214B', 'Read after backskip: id');
	my $timestamp = timelocal(38, 01, 00, 18, 7, $year);
	is($result->{timestamp}, $timestamp, 'Read after backskip: timestamp');
	is($result->{text}, 'to=<00000000@acme.gov>, relay=127.0.0.1[127.0.0.1]:10025, delay=0.63, delays=0.54/0/0/0.09, dsn=2.0.0, status=sent (250 OK, sent 48A8F422_13987_12168_1 6B1B62259)');
	is($result->{size}, undef, 'Read after backskip: size');
	is($result->{previous_host}, undef, 'Read after backskip: Remote Host');
	ok(!($result->{connect}), 'Read after backskip: Connect');
	ok(!($result->{disconnect}), 'Read after backskip: disconnect');
}

# Seek forward.
{
	lives_ok {is($object->go_forward(), 1, 'Skip forward.') } 'Skip forward.';
	is($object->get_line_number(), 2, 'Skipped forward two.');
	
	my $result = $object->next();

	my @result_keys = sort keys %$result;
	is_deeply( \@result_keys, \@keys, 'Read after skip: Hash key list.');
	is($object->get_line_number(), 3, 'Read after skip: Line number.');
	is_deeply($result->{to}, [], 'Read after skip: To');
	is($result->{from}, '<00000001@baz.acme.gov>', 'Read after skip: From');
	is($result->{relay}, undef, 'Read after skip: Relay');
	is($result->{program}, 'postfix/qmgr', 'Read after skip: Program');
	is($result->{pid}, '20508', 'Read after skip: pid');
	is($result->{host}, 'acmemail1', 'Read after skip: hostname');
	is($result->{status}, undef, 'Read after skip: status');
	is($result->{id}, '6B1B62259', 'Read after skip: id');
	my $timestamp = timelocal(38, 01, 00, 18, 7, $year);
	is($result->{timestamp}, $timestamp, 'Read after skip: timestamp');
	is($result->{text}, 'from=<00000001@baz.acme.gov>, size=84778, nrcpt=7 (queue active)', 'Read after skip: text');
	is($result->{size}, '84778', 'Read after skip: size');
	is($result->{previous_host}, undef, 'Read after skip: Remote Host');
	ok(!($result->{connect}), 'Read after skip: Connect');
	ok(!($result->{disconnect}), 'Read after skip: disconnect');
}

# Seek forward.
{
	lives_ok {ok($object->go_forward(122), 'Skip forward.') } 'Skip forward lives.';
	my $result = $object->next();

	my @result_keys = sort keys %$result;
	is_deeply( \@result_keys, \@keys, 'Read after skip: Hash key list.');
	is($object->get_line_number(), 126, 'Read after skip: Line number.');
	is_deeply($result->{to}, ['<00000058@acme.gov>'], 'Read after skip: To');
	is($result->{from}, undef, 'Read after skip: From');
	is($result->{relay}, '127.0.0.1[127.0.0.1]:10025', 'Read after skip: Relay');
	is($result->{program}, 'postfix/smtp', 'Read after skip: Program');
	is($result->{pid}, '5841', 'Read after skip: pid');
	is($result->{host}, 'acmemail1', 'Read after skip: hostname');
	is($result->{status}, 'sent (250 OK, sent 48A8F422_13989_69085_1 012652BE7)', 'Read after skip: status');
	is($result->{id}, '7326D2B54', 'Read after skip: id');
	my $timestamp = timelocal(39, 01, 00, 18, 7, $year);
	is($result->{timestamp}, $timestamp, 'Read after skip: timestamp');
	is($result->{text}, 'to=<00000058@acme.gov>, relay=127.0.0.1[127.0.0.1]:10025, delay=0.59, delays=0.42/0/0/0.17, dsn=2.0.0, status=sent (250 OK, sent 48A8F422_13989_69085_1 012652BE7)');
	is($result->{size}, undef, 'Read after skip: size');
	is($result->{previous_host}, undef, 'Read after skip: Remote Host');
	ok(!($result->{connect}), 'Read after skip: Connect');
	ok(!($result->{disconnect}), 'Read after skip: disconnect');
}

# Previous line.
{
	my $result = $object->previous();

	my @result_keys = sort keys %$result;
	is_deeply( \@result_keys, \@keys, 'Read previous: Hash key list.');
	is($object->get_line_number(), 125, 'Read previous: Line number.');
	is_deeply($result->{to}, [], 'Read previous: To');
	is($result->{from}, undef, 'Read previous: From');
	is($result->{relay}, undef, 'Read previous: Relay');
	is($result->{program}, 'postfix/cleanup', 'Read previous: Program');
	is($result->{pid}, '5840', 'Read previous: pid');
	is($result->{host}, 'acmemail1', 'Read previous: hostname');
	is($result->{status}, undef, 'Read previous: status');
	is($result->{id}, '012652BE7', 'Read previous: id');
	my $timestamp = timelocal(39, 01, 00, 18, 7, $year);
	is($result->{timestamp}, $timestamp, 'Read previous: timestamp');
	is($result->{text}, 'message-id=<D31A582E5B6A2B45902C41C643D99A5A01399D5C@K001MB101.network.ad.baz.gov>');
	is($result->{size}, undef, 'Read previous: size');
	is($result->{previous_host}, undef, 'Read previous: Remote Host');
	ok(!($result->{connect}), 'Read previous: Connect');
	ok(!($result->{disconnect}), 'Read previous: disconnect');
}

# We'll also try setting the year, and starting over.
{
	$object->set_year(1999);
	$object->go_to_line_number(1);
	my $result = $object->next();

	my @result_keys = sort keys %$result;
	is_deeply( \@result_keys, \@keys, 'Read restart: Hash key list.');
	is($object->get_line_number(), 2, 'Read restart: Line number.');
	is_deeply($result->{to}, [], 'Read restart: To');
	is($result->{from}, undef, 'Read restart: From');
	is($result->{relay}, undef, 'Read restart: Relay');
	is($result->{program}, 'postfix/smtpd', 'Read restart: Program');
	is($result->{pid}, '5833', 'Read restart: pid');
	is($result->{host}, 'acmemail1', 'Read restart: hostname');
	is($result->{status}, undef, 'Read restart: status');
	is($result->{id}, undef, 'Read restart: id');
	my $timestamp = timelocal(38, 01, 00, 18, 7, 1999);
	is($result->{timestamp}, $timestamp, 'Read restart: timestamp');
	is($result->{text}, 'disconnect from localhost.localdomain[127.0.0.1]');
	is($result->{size}, undef, 'Read restart: size');
	is($result->{previous_host}, 'localhost.localdomain[127.0.0.1]', 'Read restart: Remote Host');
	ok(!($result->{connect}), 'Read restart: Connect');
	ok(($result->{disconnect}), 'Read restart: disconnect');
}

# Seek forward.
{
	lives_ok {ok($object->go_forward(119), 'Skip forward.') } 'Skip forward lives.';
	$object->set_year(1998);
	my $result = $object->next();

	my @result_keys = sort keys %$result;
	is_deeply( \@result_keys, \@keys, 'Read after skip (reset year/buffer): Hash key list.');
	is($object->get_line_number(), 122, 'Read after skip (reset year/buffer): Line number.');
	is_deeply($result->{to}, [], 'Read after skip (reset year/buffer): To');
	is($result->{from}, undef, 'Read after skip (reset year/buffer): From');
	is($result->{relay}, undef, 'Read after skip (reset year/buffer): Relay');
	is($result->{program}, 'postfix/smtpd', 'Read after skip (reset year/buffer): Program');
	is($result->{pid}, '5819', 'Read after skip (reset year/buffer): pid');
	is($result->{host}, 'acmemail1', 'Read after skip: hostname');
	is($result->{status}, undef, 'Read after skip (reset year/buffer): status');
	is($result->{id}, 'ECF422BE6', 'Read after skip (reset year/buffer): id');
	my $timestamp = timelocal(38, 01, 00, 18, 7, 1998);
	is($result->{timestamp}, $timestamp, 'Read after skip (reset year/buffer): timestamp');
	is($result->{text}, 'client=unknown[10.0.80.60]');
	is($result->{size}, undef, 'Read after skip (reset year/buffer): size');
	is($result->{previous_host}, undef, 'Read after skip (reset year/buffer): Remote Host');
	ok(!($result->{connect}), 'Read after skip (reset year/buffer): Connect');
	ok(!($result->{disconnect}), 'Read after skip (reset year/buffer): disconnect');
}

# Next Buffer window.
{
	my $result = $object->next();

	my @result_keys = sort keys %$result;
	is_deeply( \@result_keys, \@keys, 'Read after buffer window: Hash key list.');
	is($object->get_line_number(), 123, 'Read after buffer window: Line number.');
	is_deeply($result->{to}, [], 'Read after buffer window: To');
	is($result->{from}, undef, 'Read after buffer window: From');
	is($result->{relay}, undef, 'Read after buffer window: Relay');
	is($result->{program}, 'postfix/smtpd', 'Read after buffer window: Program');
	is($result->{pid}, '5747', 'Read after buffer window: pid');
	is($result->{host}, 'acmemail1', 'Read after buffer window: hostname');
	is($result->{status}, undef, 'Read after buffer window: status');
	is($result->{id}, undef, 'Read after buffer window: id');
	my $timestamp = timelocal(39, 01, 00, 18, 7, 1998);
	is($result->{timestamp}, $timestamp, 'Read after buffer window: timestamp');
	is($result->{text}, 'connect from localhost.localdomain[127.0.0.1]');
	is($result->{size}, undef, 'Read after buffer window: size');
	is($result->{previous_host}, 'localhost.localdomain[127.0.0.1]', 'Read after buffer window: Remote Host');
	ok(($result->{connect}), 'Read after buffer window: Connect');
	ok(!($result->{disconnect}), 'Read after buffer window: disconnect');
}


# Seek forward.
{
	lives_ok {ok($object->go_forward(300), 'Skip forward.') } 'Skip forward lives.';
	my $result = $object->next();

	my @result_keys = sort keys %$result;
	is_deeply( \@result_keys, \@keys, 'Read after skip: Hash key list.');
	is($object->get_line_number(), 424, 'Read after skip: Line number.');
	is_deeply($result->{to}, ['<00000113@acme.gov>'], 'Read after skip: To');
	is($result->{from}, undef, 'Read after skip: From');
	is($result->{relay}, '127.0.0.1[127.0.0.1]:10025', 'Read after skip: Relay');
	is($result->{program}, 'postfix/smtp', 'Read after skip: Program');
	is($result->{pid}, '5841', 'Read after skip: pid');
	is($result->{host}, 'acmemail1', 'Read after skip: hostname');
	is($result->{status}, 'sent (250 OK, sent 48A8F462_13989_69099_1 76F6A2259)', 'Read after skip: status');
	is($result->{id}, 'DA0B0214B', 'Read after skip: id');
	my $timestamp = timelocal(42, 2, 00, 18, 7, 1998);
	is($result->{timestamp}, $timestamp, 'Read after skip: timestamp');
	is($result->{text}, 'to=<00000113@acme.gov>, relay=127.0.0.1[127.0.0.1]:10025, delay=0.68, delays=0.59/0/0/0.08, dsn=2.0.0, status=sent (250 OK, sent 48A8F462_13989_69099_1 76F6A2259)');
	is($result->{size}, undef, 'Read after skip: size');
	is($result->{previous_host}, undef, 'Read after skip: Remote Host');
	ok(!($result->{connect}), 'Read after skip: Connect');
	ok(!($result->{disconnect}), 'Read after skip: disconnect');
}


# Read to exaustion.
{
	$object->go_to_end();
	is($object->get_line_number(), 900, 'Read to end of file.');
}

# Can we go forward now?
{
	ok(!$object->go_forward(3), 'Go past end.');
}

# Go back to start.
{
	$object->go_to_beginning();
	is($object->get_line_number(), 0, 'Skip to begining.');
}

# Go to a specific line number.
{
	$object->go_to_line_number(10);
	is($object->get_line_number(), 10, 'Go to line 10 (Forward.)');
	my $result = $object->next();

	my @result_keys = sort keys %$result;
	is_deeply( \@result_keys, \@keys, 'Read after skip (from beginning and forward): Hash key list.');
	is($object->get_line_number(), 11, 'Read after skip (from beginning and forward): Line number.');
	is_deeply($result->{to}, ['<00000006@acme.gov>'], 'Read after skip (from beginning and forward): To');
	is($result->{from}, undef, 'Read after skip (from beginning and forward): From');
	is($result->{relay}, '10.0.0.1[10.0.0.1]:1025', 'Read after skip (from beginning and forward): Relay');
	is($result->{program}, 'postfix/smtp', 'Read after skip (from beginning and forward): Program');
	is($result->{pid}, '5772', 'Read after skip (from beginning and forward): pid');
	is($result->{host}, 'acmemail1', 'Read after skip (from beginning and forward): hostname');
	is($result->{status}, 'sent (250 Message received and queued)', 'Read after skip (from beginning and forward): status');
	is($result->{id}, '6B1B62259', 'Read after skip (from beginning and forward): id');
	my $timestamp = timelocal(38, 01, 00, 18, 7, 1998);
	is($result->{timestamp}, $timestamp, 'Read after skip (from beginning and forward): timestamp');
	is($result->{text}, 'to=<00000006@acme.gov>, relay=10.0.0.1[10.0.0.1]:1025, delay=0.06, delays=0.01/0/0/0.05, dsn=2.0.0, status=sent (250 Message received and queued)');
	is($result->{size}, undef, 'Read after skip (from beginning and forward): size');
	is($result->{previous_host}, undef, 'Read after skip (from beginning and forward): Remote Host');
	ok(!($result->{connect}), 'Read after skip (from beginning and forward): Connect');
	ok(!($result->{disconnect}), 'Read after skip (from beginning and forward): disconnect');
}

# Again, backwards.
{
	$object->go_to_line_number(4);
	is($object->get_line_number(), 4, 'Go to line 4 (Backwards.)');
	my $result = $object->next();

	my @result_keys = sort keys %$result;
	is_deeply( \@result_keys, \@keys, 'Read after skip (from beginning and back): Hash key list.');
	is($object->get_line_number(), 5, 'Read after skip (from beginning and back): Line number.');
	is_deeply($result->{to}, [], 'Read after skip (from beginning and back): To');
	is($result->{from}, undef, 'Read after skip (from beginning and backr): From');
	is($result->{relay}, undef, 'Read after skip (from beginning and back): Relay');
	is($result->{program}, 'postfix/smtpd', 'Read after skip (from beginning and back): Program');
	is($result->{pid}, '5748', 'Read after skip (from beginning and back): pid');
	is($result->{host}, 'acmemail1', 'Read after skip (from beginning and back): hostname');
	is($result->{status}, undef, 'Read after skip (from beginning and back): status');
	is($result->{id}, undef, 'Read after skip (from beginning and back): id');
	my $timestamp = timelocal(38, 01, 00, 18, 7, 1998);
	is($result->{timestamp}, $timestamp, 'Read after skip (from beginning and back): timestamp');
	is($result->{text}, 'connect from localhost.localdomain[127.0.0.1]');
	is($result->{size}, undef, 'Read after skip (from beginning and back): size');
	is($result->{previous_host}, 'localhost.localdomain[127.0.0.1]', 'Read after skipt (from beginning and back): Remote Host');
	ok(($result->{connect}), 'Read after skip (from beginning and back): Connect');
	ok(!($result->{disconnect}), 'Read after skip (from beginning and back): disconnect');
}
