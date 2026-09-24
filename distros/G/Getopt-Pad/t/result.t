use v5.26;
use Test2::V0;

use Getopt::Pad::Spec;
use Getopt::Pad::Result::Generator;

my $spec = Getopt::Pad::Spec->new(raw => {
	options => {
		'owner|o'  => { type => 's' },
		'work-dir' => { type => 'dir' },
		'private'  => { type => '!', default => 1 },
	},
	args => [
		{ type => 'url', short => 'source-url', required => 1 },
	],
});

my $class = Getopt::Pad::Result::Generator::generate($spec->root);

subtest 'generated class shape' => sub {
	like $class, qr/^Getopt::Pad::Result::_\d+$/, 'namespaced generated class';
	isa_ok $class->new, ['Getopt::Pad::Result'], 'inherits the result base';

	my $other = Getopt::Pad::Result::Generator::generate($spec->root);
	is $class, $other, 'an identical reader set reuses the cached class';

	my $different = Getopt::Pad::Result::Generator::generate(Getopt::Pad::Spec->new(raw => { options => { other => {} } })->root);
	isnt $class, $different, 'a different reader set gets its own class';
};

subtest 'readers round-trip' => sub {
	my $result = $class->new(
		owner     => 'dave',
		workDir   => '/tmp/x',
		private   => 1,
		sourceUrl => 'https://example.com/repo.git',
	);

	is $result->owner,     'dave',                          'option reader';
	is $result->workDir,   '/tmp/x',                        'camelCase reader';
	is $result->private,   1,                               'bool reader';
	is $result->sourceUrl, 'https://example.com/repo.git',  'arg reader';
	is $result->command,    undef,                          'command defaults to undef';
	is $result->subcommand, undef,                          'subcommand defaults to undef';
};

subtest 'base methods' => sub {
	my $result = $class->new(command => 'document', subcommand => 'nested-result');
	is $result->command,    'document',      'command wired';
	is $result->subcommand, 'nested-result', 'subcommand wired';

	like dies { $class->new->help },    qr/no help renderer attached/, 'help without helper fails loudly';
	like dies { $class->new->version }, qr/no help renderer attached/, 'version without helper fails loudly';
};

subtest 'reserved reader names come from the result class itself' => sub {
	ok(Getopt::Pad::Result->reservesReader($_), "'$_' is reserved") foreach qw(help version command subcommand new can isa DOES META BUILDARGS helper DESTROY AUTOLOAD);
	ok !Getopt::Pad::Result->reservesReader($_), "'$_' is free" foreach qw(owner workDir sourceUrl);
};

done_testing;
