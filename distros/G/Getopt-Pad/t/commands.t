use v5.26;
use experimental 'signatures';
use Test2::V0;

use Getopt::Pad;
use Getopt::Pad::Spec;
use Getopt::Pad::Parser;

my %commandSpec = (
	options => {
		'verbose' => { type => '!', help => 'Print more information' },
	},
	commands => {
		'document' => {
			description => 'Work on documents',
			options     => { path => { type => 'file' } },
			commands    => {
				'create' => {
					description => 'Create a new document',
					options     => { format => { type => 's', valid => [qw(pdf docx)] } },
					args        => [{ short => 'title', required => 1 }],
				},
			},
		},
		'image' => {
			description => 'Work on images',
			options     => {
				width  => { type => 'i', min => 1 },
				height => { type => 'i', min => 1 },
			},
		},
	},
);

sub parseWith($argv, %raw) {
	my $spec = Getopt::Pad::Spec->new(raw => \%raw);
	return Getopt::Pad::Parser->new(spec => $spec, argv => $argv)->parse;
}

subtest 'nested descent with chained results' => sub {
	my $opt = GetOptions(
		argv => ['--verbose', 'document', 'create', '--format', 'pdf', 'My Doc'],
		%commandSpec,
	);

	is $opt->verbose, 1,          'outer option';
	is $opt->command, 'document', 'first command name';

	my $document = $opt->subcommand;
	is $document->command, 'create', 'second command name';

	my $create = $document->subcommand;
	is $create->format,     'pdf',    'inner option';
	is $create->title,      'My Doc', 'inner positional';
	is $create->subcommand, undef,    'leaf has no subcommand';
};

subtest 'options bind to their own level' => sub {
	my $opt = GetOptions(argv => ['image', '--width', '640'], %commandSpec);
	is $opt->command, 'image', 'command chosen';
	is $opt->subcommand->width, 640, 'option parsed by the inner level';

	like dies { parseWith(['--width', '640', 'image'], %commandSpec) },
		qr/Unknown option: width/, 'inner option unknown at the outer level';
};

subtest 'missing and unknown commands' => sub {
	like dies { parseWith([], %commandSpec) },
		qr/missing command, expected one of: document, image/, 'missing command lists candidates';

	like dies { parseWith(['frobnicate'], %commandSpec) },
		qr/unknown command 'frobnicate', expected one of: document, image/, 'unknown command lists candidates';

	my $optional = parseWith([],
		options         => { verbose => { type => '!' } },
		commands        => { doc => {} },
		commandRequired => 0,
	);
	is $optional->command,    undef, 'command undef when optional and absent';
	is $optional->subcommand, undef, 'subcommand undef when optional and absent';
};

subtest 'per-level help' => sub {
	my $spec = Getopt::Pad::Spec->new(raw => {%commandSpec});

	my $rootHelp = $spec->helperFor($spec->root, programName => 'tool', width => 100, color => 0)->renderHelp;
	like $rootHelp, qr/^# tool \[options\] <command>$/m, 'root header shows command placeholder';
	like $rootHelp, qr/^## Commands$/m, 'commands section';
	like $rootHelp, qr/^   document\s+Work on documents$/m, 'command with description';
	like $rootHelp, qr/^   image\s+Work on images$/m, 'second command listed';

	my $request = dies {
		Getopt::Pad::Parser->new(spec => $spec, argv => ['document', 'create', '--help'])->parse;
	};
	isa_ok $request, ['Getopt::Pad::ExitRequest'], 'nested --help throws';
	my $nested = $request->output;
	like $nested, qr/^# \S+ document create \[options\] title$/m, 'nested header carries the command path';
	like $nested, qr/^# Create a new document$/m, 'nested description';
};

subtest 'nested --help is not blocked by the outer level' => sub {
	my $request = dies {
		parseWith(['image', '--help'], %commandSpec, options => { owner => { type => 's', required => 1 } });
	};
	isa_ok $request, ['Getopt::Pad::ExitRequest'], 'help request despite a missing required root option';
	like $request->output, qr/^# \S+ image /m, 'help for the nested level';
};

done_testing;
