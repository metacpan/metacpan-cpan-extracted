#!/usr/bin/env perl
# t/structured_fields.t -- structured fields, e.g. $log->info('msg', { user_id => 42 })

use strict;
use warnings;

use File::Temp qw(tempdir);
use Socket qw(AF_UNIX SOCK_DGRAM sockaddr_un MSG_DONTWAIT);
use Test::Mockingbird;
use Test::Most;

use Log::Abstraction;

# Read a log file back as text, tolerating CRLF line endings on Windows
sub slurp {
	my ($path) = @_;
	open(my $fin, '<:raw', $path) or die "$path: $!";
	local $/;
	my $data = <$fin>;
	close $fin;
	$data =~ s/\r\n/\n/g;
	return $data;
}

my $tmpdir = tempdir(CLEANUP => 1);

subtest 'history and array backends record the fields' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => \@array);

	my $ret = $log->info('login', { user_id => 42 });
	is($ret, $log, 'info still returns $self');
	is_deeply(\@array, [ { level => 'info', message => 'login', fields => { user_id => 42 } } ],
		'array entry has a fields key');
	is_deeply($log->messages()->[0]{fields}, { user_id => 42 }, 'history has the fields');
};

subtest 'every level accepts fields' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => { array => \@array });

	for my $level (qw(trace debug info notice warn error)) {
		$log->$level("$level message", { level_name => $level });
	}
	is(scalar(@array), 6, 'six entries');
	for my $entry (@array) {
		is($entry->{message}, "$entry->{level} message", "$entry->{level}: message excludes the fields");
		is_deeply($entry->{fields}, { level_name => $entry->{level} }, "$entry->{level}: fields kept");
	}
};

subtest 'messages without fields are unchanged' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => \@array);

	$log->info('plain');
	$log->info('empty fields', {});
	$log->info('a', 'b');
	$log->info(['c', 'd'], { x => 1 });

	ok(!exists($array[0]{fields}), 'no fields key without fields');
	ok(!exists($array[1]{fields}), 'an empty hashref adds no fields key');
	is($array[1]{message}, 'empty fields', 'an empty hashref is not part of the message');
	is($array[2]{message}, 'ab', 'plain lists still join');
	is($array[3]{message}, 'cd', 'an arrayref message may be followed by fields');
	is_deeply($array[3]{fields}, { x => 1 }, '... and its fields are kept');
};

subtest 'a lone hashref is a message, not fields' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => \@array);

	$log->warn({ warning => 'named form' });
	$log->warn(warning => 'pair form', { code => 3 });
	$log->error({ warning => 'named with fields' }, { code => 4 });

	is($array[0]{message}, 'named form', 'warn({ warning => ... }) still works');
	ok(!exists($array[0]{fields}), '... with no fields');
	is($array[1]{message}, 'pair form', 'warn(warning => ..., \%fields)');
	is_deeply($array[1]{fields}, { code => 3 }, '... has its fields');
	is($array[2]{message}, 'named with fields', 'error({ warning => ... }, \%fields)');
	is_deeply($array[2]{fields}, { code => 4 }, '... has its fields');
};

subtest 'fields are copied' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => \@array);

	my %fields = (user_id => 42);
	$log->info('copy', \%fields);
	$fields{user_id} = 99;
	is($array[0]{fields}{user_id}, 42, 'changing the caller\'s hash later has no effect');
};

subtest 'below-threshold messages are dropped with their fields' => sub {
	my @array;
	my $log = Log::Abstraction->new(level => 'error', logger => \@array);

	$log->info('dropped', { x => 1 });
	is(scalar(@array), 0, 'nothing logged');
};

subtest 'CODE backend receives a fields key' => sub {
	my @calls;
	my $log = Log::Abstraction->new(level => 'debug', logger => sub { push @calls, $_[0] }, ctx => 'c');

	$log->notice('cb', { k => 'v' });
	$log->notice('no fields');

	is_deeply($calls[0]{message}, ['cb'], 'message excludes the fields');
	is_deeply($calls[0]{fields}, { k => 'v' }, 'fields passed through');
	is($calls[0]{ctx}, 'c', 'ctx still passed');
	ok(!exists($calls[1]{fields}), 'no fields key without fields');
};

subtest 'text format appends logfmt key=value pairs' => sub {
	my $file = "$tmpdir/text.log";
	my $log = Log::Abstraction->new(level => 'debug', logger => { file => $file });

	$log->info('login', {
		user_id => 42,
		name    => 'Jane Doe',
		quote   => 'say "hi"',
		empty   => '',
		undef   => undef,
		list    => [1, 2],
		'bad key=x' => 'v',
	});
	my $data = slurp($file);
	like($data, qr/\Q login bad_key_x=v empty="" list=[1,2] name="Jane Doe" quote="say \"hi\"" undef="" user_id=42\E\n\z/,
		'sorted, quoted and escaped');
};

subtest 'a field value cannot forge a log entry' => sub {
	my $file = "$tmpdir/forge.log";
	my $log = Log::Abstraction->new(level => 'debug', logger => $file);

	$log->info('x', { evil => "a\nERROR> [2026-01-01 00:00:00] forged" });
	my @lines = split(/\n/, slurp($file));
	is(scalar(@lines), 1, 'one line');
	like($lines[0], qr/evil="a\\nERROR> /, 'line break written as \n');
};

subtest 'format tokens in field values are not expanded' => sub {
	local $ENV{SF_SECRET} = 'leaked';
	my $file = "$tmpdir/env.log";
	my $log = Log::Abstraction->new(level => 'debug', logger => $file, format => '%message% %env_SF_SECRET%');

	$log->info('m', { v => '%env_SF_SECRET%' });
	is(slurp($file), "m v=%env_SF_SECRET% leaked\n", 'only the format\'s token is expanded');
};

subtest 'JSON format has a nested fields object' => sub {
	require JSON::PP;
	my $file = "$tmpdir/json.log";
	my $log = Log::Abstraction->new(level => 'debug', file => $file, format => 'json', array => []);

	$log->info('j', { user => 42, deep => { a => [1] }, obj => $log });
	$log->info('none');

	my @lines = split(/\n/, slurp($file));
	my $first = JSON::PP->new->decode($lines[0]);
	is($first->{message}, 'j', 'message');
	is_deeply($first->{fields}{deep}, { a => [1] }, 'nested data kept as data');
	is($first->{fields}{user}, 42, 'scalar field');
	like($first->{fields}{obj}, qr/^Log::Abstraction=HASH/, 'object stringified');
	ok(!exists(JSON::PP->new->decode($lines[1])->{fields}), 'no fields key without fields');
};

subtest 'fd backend gets the fields' => sub {
	my $out = '';
	open(my $fh, '>', \$out) or die $!;
	my $log = Log::Abstraction->new(level => 'debug', fd => $fh, array => []);

	$log->info('fd', { n => 1 });
	close $fh;
	like($out, qr/ fd n=1\n\z/, 'fields appended');
};

subtest 'object backend gets the fields as text' => sub {
	{
		package Local::Obj;
		sub new { return bless { got => [] }, shift }
		sub info { my $self = shift; push @{$self->{got}}, [@_] }
	}
	my $obj = Local::Obj->new();
	my $log = Log::Abstraction->new(level => 'debug', logger => $obj);

	$log->info('obj', { n => 1 });
	is_deeply($obj->{got}, [ ['obj', ' n=1'] ], 'fields appended as a separate string');
};

subtest 'syslog gets the fields as text' => sub {
	my @sent;
	my $g1 = Test::Mockingbird::mock_scoped('Sys::Syslog::openlog' => sub { 1 });
	my $g2 = Test::Mockingbird::mock_scoped('Sys::Syslog::syslog' => sub { push @sent, [@_] });
	my $g3 = Test::Mockingbird::mock_scoped('Sys::Syslog::closelog' => sub { 1 });

	my $log = Log::Abstraction->new(level => 'debug', script_name => 'sf', logger => { syslog => {} });
	$log->info('sys', { n => 1 });
	is($sent[0][1], '%s', 'message passed through %s');
	is($sent[0][2], 'sys n=1', 'fields appended');
	undef $log;
};

subtest 'journald gets the fields as journal fields' => sub {
	my $ok = eval { socket(my $probe, AF_UNIX, SOCK_DGRAM, 0) or die "$!\n"; close $probe; 1 };
	plan skip_all => 'Unix domain sockets not available' unless($ok);

	my $sockpath = "$tmpdir/journal.socket";
	socket(my $recv, AF_UNIX, SOCK_DGRAM, 0) or die "socket: $!";
	bind($recv, sockaddr_un($sockpath)) or die "bind: $!";

	my $log = Log::Abstraction->new(level => 'debug', logger => { journald => { socket => $sockpath, app => 'a' } });
	$log->info('jd', {
		user_id   => 42,
		'req-id'  => 'r1',
		_hidden   => 'h',
		MESSAGE   => 'forged',
		priority  => 0,
		multi     => "a\nb",
		app       => 'override',
		'___'     => 'nameless',
	});

	my $data = '';
	recv($recv, $data, 65536, MSG_DONTWAIT);
	close $recv;
	unlink $sockpath;

	like($data, qr/^MESSAGE=jd$/m, 'MESSAGE is the message');
	like($data, qr/^PRIORITY=6$/m, 'PRIORITY not overridden');
	like($data, qr/^USER_ID=42$/m, 'field name upper-cased');
	like($data, qr/^REQ_ID=r1$/m, 'invalid characters become _');
	like($data, qr/^HIDDEN=h$/m, 'leading _ removed');
	like($data, qr/^APP=override$/m, 'a field overrides the config hash');
	like($data, qr/^MULTI\n/m, 'a multi-line value uses binary framing');
	unlike($data, qr/nameless/, 'a field with no valid name is dropped');
	unlike($data, qr/forged/, 'MESSAGE can\'t be replaced');
};

subtest 'Log::Any passes fields through structured()' => sub {
	my $ok = eval { require Log::Any; require Log::Any::Adapter; 1 };
	plan skip_all => 'Log::Any not installed' unless($ok);

	my @array;
	my $la = Log::Abstraction->new(level => 'debug', logger => \@array);
	Log::Any::Adapter->set('Abstraction', instance => $la);
	my $log = Log::Any->get_logger(category => 'SF');

	my $line = __LINE__; $log->info('any', 'thing', { user_id => 7 });
	$log->warning('w', { code => 1 });
	$log->info('plain');
	$log->context->{request} = 'r9';
	$log->info('ctx', { user_id => 8 });

	is($array[0]{message}, 'any thing', 'parts joined with a space');
	is_deeply($array[0]{fields}, { user_id => 7 }, 'fields reach Log::Abstraction as data');
	is($array[1]{level}, 'warn', 'warning maps to warn');
	is_deeply($array[1]{fields}, { code => 1 }, 'warn gets fields');
	ok(!exists($array[2]{fields}), 'no fields key without fields');
	is_deeply($array[3]{fields}, { request => 'r9', user_id => 8 }, 'Log::Any context merged in');

	my @calls;
	my $cb = Log::Abstraction->new(level => 'debug', logger => sub { push @calls, $_[0] });
	Log::Any::Adapter->set('Abstraction', instance => $cb);
	$line = __LINE__; $log->info('where', { x => 1 });
	is($calls[0]{file}, __FILE__, 'caller file is this test');
	is($calls[0]{line}, $line, 'caller line is this test');
};

done_testing();
