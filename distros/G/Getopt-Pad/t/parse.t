use v5.26;
use experimental 'signatures';
use Test2::V0;

use Getopt::Pad;
use Getopt::Pad::Spec;
use Getopt::Pad::Parser;

sub parseWith($argv, %raw) {
	my $spec = Getopt::Pad::Spec->new(raw => \%raw);
	return Getopt::Pad::Parser->new(spec => $spec, argv => $argv)->parse;
}

subtest 'basic options' => sub {
	my $opt = GetOptions(
		argv    => ['--owner', 'dave', '--work-dir', '/tmp'],
		options => {
			'owner|o'  => { type => 's', required => 1 },
			'work-dir' => { type => 'dir' },
			'repo'     => { type => 's' },
		},
	);
	is $opt->owner,   'dave', 'long option';
	is $opt->workDir, '/tmp', 'camelCase reader';
	is $opt->repo,    undef,  'absent optional option is undef';
};

subtest 'aliases and bundling' => sub {
	my $opt = GetOptions(
		argv    => ['-o', 'dave'],
		options => { 'owner|o' => { type => 's' } },
	);
	is $opt->owner, 'dave', 'single-letter alias';

	my $bundled = GetOptions(
		argv    => ['-vvv'],
		options => { 'verbose|v' => { type => '+' } },
	);
	is $bundled->verbose, 3, 'bundled counter';
};

subtest 'defaults and negation' => sub {
	my $opt = GetOptions(
		argv    => [],
		options => {
			'private'   => { type => '!', default => 1 },
			'log-level' => { type => 's', default => 'info', valid => [qw(debug info warn)] },
		},
	);
	is $opt->private,  1,      'bool default';
	is $opt->logLevel, 'info', 'string default';

	my $negated = GetOptions(
		argv    => ['--no-private'],
		options => { 'private' => { type => '!', default => 1 } },
	);
	is $negated->private, 0, 'negated bool';
};

subtest 'multiple' => sub {
	my $opt = GetOptions(
		argv    => ['--tag', 'a', '--tag', 'b'],
		options => { tag => { type => 's', multiple => 1 } },
	);
	is $opt->tag, ['a', 'b'], 'collected into arrayref';

	my $absent = GetOptions(argv => [], options => { tag => { type => 's', multiple => 1 } });
	is $absent->tag, undef, 'absent multiple option stays undef';
};

subtest 'validation failures' => sub {
	like dies { parseWith(['--frobnicate'], options => {}) },
		qr/Unknown option: frobnicate/, 'unknown option';

	like dies { parseWith([], options => { owner => { type => 's', required => 1 } }) },
		qr/missing required option '--owner'/, 'missing required';

	like dies { parseWith(['--width', 'abc'], options => { width => { type => 'i' } }) },
		qr/option '--width': 'abc' is not an integer/, 'type failure';

	like dies { parseWith(['--width', '0'], options => { width => { type => 'i', min => 1 } }) },
		qr/0 is smaller than the minimum of 1/, 'min violated';

	like dies { parseWith(['--log-level', 'nope'], options => { 'log-level' => { type => 's', valid => [qw(info warn)] } }) },
		qr/option '--log-level': 'nope' is not one of: info, warn/, 'valid list';

	like dies { parseWith(['--user-id', '3'], options => { 'user-id' => { type => 'i', valid => sub { [1, 2] } } }) },
		qr/option '--user-id': '3' is not one of: 1, 2/, 'valid coderef lists the allowed values';

	like dies { parseWith(['--user-id', '3'], options => { 'user-id' => { type => 'i', valid => sub { 1 } } }) },
		qr/spec: option 'user-id': the valid coderef must return an array reference/, 'valid coderef returning no list is a spec error';

	like dies { parseWith(['--even', '3'], options => { even => { type => 'i', lazyValid => sub($n) { $n % 2 == 0 } } }) },
		qr/option '--even': '3' is not a valid value/, 'lazyValid predicate';

	like dies { parseWith([], options => { even => { type => 'i', lazyValid => [2] } }) },
		qr/spec: option 'even': lazyValid must be a code reference/, 'lazyValid needs a coderef';

	like dies { parseWith(['--own', 'x'], options => { owner => { type => 's' } }) },
		qr/Unknown option: own/, 'no abbreviation';

	like dies { parseWith([], options => { level => { type => 's', default => 'bad', valid => [qw(a b)] } }) },
		qr/spec: option 'level': default value: 'bad' is not one of: a, b/, 'invalid default is a spec error';

	like dies { parseWith(['--level', 'a'], options => { level => { type => 's', default => 'bad', valid => [qw(a b)] } }) },
		qr/spec: option 'level': default value: 'bad' is not one of: a, b/, 'invalid default dies even when the option is given';
};

done_testing;
