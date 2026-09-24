use v5.26;
use experimental 'signatures';
use Test2::V0;

use File::Spec;
use IPC::Open3 qw(open3);
use Symbol     qw(gensym);

use Getopt::Pad::Spec;
use Getopt::Pad::Parser;

my $libDir = File::Spec->rel2abs('lib');

my $spec = Getopt::Pad::Spec->new(raw => {
	options => {
		'owner|o' => { type => 's', required => 1, help => 'Target owner', group => 'Target' },
		'work-dir' => { type => 'dir', mustExist => 1, help => 'Where the clone is placed', group => 'General' },
		'dry-run'   => { help => 'Change nothing', group => 'General' },
		'log-level' => { type => 's', default => 'info', valid => [qw(debug info warn)], help => 'Logging level to use', group => 'General' },
		'private'   => { type => '!', default => 1, help => 'Create as private', group => 'Target' },
	},
	args => [
		{ type => 'url', short => 'source-url', required => 1, help => 'The source address' },
	],
	description => 'Migrate one Git repository.',
	examples    => [{ text => 'Basic run', args => '--owner dave x.git' }],
});

my $rendered = $spec->helperFor($spec->root, programName => 'migrate', width => 100, color => 0)->renderHelp;

subtest 'rendered layout' => sub {
	my @lines = split /\n/, $rendered;
	is $lines[0], '# migrate [options] source-url', 'header line';
	is $lines[1], '# Migrate one Git repository.',  'description line';

	like $rendered, qr/^## Arguments$/m, 'arguments section';
	like $rendered, qr/^   <source-url>\s+\[REQ\] The source address \[URL\]$/m, 'argument entry';

	like $rendered, qr/^## General$/m, 'group section';
	like $rendered, qr/^   --work-dir <>\s+\[has to exist\] Where the clone is placed \[Path\]$/m, 'constraint and type notes';
	like $rendered, qr/^   --dry-run\s+Change nothing$/m, 'bare flag entry';
	like $rendered, qr/^   --\[no-\]private\s+Create as private$/m, 'negatable label';
	like $rendered, qr/^\s+Valid   = \[ debug, info, warn \]$/m, 'valid subline';
	like $rendered, qr/^\s+Default = info$/m, 'default subline';

	my $generalPos = index($rendered, '## General');
	my $targetPos  = index($rendered, '## Target');
	ok $generalPos < $targetPos, 'groups sorted alphabetically';

	like $rendered, qr/^# Examples:$/m, 'examples header';
	like $rendered, qr/^## Basic run$/m, 'example text';
	like $rendered, qr/^##   migrate --owner dave x\.git$/m, 'example invocation';

	unlike $rendered, qr/--help/,    'auto help option hidden';
	unlike $rendered, qr/--version/, 'auto version option hidden';
	unlike $rendered, qr/\e\[/,      'no ANSI codes with color off';
};

subtest 'long help text wraps with hanging indent' => sub {
	my $wide = Getopt::Pad::Spec->new(raw => {
		options => { 'opt' => { type => 's', help => 'word ' x 40 } },
	});
	my $out = $wide->helperFor($wide->root, programName => 'x', width => 60, color => 0)->renderHelp;
	my @entry = grep { /word/ } split /\n/, $out;
	ok @entry > 1, 'text wrapped over multiple lines';
	ok length($_) <= 60, 'line within width' foreach @entry;
	like $entry[1], qr/^\s+word/, 'continuation lines indented';
};

subtest 'colored output' => sub {
	my $colored = $spec->helperFor($spec->root, programName => 'migrate', width => 100, color => 1)->renderHelp;
	my @lines = split /\n/, $colored;

	is $lines[0], "\e[1;31m# migrate [options] source-url\e[0m", 'usage line red including hashtag';
	is $lines[1], "\e[94m# Migrate one Git repository.\e[0m",    'description blue, not bold';
	like $colored, qr/^\e\[92m## Arguments\e\[0m$/m,              'section header green including hashtags';
	like $colored, qr/\e\[31m\[REQ\]\e\[0m/,                     'REQ painted red';
	like $colored, qr/\e\[31m\[has to exist\]\e\[0m/,            'constraint note painted red';
	like $colored, qr/\e\[90m\[URL\]\e\[0m/,                     'type label painted gray';
	like $colored, qr/^   --work-dir <>\s+\e\[31m/m,             'option label stays uncolored';
	like $colored, qr/\e\[33mValid\e\[0m   = \[ \e\[36mdebug\e\[0m, \e\[36minfo\e\[0m, \e\[36mwarn\e\[0m \]/, 'valid subline: yellow key, cyan values';
	like $colored, qr/\e\[33mDefault\e\[0m = \e\[35minfo\e\[0m/, 'default subline: yellow key, magenta value';
	like $colored, qr/^\e\[1;31m# Examples:\e\[0m$/m,            'examples header red';
	like $colored, qr/^\e\[92m## Basic run\e\[0m$/m,             'example text green';

	my ($plainEntry)   = grep { /--owner/ } split /\n/, $rendered;
	my ($coloredEntry) = grep { /--owner/ } @lines;
	(my $stripped = $coloredEntry) =~ s/\e\[[0-9;]*m//g;
	is $stripped, $plainEntry, 'colors never shift the column layout';
};

subtest 'colors reach the right occurrence and survive wrapping' => sub {
	my $duplicated = Getopt::Pad::Spec->new(raw => {
		options => { source => { type => 'url', help => 'Give a [URL] here' } },
	});
	my $out = $duplicated->helperFor($duplicated->root, programName => 'x', width => 100, color => 1)->renderHelp;
	like $out, qr/Give a \[URL\] here \e\[90m\[URL\]\e\[0m/, 'type label painted, not its copy in the help text';

	my $narrow = Getopt::Pad::Spec->new(raw => {
		options => { 'work-dir' => { type => 'dir', mustExist => 1, help => 'Where the clone is placed' } },
	});
	my $buildNarrow = sub($color) {
		return $narrow->helperFor($narrow->root, programName => 'x', width => 42, color => $color)->renderHelp;
	};
	my $wrapped = $buildNarrow->(1);
	like $wrapped, qr/\e\[31m\[has\e\[0m \e\[31mto\e\[0m\n/,   'wrapped constraint note painted before the break';
	like $wrapped, qr/\n\s+\e\[31mexist\]\e\[0m/,              'wrapped constraint note painted after the break';

	(my $stripped = $wrapped) =~ s/\e\[[0-9;]*m//g;
	is $stripped, $buildNarrow->(0), 'colors never shift the wrapped layout';

	my $tooNarrow = $narrow->helperFor($narrow->root, programName => 'x', width => 12, color => 0);
	is warnings { $tooNarrow->renderHelp }, [], 'a terminal narrower than the label column renders without warnings';

	local $ENV{COLUMNS} = 100;
	my $lazy = $narrow->helperFor($narrow->root, programName => 'x', color => 0);
	$ENV{COLUMNS} = 42;
	is $lazy->renderHelp, $buildNarrow->(0), 'the terminal width is read when help is rendered, not when the helper is built';
};

subtest 'declared options can be hidden, and the spec version is rendered' => sub {
	my $spec = Getopt::Pad::Spec->new(raw => {
		options => {
			owner  => { type => 's', help => 'Target owner' },
			secret => { type => 's', hidden => 1, help => 'Not for the help text' },
			nick   => { type => 's', default => undef },
		},
		version => '2.0',
	});
	my $helper = $spec->helperFor($spec->root, programName => 'x', width => 100, color => 0);
	like $helper->renderHelp, qr/--owner/, 'visible option listed';
	unlike $helper->renderHelp, qr/secret/, 'hidden declared option left out';
	unlike $helper->renderHelp, qr/Default/, 'an undefined default renders no Default line';
	is $helper->renderVersion, 'x 2.0', 'spec version string rendered';
};

subtest 'help and version triggers throw their output' => sub {
	my $request = dies {
		Getopt::Pad::Parser->new(spec => $spec, argv => ['--help'])->parse;
	};
	isa_ok $request, ['Getopt::Pad::ExitRequest'], 'help ends the parse with an exit request';
	like $request->output, qr/^# \S+ \[options\]/m, 'carrying the rendered help';
	like $request->output, qr/\n\z/, 'output ends with a newline';

	my $version = dies {
		Getopt::Pad::Parser->new(spec => $spec, argv => ['--version'])->parse;
	};
	isa_ok $version, ['Getopt::Pad::ExitRequest'], 'version ends the parse with an exit request';
	is $version->output, $spec->helperFor($spec->root)->renderVersion . "\n", 'carrying the rendered version line';
};

subtest 'end-to-end help and version' => sub {
	my $runScript = sub {
		my ($code, @argv) = @_;
		my $stderrHandle = gensym;
		my $pid = open3(my $stdinHandle, my $stdoutHandle, $stderrHandle, $^X, "-I$libDir", '-MGetopt::Pad', '-e', $code, '--', @argv);
		close $stdinHandle;
		local $/;
		my $stdout = readline($stdoutHandle) // '';
		my $stderr = readline($stderrHandle) // '';
		waitpid $pid, 0;
		return ($? >> 8, $stdout, $stderr);
	};

	my ($exit, $stdout, $stderr) = $runScript->(
		'GetOptions(options => { owner => { type => q(s), required => 1 } }); print q(unreached);',
		'--help',
	);
	is $exit, 0, 'help exits 0 even with missing required options';
	like $stdout, qr/^# .*\[options\]/, 'usage printed to STDOUT';
	is $stderr, '', 'STDERR clean';

	(my $versionExit, my $versionOut, undef) = $runScript->(
		'our $VERSION = q(1.2.3); GetOptions(options => {});',
		'--version',
	);
	is $versionExit, 0, 'version exits 0';
	like $versionOut, qr/1\.2\.3/, 'script version printed';
};

done_testing;
