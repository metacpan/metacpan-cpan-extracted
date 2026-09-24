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

subtest 'fixed positionals' => sub {
	my $opt = GetOptions(
		argv    => ['--owner', 'dave', 'https://example.com/x.git'],
		options => { owner => { type => 's' } },
		args    => [{ type => 'url', short => 'source-url', required => 1 }],
	);
	is $opt->sourceUrl, 'https://example.com/x.git', 'arg reader';

	my $mixed = GetOptions(
		argv    => ['https://example.com/x.git', '--owner', 'dave'],
		options => { owner => { type => 's' } },
		args    => [{ type => 'url', short => 'source-url', required => 1 }],
	);
	is $mixed->owner, 'dave', 'options may follow positionals (permute)';
};

subtest 'optional and slurpy positionals' => sub {
	my $opt = GetOptions(
		argv => ['in.txt'],
		args => [
			{ short => 'input', required => 1 },
			{ short => 'output' },
		],
	);
	is $opt->input,  'in.txt', 'required present';
	is $opt->output, undef,    'optional missing is undef';

	my $slurpy = GetOptions(
		argv => ['a.txt', 'b.txt', 'c.txt'],
		args => [{ short => 'inputs', required => 1, multiple => 1 }],
	);
	is $slurpy->inputs, ['a.txt', 'b.txt', 'c.txt'], 'slurpy collects the rest';

	my $emptySlurpy = GetOptions(
		argv => [],
		args => [{ short => 'inputs', multiple => 1 }],
	);
	is $emptySlurpy->inputs, undef, 'empty optional slurpy is undef';
};

subtest 'positional failures' => sub {
	like dies { parseWith([], args => [{ short => 'source', required => 1 }]) },
		qr/missing required argument <source>/, 'missing required arg';

	like dies { parseWith([], args => [{ short => 'inputs', required => 1, multiple => 1 }]) },
		qr/missing required argument <inputs>/, 'missing required slurpy';

	like dies { parseWith(['x', 'y'], args => [{ short => 'only' }]) },
		qr/unexpected extra argument 'y'/, 'too many positionals';

	like dies { parseWith(['stray'], options => {}) },
		qr/unexpected extra argument 'stray'/, 'positional without args spec';

	like dies { parseWith(['not a url'], args => [{ short => 'source', type => 'url' }]) },
		qr/argument <source>: 'not a url' is not a URL/, 'arg type failure';
};

done_testing;
