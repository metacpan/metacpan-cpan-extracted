#!perl
use Test::More;
use Test::Deep;
use_ok 'Jig::CLI';

subtest 'with an empty command / no args / no flags' => sub {
	my ($cmd, $opts, $args) = cli([
		[qw[ help|h
		     debug|D ]]
	], ());

	is $cmd, '', "command should be empty";
	cmp_deeply $opts, {}, 'should have no options';
	cmp_deeply $args, [], 'should have no arguments';
};

subtest 'with just argumnets' => sub {
	my ($cmd, $opts, $args) = cli([
		[qw[ help|h
		     debug|D ]]
	], qw(foo bar baz));

	is $cmd, '', "command should be empty";
	cmp_deeply $opts, {}, 'should have no options';
	cmp_deeply $args, [qw[
		foo bar baz
	]], 'should have arguments';
};

subtest 'with a command' => sub {
	my ($cmd, $opts, $args) = cli([
		[qw[ help|h
		     debug|D ]],
		foo => undef,
	], qw(foo));

	is $cmd, 'foo', "command should not be empty";
	cmp_deeply $opts, {}, 'should have no options';
	cmp_deeply $args, [], 'should have no arguments';
};

subtest 'with a command, multiple flag levels, and some arguments' => sub {
	my ($cmd, $opts, $args) = cli([
		[qw[ help|h
		     debug|D ]],
		foo => [ [qw[ bar|B ]] ],
	], qw(-D foo -B bar baz));

	is $cmd, 'foo', "command should not be empty";
	cmp_deeply $opts, {
		debug => bool(1),
		bar   => bool(1),
	}, 'should have options';
	cmp_deeply $args, [qw[bar baz]], 'should have arguments';
};

subtest 'with multiple, nested sub-commands' => sub {
	my ($cmd, $opts, $args) = cli([[],
		foo => [[],
			bar => [[],
				baz => undef]],
	], qw(foo bar baz));

	is $cmd, 'foo bar baz', "command should not be empty";
	cmp_deeply $opts, {}, 'should have no options';
	cmp_deeply $args, [], 'should have no arguments';
};

subtest 'global options can appear after sub-commands' => sub {
	my ($cmd, $opts, $args) = cli([[qw[debug|D]],
		foo => [[],
			bar => [[],
				baz => undef]],
	], qw(foo bar -D baz));

	is $cmd, 'foo bar baz', "command should not be empty";
	cmp_deeply $opts, { debug => bool(1), }, 'should have global --debug option';
	cmp_deeply $args, [], 'should have no arguments';
};

done_testing;
