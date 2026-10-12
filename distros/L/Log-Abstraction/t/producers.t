#!/usr/bin/env perl
# t/producers.t -- the log_any and log_dispatch backends, which hand messages
# on to Log::Any and Log::Dispatch

use strict;
use warnings;

use Test::Most;
use Test::Needs ();

use Log::Abstraction;

# A Log::Dispatch whose single output records "level: message" lines
sub dispatcher {
	my ($out, %opts) = @_;
	require Log::Dispatch;
	return Log::Dispatch->new(outputs => [[
		'Code',
		min_level => $opts{min_level} // 'debug',
		code      => sub { my %p = @_; push @{$out}, "$p{level}: $p{message}" },
	]]);
}

subtest 'log_dispatch receives every level' => sub {
	Test::Needs::test_needs('Log::Dispatch');
	my @out;
	my $log = Log::Abstraction->new(level => 'trace', logger => { log_dispatch => dispatcher(\@out) });

	$log->$_($_) for qw(trace debug info notice warn error critical alert emergency);
	is_deeply(\@out, [
		'debug: trace', 'debug: debug', 'info: info', 'notice: notice', 'warning: warn',
		'error: error', 'critical: critical', 'alert: alert', 'emergency: emergency',
	], 'levels mapped to Log::Dispatch names (trace -> debug, warn -> warning)');
};

subtest 'log_dispatch: arguments, fields, format and level' => sub {
	Test::Needs::test_needs('Log::Dispatch');
	my (@plain, @formatted, @high);
	my $log = Log::Abstraction->new(level => 'debug', logger => {
		log_dispatch => dispatcher(\@plain),
	});
	$log->info('a', 'b', { user => 'x y' });
	is_deeply(\@plain, [ 'info: ab user="x y"' ], 'joined with no space, fields as text');

	$log = Log::Abstraction->new(level => 'debug', logger => {
		log_dispatch => { log_dispatch => dispatcher(\@formatted), format => '[%level%] %message%' },
	});
	$log->info('hello');
	is_deeply(\@formatted, [ 'info: [INFO] hello' ], 'own format');

	$log = Log::Abstraction->new(level => 'debug', logger => {
		log_dispatch => { log_dispatch => dispatcher(\@high), level => 'warning' },
	});
	$log->info('dropped');
	$log->error('kept');
	is_deeply(\@high, [ 'error: kept' ], 'own level');
};

subtest 'a Log::Dispatch object as the logger' => sub {
	Test::Needs::test_needs('Log::Dispatch');
	my @out;
	my $log = Log::Abstraction->new(level => 'trace', logger => dispatcher(\@out));
	$log->trace('t', 'u');    # Log::Dispatch has no trace method
	$log->warn('w', { n => 1 });
	is_deeply(\@out, [ 'debug: tu', 'warning: w n=1' ], 'treated as log_dispatch');
};

subtest 'log_dispatch: a dying output only carps' => sub {
	Test::Needs::test_needs('Log::Dispatch');
	require Log::Dispatch;
	my @array;
	my $d = Log::Dispatch->new(outputs => [[ 'Code', min_level => 'debug', code => sub { die "boom\n" } ]]);
	my $log = Log::Abstraction->new(level => 'debug', logger => { log_dispatch => $d, array => \@array });

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	lives_ok { $log->info('x') } 'no exception';
	like($warnings[0], qr/Log::Dispatch failed: boom/, 'carped');
	is(scalar(@array), 1, 'other backends still run');
};

subtest 'log_any: category name, proxy, fields' => sub {
	Test::Needs::test_needs('Log::Any', 'Log::Any::Adapter');
	require Log::Any;
	require Log::Any::Adapter;

	my @seen;
	my $inner = Log::Abstraction->new(level => 'trace', logger => sub { push @seen, $_[0] });
	my $guard = Log::Any::Adapter->set({ lexically => \my $lex }, 'Abstraction', instance => $inner);

	my $log = Log::Abstraction->new(level => 'trace', logger => { log_any => 'My::Category' });
	my $line = __LINE__; $log->info('hello', 'world', { user_id => 42 });
	$log->warn('careful');
	$log->trace('fine');

	is(scalar(@seen), 3, 'three messages arrived through Log::Any');
	is_deeply($seen[0]{message}, [ 'helloworld' ], 'message joined with no space');
	is_deeply($seen[0]{fields}, { user_id => 42 }, 'fields arrived as structured data');
	is($seen[0]{line}, $line, 'caller line is the original call');
	is($seen[0]{file}, __FILE__, 'caller file is the original call');
	is_deeply([ map { $_->{level} } @seen ], [ qw(info warn trace) ], 'levels kept');

	@seen = ();
	my $proxy = Log::Any->get_logger(category => 'Other');
	$log = Log::Abstraction->new(level => 'trace', logger => {
		log_any => { log_any => $proxy, level => 'notice', format => '<%level%> %message%' },
	});
	$log->info('dropped');
	$log->notice('kept');
	is(scalar(@seen), 1, 'own level');
	is_deeply($seen[0]{message}, [ '<NOTICE> kept' ], 'own format');

	@seen = ();
	$log = Log::Abstraction->new(level => 'trace', logger => $proxy);
	$log->emergency('e');
	is_deeply([ $seen[0]{level}, $seen[0]{message} ], [ 'emergency', [ 'e' ] ], 'a proxy as the logger');
};

subtest 'log_any: a message is not forwarded in a loop' => sub {
	Test::Needs::test_needs('Log::Any', 'Log::Any::Adapter');
	require Log::Any::Adapter;

	my @array;
	my $log = Log::Abstraction->new(level => 'debug', logger => { log_any => 'Loop', array => \@array });
	my $guard = Log::Any::Adapter->set({ lexically => \my $lex }, 'Abstraction', instance => $log);

	lives_ok { $log->info('once') } 'no infinite recursion';
	is(scalar(@array), 2, 'logged directly and once more through Log::Any, then stopped');

	@array = ();
	$log->info('again');
	is(scalar(@array), 2, 'forwarding works again afterwards');
};

subtest 'new() validates the destinations' => sub {
	throws_ok { Log::Abstraction->new(logger => { log_dispatch => 'x' }) }
		qr/log_dispatch must be a Log::Dispatch object/, 'log_dispatch string';
	throws_ok { Log::Abstraction->new(logger => { log_dispatch => bless({}, 'Foo') }) }
		qr/log_dispatch must be a Log::Dispatch object/, 'object without log()';
	throws_ok { Log::Abstraction->new(logger => { log_any => [] }) }
		qr/log_any must be a Log::Any logger or a category name/, 'log_any arrayref';
	throws_ok { Log::Abstraction->new(logger => { log_any => bless({}, 'Foo') }) }
		qr/log_any must be a Log::Any logger or a category name/, 'log_any other object';
	throws_ok { Log::Abstraction->new(logger => { log_any => { level => 'info' } }) }
		qr/the log_any hash needs a 'log_any' key/, 'hash form without destination';
	throws_ok { Log::Abstraction->new(logger => { log_dispatch => { log_dispatch => bless({}, 'Foo'), level => 'bogus' } }) }
		qr/log_dispatch must be a Log::Dispatch object/, 'hash form, bad destination';
	SKIP: {
		skip 'Log::Dispatch not installed', 1 unless eval { require Log::Dispatch; 1 };
		throws_ok { Log::Abstraction->new(logger => { log_dispatch => { log_dispatch => dispatcher([]), level => 'bogus' } }) }
			qr/invalid log_dispatch level 'bogus'/, 'bad level';
	}
};

done_testing();
