use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use IO::Async::Loop;
use IO::AsyncX::System;

my $loop = IO::Async::Loop->new;

$loop->add(
	my $system = new_ok('IO::AsyncX::System')
);
is(exception {
	my ($code, $stdout, $stderr) = $system->run([$^X, '-e', 'print "test"'])->get;
	is($code, 0, 'exit success');
	cmp_deeply($stdout, ['test'], 'stdout correct');
}, undef, 'no exception');
is(exception {
	my $f = $system->run([$^X, '-e', 'sleep 3'], timeout => 0.5);
	$loop->await(
		Future->wait_any(
			$f,
			$loop->timeout_future(after => 5),
		)
	);
	ok($f->is_ready, 'future is ready');
	like($f->failure, qr/Timeout/, 'was a timeout');
}, undef, 'no exception');

is(exception {
	my ($code, $stdout, $stderr) = $system->run(
		[$^X, '-e', 'binmode STDOUT; print "\x{FA}\xF0"'],
		binary => 1,
	)->get;
	is($code, 0, 'exit success');
	cmp_deeply($stdout, ["\x{FA}\x{F0}"], 'stdout correct');
}, undef, 'no exception');

is(exception {
	my ($code, $stdout, $stderr) = $system->run(
		[$^X, '-e', 'binmode STDOUT, ":encoding(UTF-8)"; print "\x{2880}"'],
		utf8 => 1,
	)->get;
	is($code, 0, 'exit success');
	cmp_deeply($stdout, ["\x{2880}"], 'stdout correct');
}, undef, 'no exception');

is(exception {
	my ($code, $stdout, $stderr) = $system->run(
		[$^X, '-ne', 'print "" . reverse($_)'],
		utf8 => 1,
		stdin => 'test input',
	)->get;
	is($code, 0, 'exit success');
	cmp_deeply($stdout, ["tupni tset"], 'stdin processed correctly');
}, undef, 'no exception');

done_testing;

