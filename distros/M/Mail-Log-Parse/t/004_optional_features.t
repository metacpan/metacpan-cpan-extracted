#!/usr/bin/perl

use warnings;
use strict;
use Test::More;
use Test::Exception;
use Time::Local;
use Mail::Log::Parse::Postfix;
use Mail::Log::Exceptions;

if ( eval { require Test::Without::Module }
		and eval { require IO::Uncompress::AnyUncompress }
		and eval { require IO::Uncompress::Gunzip }
	) {
	Test::Without::Module->import( qw( File::Temp ) );
	plan( tests => 28 );
}
else {
	plan( skip_all => 'Need Test::Without::Module installed.');
}

# We'll need this value over and over.
( undef, undef, undef, undef, undef, my $year) = localtime;

# The keys list.
my @keys = sort qw(to from relay pid msgid program host status id timestamp text size delay_before_queue 
					delay_in_queue delay_connect_setup delay_message_transmission delay connect
					disconnect previous_host previous_host_name previous_host_ip);

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
	is($result, undef, 'Back from start.');
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

# Open a new file, which is compressed...
{
# Without File::Temp
throws_ok { $object->set_logfile('t/data/log.gz'); } 'Mail::Log::Exceptions';

# With File::Temp
SKIP: {
	eval { require File::Temp; File::Temp->VERSION(0.17); };

	skip "File::Temp version 0.17 required: $@", 2 if $@;

	# Without IO::Uncompress::AnyUncompress
	eval q{ Test::Without::Module->import( qw( IO::Uncompress::AnyUncompress ) ); };
	throws_ok { $object->set_logfile('t/data/log.gz'); } 'Mail::Log::Exceptions';

	eval q{ no Test::Without::Module qw( File::Temp ) };
	lives_and { $object->set_logfile('t/data/log.gz'); } 'Reloaded File::Temp';
}
}
