use v5.26;
use experimental 'signatures';
use Test2::V0;

use Getopt::Pad::Spec;

sub buildSpec(%raw) {
	return Getopt::Pad::Spec->new(raw => \%raw);
}

subtest 'a valid spec builds' => sub {
	my $spec = buildSpec(
		options => {
			'owner|o'   => { type => 's', required => 1, group => 'Target', help => 'Target owner' },
			'work-dir'  => { type => 'dir', mustExist => 1, group => 'General' },
			'private'   => { type => '!', default => 1 },
			'dry-run'   => {},
			'log-level' => { type => 'string', default => 'info', valid => [qw(debug info warn)] },
		},
		args => [
			{ type => 'url', short => 'source-url', required => 1 },
		],
		description => 'Test tool',
		examples    => [{ text => 'Example', args => '--owner dave' }],
	);

	my $root  = $spec->root;
	my $owner = $root->optionByName('owner');
	is $owner->reader, 'owner', 'plain reader name';
	is [$owner->aliases], ['o'], 'alias split from key';
	is $owner->glSpec, 'owner|o=s', 'Getopt::Long spec';
	ok $owner->required, 'required flag';

	is $root->optionByName('work-dir')->reader, 'workDir', 'kebab-case becomes camelCase';
	ok $root->optionByName('work-dir')->type->mustExist, 'type key passed through';

	is $root->optionByName('dry-run')->typeName, 'flag', 'missing type defaults to flag';
	ok $root->optionByName('private')->negatable, 'bang type is negatable';
	ok $root->optionByName('private')->hasDefault, 'default recorded';

	my ($arg) = $root->args;
	is $arg->reader, 'sourceUrl', 'arg reader from short name';
	is $arg->typeName, 'url', 'arg type';

	is $root->description, 'Test tool', 'description';
	is [$root->examples], [{ text => 'Example', args => '--owner dave' }], 'examples';
};

subtest 'spec errors fail loudly' => sub {
	like dies { buildSpec(options => { owner => { type => 's', frobnicate => 1 } }) },
		qr/option 'owner': unknown key\(s\): frobnicate/, 'unknown option key';

	like dies { buildSpec(options => { owner => { type => 'nope' } }) },
		qr/unknown option type 'nope'/, 'unknown type';

	like dies { buildSpec(options => { owner => { type => 's', required => 1, default => 'x' } }) },
		qr/required and default are mutually exclusive/, 'required plus default';

	like dies { buildSpec(options => { verbose => { type => '!', multiple => 1 } }) },
		qr/multiple requires a value-taking type/, 'multiple on a bool';

	like dies { buildSpec(options => { help => { type => 's' } }) },
		qr/reader 'help' collides/, 'reserved reader';

	like dies { buildSpec(options => { helper => { type => 's' } }) },
		qr/reader 'helper' collides/, 'reader clashing with result internals';

	like dies { buildSpec(options => { AUTOLOAD => { type => 's' } }) },
		qr/reader 'AUTOLOAD' collides/, 'reader clashing with a Perl hook';

	like dies { buildSpec(options => { 'verbose|v' => {}, 'version-check|v' => {} }) },
		qr/name 'v' is already used by an alias of option/, 'duplicate alias across options';

	like dies { buildSpec(options => { 'owner|' => { type => 's' } }) },
		qr/option 'owner\|': invalid name ''/, 'trailing pipe rejected';

	like dies { buildSpec(options => { workers => { type => 'i', min => 'abc' } }) },
		qr/option 'workers': min must be a number, not 'abc'/, 'non-numeric bound';

	like dies { buildSpec(options => {}, examples => 'nope') },
		qr/'examples' must be an array reference/, 'examples not a list';

	like dies { buildSpec(options => {}, examples => [{ text => 'Only text' }]) },
		qr/each example must be a hash with 'text' and 'args'/, 'example missing args';

	like dies { buildSpec(options => { retries => { type => 'i', default => 'nope' } }) },
		qr/option 'retries': default value: 'nope' is not an integer/, 'default validated when the spec is built';

	like dies { buildSpec(options => { 'work-dir' => { type => 's' }, 'workDir' => { type => 's' } }) },
		qr/both map to reader 'workDir'/, 'reader collision';

	like dies { buildSpec(options => { config => { type => 's' } }, config => { format => 'json' }) },
		qr/spec: option 'config' collides with the automatic --config option/, 'collision with an auto option';

	like dies { buildSpec(options => { owner => { type => 's', default => ['a'] } }) },
		qr/option 'owner': default value: expected a single value, not a list or mapping/, 'list default for a single-value option';

	like dies { buildSpec(options => { owner => { type => 's', valid => 'nope' } }) },
		qr/valid must be an array or code reference/, 'invalid valid';

	like dies { buildSpec(typo => 1) },
		qr/spec: unknown key\(s\): typo/, 'unknown top-level key';
};

subtest 'arg constraints' => sub {
	like dies { buildSpec(args => [{ type => 's' }]) },
		qr/missing or invalid 'short' name/, 'short is mandatory';

	like dies { buildSpec(args => [{ short => 'a', type => 'flag' }]) },
		qr/cannot be used for a positional arg/, 'valueless arg type';

	like dies { buildSpec(args => [{ short => 'a', multiple => 1 }, { short => 'b' }]) },
		qr/multiple is only allowed on the last arg/, 'slurpy must be last';

	like dies { buildSpec(args => [{ short => 'a' }, { short => 'b', required => 1 }]) },
		qr/required arg cannot follow an optional one/, 'required after optional';
};

subtest 'command constraints' => sub {
	my $spec = buildSpec(
		options  => { verbose => { type => '!' } },
		commands => {
			document => {
				options  => { path => { type => 'file' } },
				commands => {
					create => { args => [{ short => 'title', required => 1 }] },
				},
			},
		},
	);
	my $document = $spec->root->command('document');
	is [$spec->root->commandNames], ['document'], 'command listed';
	is $document->path, 'document', 'level path';
	is $document->command('create')->path, 'document create', 'nested level path';
	ok $spec->root->commandRequired, 'commands mandatory by default';

	my $optional = buildSpec(commands => { doc => {} }, commandRequired => 0);
	ok !$optional->root->commandRequired, 'commandRequired 0 accepted';

	like dies { buildSpec(args => [{ short => 'a' }], commands => { doc => {} }) },
		qr/args and commands are mutually exclusive/, 'args and commands clash';

	like dies { buildSpec(commandRequired => 0) },
		qr/commandRequired without commands/, 'commandRequired needs commands';

	like dies { buildSpec(commands => { doc => { options => { x => { type => 'bad' } } } }) },
		qr/unknown option type 'bad'/, 'nested errors surface';
};

done_testing;
