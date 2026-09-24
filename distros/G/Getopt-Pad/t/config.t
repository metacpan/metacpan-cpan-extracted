use v5.26;
use experimental 'signatures';
use Test2::V0;

use Encode ();
use Feature::Compat::Try;
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3 qw(open3);
use Getopt::Pad;
use Getopt::Pad::Spec;
use Getopt::Pad::Parser;

# YAML::XS is only recommended by the distribution, and most files written
# below are YAML.
try { require YAML::XS }
catch ($error) { skip_all('YAML::XS is not installed') }

my $dir = tempdir(CLEANUP => 1);

sub writeFile($path, $content) {
	open my $handle, '>', $path or die $!;
	print {$handle} $content;
	close $handle;
	return $path;
}

my $systemConfig = writeFile("$dir/system.yaml", "Options:\n  owner: system\n  log-level: warn\n");
my $userConfig   = writeFile("$dir/user.yaml",   "Options:\n  owner: dave\n");

my %options = (
	'owner'     => { type => 's' },
	'log-level' => { type => 's', default => 'info', valid => [qw(debug info warn)] },
	'tag'       => { type => 's', multiple => 1 },
);

sub parseWith($argv, %raw) {
	my $spec = Getopt::Pad::Spec->new(raw => \%raw);
	return Getopt::Pad::Parser->new(spec => $spec, argv => $argv)->parse;
}

subtest 'precedence CLI > config > default' => sub {
	my $opt = GetOptions(
		argv    => [],
		options => {%options},
		config  => { format => 'yaml', paths => [$systemConfig, $userConfig] },
	);
	is $opt->owner,    'dave', 'later config path overrides earlier';
	is $opt->logLevel, 'warn', 'config overrides the spec default';

	my $cli = GetOptions(
		argv    => ['--owner', 'cli'],
		options => {%options},
		config  => { format => 'yaml', paths => [$systemConfig, $userConfig] },
	);
	is $cli->owner,    'cli',  'command line beats config';
	is $cli->logLevel, 'warn', 'untouched values still come from config';
};

subtest 'autoload behavior' => sub {
	my $opt = GetOptions(
		argv    => [],
		options => {%options},
		config  => { format => 'yaml', paths => ["$dir/missing.yaml", $userConfig] },
	);
	is $opt->owner, 'dave', 'missing autoload paths are skipped silently';

	my $off = GetOptions(
		argv    => [],
		options => {%options},
		config  => { format => 'yaml', paths => [$userConfig], autoload => 0 },
	);
	is $off->owner, undef, 'autoload 0 loads nothing without --config';
};

subtest 'explicit --config' => sub {
	my $opt = GetOptions(
		argv    => ['--config', $systemConfig],
		options => {%options},
		config  => { format => 'yaml', paths => [$userConfig], autoload => 0 },
	);
	is $opt->owner, 'system', 'explicit path loaded';

	my $replaced = GetOptions(
		argv    => ['--config', $systemConfig],
		options => {%options},
		config  => { format => 'yaml', paths => [$userConfig] },
	);
	is $replaced->owner, 'system', 'explicit path replaces the autoload chain';

	my $viaDefault = GetOptions(
		argv    => ['--config'],
		options => {%options},
		config  => { format => 'yaml', defaultPath => $userConfig, autoload => 0 },
	);
	is $viaDefault->owner, 'dave', 'bare --config falls back to defaultPath';

	like dies { parseWith(['--config'], options => {%options}, config => { format => 'yaml' }) },
		qr/--config without a path, and the spec sets no defaultPath/, 'bare --config without defaultPath fails';

	like dies { parseWith(['--config', "$dir/nope.yaml"], options => {%options}, config => { format => 'yaml' }) },
		qr/config file '.*nope\.yaml' does not exist/, 'explicit missing file fails';
};

subtest 'config values run the normal pipeline' => sub {
	my $badValue = writeFile("$dir/bad-value.yaml", "Options:\n  log-level: extreme\n");
	like dies { parseWith([], options => {%options}, config => { format => 'yaml', paths => [$badValue] }) },
		qr/config value for 'log-level': 'extreme' is not one of: debug, info, warn/, 'valid list applies to config values';

	my $unknown = writeFile("$dir/unknown.yaml", "Options:\n  frobnicate: 1\n");
	like dies { parseWith([], options => {%options}, config => { format => 'yaml', paths => [$unknown] }) },
		qr/unknown option 'frobnicate' in group 'Options'/, 'unknown config key fails';

	my $autoKey = writeFile("$dir/auto.yaml", "Options:\n  help: 1\n");
	like dies { parseWith([], options => {%options}, config => { format => 'yaml', paths => [$autoKey] }) },
		qr/unknown option 'help' in group 'Options'/, 'auto options are not settable from config';

	my $scalarTag = writeFile("$dir/scalar-tag.yaml", "Options:\n  tag: solo\n");
	my $wrapped = parseWith([], options => {%options}, config => { format => 'yaml', paths => [$scalarTag] });
	is $wrapped->tag, ['solo'], 'scalar for a multiple option is wrapped';

	my $listTag = writeFile("$dir/list-tag.yaml", "Options:\n  tag:\n    - a\n    - b\n");
	my $list = parseWith([], options => {%options}, config => { format => 'yaml', paths => [$listTag] });
	is $list->tag, ['a', 'b'], 'list for a multiple option passes through';

	my $notMapping = writeFile("$dir/list.yaml", "- a\n- b\n");
	like dies { parseWith([], options => {%options}, config => { format => 'yaml', paths => [$notMapping] }) },
		qr/must contain a mapping of group names/, 'non-mapping config rejected';

	my $wrongGroup = writeFile("$dir/wrong-group.yaml", "General:\n  owner: x\n");
	like dies { parseWith([], options => {%options}, config => { format => 'yaml', paths => [$wrongGroup] }) },
		qr/option 'owner' belongs to group 'Options', not 'General'/, 'option under the wrong group rejected';

	my $flatGroup = writeFile("$dir/flat-group.yaml", "Options: 5\n");
	like dies { parseWith([], options => {%options}, config => { format => 'yaml', paths => [$flatGroup] }) },
		qr/group 'Options' must contain a mapping of option names/, 'non-mapping group rejected';
};

subtest '--config appears in the help output' => sub {
	my $spec = Getopt::Pad::Spec->new(raw => {
		options => {%options},
		config  => { format => 'yaml', defaultPath => '~/.demo.yaml' },
	});
	my $rendered = $spec->helperFor($spec->root, programName => 'demo', width => 120, color => 0)->renderHelp;

	like $rendered, qr/^   --config <>\s+Load options from this yaml config file \(bare --config loads ~\/\.demo\.yaml\)$/m,
		'--config documented with its format and defaultPath';
	like $rendered, qr/^## Config$/m, 'auto config options get their own Config group';
	like $rendered, qr/## Config\n   --config <>.*\n   --create-default-config <>/, 'both config options listed under it';
	unlike $rendered, qr/--help/,    'auto help still hidden';
	unlike $rendered, qr/--version/, 'auto version still hidden';

	my $noDefault = Getopt::Pad::Spec->new(raw => { options => {%options}, config => { format => 'json' } });
	like +$noDefault->helperFor($noDefault->root, programName => 'demo', width => 120, color => 0)->renderHelp,
		qr/^   --config <>\s+Load options from this json config file$/m, 'format named, no defaultPath clause';

	my $opt = GetOptions(
		argv    => [],
		options => {%options},
		config  => { format => 'yaml', paths => [$userConfig] },
	);
	ok !$opt->can('config'), 'the result object still has no config reader';
};

subtest '--create-default-config writes the defaults and exits' => sub {
	my $targetPath = "$dir/fresh-default.yaml";

	my $request = dies {
		parseWith(['--create-default-config', $targetPath],
			options => {%options},
			config  => { format => 'yaml' },
		);
	};
	isa_ok $request, ['Getopt::Pad::ExitRequest'], 'exit request thrown';
	is $request->output, "Wrote default config to $targetPath\n", 'output names the file';
	ok -f $targetPath, 'file written';

	require YAML::XS;
	is YAML::XS::LoadFile($targetPath), { Options => { 'log-level' => 'info' } }, 'defaults written nested under their group';

	my $roundTrip = GetOptions(
		argv    => ['--config', $targetPath],
		options => {%options},
		config  => { format => 'yaml' },
	);
	is $roundTrip->logLevel, 'info', 'written file loads back through --config';

	like dies {
		parseWith(['--create-default-config', $targetPath],
			options => {%options},
			config  => { format => 'yaml' },
		);
	}, qr/config file '.*fresh-default\.yaml' already exists/, 'refuses to overwrite an existing file';

	like dies {
		parseWith(['--create-default-config'],
			options => {%options},
			config  => { format => 'yaml' },
		);
	}, qr/Option create-default-config requires an argument/, 'a path is mandatory';

	my $spec = Getopt::Pad::Spec->new(raw => { options => {%options}, config => { format => 'yaml' } });
	my $rendered = $spec->helperFor($spec->root, programName => 'demo', width => 160, color => 0)->renderHelp;
	like $rendered,
		qr/^   --create-default-config <>\s+Write a config file prefilled with the default values to this path and exit$/m,
		'--create-default-config documented in the help output';
};

subtest 'json format and format errors' => sub {
	my $jsonConfig = writeFile("$dir/config.json", '{"Options": {"owner": "json-dave"}}');
	my $opt = GetOptions(
		argv    => [],
		options => {%options},
		config  => { format => 'json', paths => [$jsonConfig] },
	);
	is $opt->owner, 'json-dave', 'json config loaded';

	my $brokenJson = writeFile("$dir/broken.json", '{"owner": ');
	my $parseError = dies { parseWith([], options => {%options}, config => { format => 'json', paths => [$brokenJson] }) };
	like $parseError, qr/config file '.*broken\.json':/, 'parse failure names the file';
	unlike $parseError, qr/ at \S+ line \d+/, 'the parser\'s Perl source location is stripped';

	like dies { Getopt::Pad::Spec->new(raw => { options => {}, config => { format => 'toml' } }) },
		qr/unknown config format 'toml' \(known: json, yaml, yml\)/, 'unknown format is a spec error';

	like dies { Getopt::Pad::Spec->new(raw => { options => {}, config => {} }) },
		qr/config: missing 'format'/, 'format is mandatory';
};

subtest 'config I/O owns the file encoding' => sub {
	my $city   = "Z\x{fc}rich";
	my %umlaut = (city => { type => 's', default => $city });

	my $yamlPath = "$dir/umlaut.yaml";
	isa_ok dies { parseWith(['--create-default-config', $yamlPath], options => {%umlaut}, config => { format => 'yaml' }) },
		['Getopt::Pad::ExitRequest'], 'yaml default written';
	is +GetOptions(argv => ['--config', $yamlPath], options => {%umlaut}, config => { format => 'yaml' })->city,
		$city, 'a non-ASCII yaml default survives the --create-default-config round trip';

	my $jsonPath = writeFile("$dir/umlaut.json", Encode::encode('UTF-8', qq({"Options": {"city": "$city"}})));
	is +GetOptions(argv => [], options => {%umlaut}, config => { format => 'json', paths => [$jsonPath] })->city,
		$city, 'json files are decoded from UTF-8';

	# A format that knows nothing about files or encodings: text in, text out.
	package My::Test::Format::Line {
		use Object::Pad;
		use Getopt::Pad::Config::Format;

		class My::Test::Format::Line :isa(Getopt::Pad::Config::Format) {
			use constant NAMES => ['line'];
			method parse($text) { return { Options => { city => $text =~ s/\n\z//r } } }
			method dump($data)  { return "$data->{Options}{city}\n" }
		}
	}
	Getopt::Pad::Config::Format::registerFormat('My::Test::Format::Line');

	my $linePath = "$dir/umlaut.line";
	isa_ok dies { parseWith(['--create-default-config', $linePath], options => {%umlaut}, config => { format => 'line' }) },
		['Getopt::Pad::ExitRequest'], 'line default written';
	open my $raw, '<:raw', $linePath or die $!;
	is scalar readline($raw), Encode::encode('UTF-8', "$city\n"), 'the written file holds UTF-8 octets';
	is +GetOptions(argv => ['--config', $linePath], options => {%umlaut}, config => { format => 'line' })->city,
		$city, 'the format receives decoded text';
};

subtest '--create-default-config through other formats and at odd targets' => sub {
	my $jsonPath = "$dir/defaults.json";
	isa_ok dies { parseWith(['--create-default-config', $jsonPath], options => {%options}, config => { format => 'json' }) },
		['Getopt::Pad::ExitRequest'], 'json default written';
	is +GetOptions(argv => ['--config', $jsonPath], options => {%options}, config => { format => 'json' })->logLevel,
		'info', 'json default file loads back';

	package My::Test::Format::ReadOnly {
		use Object::Pad;
		use Getopt::Pad::Config::Format;

		class My::Test::Format::ReadOnly :isa(Getopt::Pad::Config::Format) {
			use constant NAMES => ['ro'];
			method parse($text) { return {} }
		}
	}
	Getopt::Pad::Config::Format::registerFormat('My::Test::Format::ReadOnly');
	like dies { parseWith(['--create-default-config', "$dir/nope.ro"], options => {%options}, config => { format => 'ro' }) },
		qr/config format 'ro' cannot write config files/, 'a format without dump refuses';
	ok !-e "$dir/nope.ro", 'and creates no file';

	my $linkPath = "$dir/dangling.json";
	symlink("$dir/elsewhere.json", $linkPath) or die $!;
	like dies { parseWith(['--create-default-config', $linkPath], options => {%options}, config => { format => 'json' }) },
		qr/config file '.*dangling\.json' already exists/, 'a dangling symlink is refused';
	ok !-e "$dir/elsewhere.json", 'the link target is not created';
};

subtest 'config files set top-level options only' => sub {
	my $nested = writeFile("$dir/nested.json", '{"Options": {"verbose": 1}}');
	like dies {
		parseWith(['doc'], options => {%options}, commands => { doc => { options => { verbose => {} } } },
			config => { format => 'json', paths => [$nested] });
	}, qr/unknown option 'verbose' in group 'Options' \(config files set top-level options only\)/, 'a subcommand option in a config file gets the hint';
};

subtest 'yaml loading never blesses' => sub {
	require Getopt::Pad::Config::Format::Yaml;
	my $data = Getopt::Pad::Config::Format::Yaml->new->parse("--- !!perl/hash:My::Evil\nOptions:\n  owner: x\n");
	is ref $data, 'HASH', 'a perl tag yields a plain hash';
	is $data->{Options}{owner}, 'x', 'with its data intact';
};

subtest 'a missing YAML::XS is a spec error' => sub {
	my $code = 'BEGIN { unshift @INC, sub { die "hidden\n" if $_[1] eq "YAML/XS.pm"; return } }'
		. ' use Getopt::Pad; GetOptions(argv => [], options => {}, config => { format => q(yaml) }); print q(unreached);';
	my $pid = open3(my $stdinHandle, my $outputHandle, undef, $^X, '-I' . File::Spec->rel2abs('lib'), '-e', $code);
	close $stdinHandle;
	local $/;
	my $output = readline($outputHandle) // '';
	waitpid $pid, 0;

	isnt $? >> 8, 0, 'the spec fails to build';
	like $output, qr/Getopt::Pad spec: config format 'yaml' requires the YAML::XS module at -e line 1\./, 'named as a spec error at the call';
	unlike $output, qr/unreached/, 'before any config file is touched';
};

done_testing;
