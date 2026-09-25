use v5.26;
use experimental 'signatures';
use Test2::V0;

use File::Temp qw(tempdir);
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
	is $absent->tag, [], 'absent multiple option reads as an empty list';
};

subtest 'csv' => sub {
	my %csv = (tag => { type => 's', multiple => 1, csv => 1 });
	is parseWith(['--tag', 'a, b', '--tag', 'c,'], options => {%csv})->tag, ['a', 'b', 'c'], 'words split at commas, items trimmed, trailing comma tolerated';
	is parseWith(['--n', '1,2'], options => { n => { type => 'i', multiple => 1, csv => 1 } })->n, [1, 2], 'items pass the type';

	like dies { parseWith(['--tag', 'a,,b'], options => {%csv}) }, qr/option '--tag': 'a,,b' contains an empty item/, 'empty item in the middle';
	like dies { parseWith(['--tag', ','], options => {%csv}) },    qr/option '--tag': ',' contains an empty item/,    'a lone comma';
	like dies { parseWith(['--tag', 'a,x'], options => { tag => { type => 's', multiple => 1, csv => 1, valid => ['a'] } }) },
		qr/option '--tag': 'x' is not one of: a/, 'the valid list applies per item';
};

subtest 'hash' => sub {
	my $opt = GetOptions(
		argv    => ['--define', 'os=linux', '--define', 'os=bsd', '-D', 'flags=a=b'],
		options => { 'define|D' => { type => 's', hash => 1 } },
	);
	is $opt->define, { os => 'bsd', flags => 'a=b' }, 'key=value pairs merged, last key wins, split at the first =';

	my $typed = GetOptions(
		argv    => ['--limit', 'cpu=2', '--limit', 'mem=512'],
		options => { limit => { type => 'i', hash => 1, default => { cpu => 1 } } },
	);
	is $typed->limit, { cpu => 2, mem => 512 }, 'values pass the type and a given hash replaces the default';

	my $absent = GetOptions(argv => [], options => { define => { type => 's', hash => 1 } });
	is $absent->define, {}, 'absent hash option reads as an empty mapping';

	like dies { parseWith(['--define', 'bare'], options => { define => { type => 's', hash => 1 } }) },
		qr/Option define, key "bare", requires a value/, 'a key without a value';
	like dies { parseWith(['--define', '=x'], options => { define => { type => 's', hash => 1 } }) },
		qr/option '--define': empty key/, 'an empty key';
	like dies { parseWith(['--limit', 'cpu=lots'], options => { limit => { type => 'i', hash => 1 } }) },
		qr/option '--limit': key 'cpu': 'lots' is not an integer/, 'a value failing the type names its key';
};

subtest 'objectlist' => sub {
	my %server = (server => { type => 's', objectlist => 1 });
	my $opt = parseWith(['--server', '1.host=b', '--server', '0.host=a', '--server', '0.port=80', '--server', '0.host=c'], options => {%server});
	is $opt->server, [{ host => 'c', port => '80' }, { host => 'b' }], 'entries collected by index, repeated field overwrites';

	my $typed = parseWith(['--limit', '0.cpu=2'], options => { limit => { type => 'i', objectlist => 1, default => [{ cpu => 1 }] } });
	is $typed->limit, [{ cpu => 2 }], 'values pass the type and a given list replaces the default';
	is parseWith([], options => {%server})->server, [], 'absent objectlist option reads as an empty list';

	like dies { parseWith(['--server', '0.host=a', '--server', '2.host=b'], options => {%server}) }, qr/option '--server': missing index 1/, 'a gap in the indices';
	like dies { parseWith(['--server', 'host=a'], options => {%server}) },  qr/option '--server': invalid key 'host', expected INDEX.FIELD=VALUE/, 'a key without an index';
	like dies { parseWith(['--server', '0.a.b=x'], options => {%server}) }, qr/invalid key '0.a.b'/, 'nested fields are rejected';
	like dies { parseWith(['--limit', '0.cpu=lots'], options => { limit => { type => 'i', objectlist => 1 } }) },
		qr/option '--limit': entry 0: key 'cpu': 'lots' is not an integer/, 'a value failing the type names its entry and key';
};

subtest 'paths created when the parse settles on them' => sub {
	my $dir     = tempdir(CLEANUP => 1);
	my %workDir = ('work-dir' => { type => 'dir', createPathIfMissing => 1, default => "$dir/default" });

	parseWith(['--work-dir', "$dir/given"], options => {%workDir});
	ok -d "$dir/given",   'the given directory is created';
	ok !-d "$dir/default", 'the overridden default is not';

	parseWith([], options => {%workDir});
	ok -d "$dir/default", 'the default is created when it is the effective value';

	parseWith(["$dir/positional/out.txt"], args => [{ short => 'output', type => 'file', createPathIfMissing => 1 }]);
	ok -f "$dir/positional/out.txt", 'an arg path is created too';

	like dies { parseWith([], options => { 'work-dir' => { type => 'dir', mustExist => 1, createPathIfMissing => 1 } }) },
		qr/option 'work-dir': mustExist and createPathIfMissing are mutually exclusive/, 'both keys is a spec error';
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
