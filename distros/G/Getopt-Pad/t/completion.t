use v5.26;
use experimental 'signatures';
use Test2::V0;

use File::Spec;
use IPC::Open3 qw(open3);
use Symbol     qw(gensym);

use Getopt::Pad::Spec;
use Getopt::Pad::Parser;
use Getopt::Pad::Completion;

my $libDir = File::Spec->rel2abs('lib');

my %raw = (
	options  => {
		'verbose|v' => { type => '!', help => 'Say more' },
		'log-file'  => { type => 'file' },
		'secret'    => { type => 's', hidden => 1 },
	},
	commands => {
		delete => {
			options => {
				'user-id|u' => { type => 'i', valid => sub { [10, 11, 25] } },
				'force|f'   => {},
				'mode'      => { type => 's', valid => [qw(soft hard)] },
				'define|D'  => { type => 's', hash => 1, valid => [qw(bsd linux)] },
				'tag'       => { type => 's', multiple => 1, csv => 1, valid => [qw(alpha beta)] },
				'server'    => { type => 's', objectlist => 1, valid => [qw(alpha beta)] },
			},
		},
		list => {
			options => { 'long|l' => {} },
			args    => [{ short => 'dir', type => 'dir' }, { short => 'names', multiple => 1 }],
		},
	},
);

my $spec       = Getopt::Pad::Spec->new(raw => \%raw);
my $completion = Getopt::Pad::Completion->new(spec => $spec, programName => 'tool');

sub candidatesFor(@words) {
	return [$completion->candidates(\@words, $#words)];
}

subtest 'commands and option spellings' => sub {
	is candidatesFor(''),    ['none', 'delete', 'list'], 'bare word at the root lists the commands';
	is candidatesFor('d'),   ['none', 'delete'],         'command prefix filters';
	is candidatesFor('-'),   ['none', '--create-completions', '--log-file', '--no-verbose', '--verbose', '-v'], 'a dash lists the visible spellings, negated forms included';
	is candidatesFor('--l'), ['none', '--log-file'],     'option prefix filters';
	is candidatesFor('delete', ''),   ['none', '--define', '--force', '--mode', '--server', '--tag', '--user-id', '-D', '-f', '-u'], 'a Level without commands or args offers its options';
	is candidatesFor('delete', '--'), ['none', '--define', '--force', '--mode', '--server', '--tag', '--user-id'],             'two dashes narrow to long spellings';
	is candidatesFor('bogus', ''),    ['none'], 'an unknown command completes nothing';
	is candidatesFor('--', '-'),      ['none'], 'no options after --';
};

subtest 'option values' => sub {
	is candidatesFor('delete', '--user-id', ''),  ['none', '10', '11', '25'], 'dynamic valid list';
	is candidatesFor('delete', '--user-id', '1'), ['none', '10', '11'],       'dynamic valid list filtered by prefix';
	is candidatesFor('delete', '--user-id=1'),    ['none', '--user-id=10', '--user-id=11'], 'inline value keeps the option spelling';
	is candidatesFor('delete', '-u', ''),         ['none', '10', '11', '25'], 'single-letter alias';
	is candidatesFor('delete', '-fu', ''),        ['none', '10', '11', '25'], 'value-taking option last in a bundle';
	is candidatesFor('delete', '-uf', ''),        ['none', '--define', '--force', '--mode', '--server', '--tag', '--user-id', '-D', '-f', '-u'], 'a bundle carrying its value inline swallows nothing';
	is candidatesFor('delete', '--mode', 's'),    ['none', 'soft'], 'static valid list';
	is candidatesFor('delete', '--force', ''),    ['none', '--define', '--force', '--mode', '--server', '--tag', '--user-id', '-D', '-f', '-u'], 'a flag takes no value';
	is candidatesFor('delete', '--server', '0.host=b'), ['none', '0.host=beta'], 'an objectlist option completes the value behind INDEX.FIELD=';
	is candidatesFor('delete', '--tag', 'b'),          ['none', 'beta'], 'a csv option completes its first item';
	is candidatesFor('delete', '--tag', 'alpha,b'),    ['none', 'alpha,beta'], 'a csv option completes behind the last comma';
	is candidatesFor('delete', '--define', 'os'),      ['none'], 'a hash option offers nothing before the =';
	is candidatesFor('delete', '--define', 'os=l'),    ['none', 'os=linux'], 'a hash option completes the value behind its key';
	is candidatesFor('delete', '--define=os='),        ['none', '--define=os=bsd', '--define=os=linux'], 'inline hash value keeps spelling and key';
	is candidatesFor('--log-file', ''),           ['files'], 'a file option asks the shell for files';
	is candidatesFor('--log-file', 'x', ''),      ['none', 'delete', 'list'], 'the value is consumed';
	is candidatesFor('--create-completions', ''), ['none', 'bash', 'zsh'], 'the shells are completed too';
};

subtest 'positional args' => sub {
	is candidatesFor('list', ''),           ['dirs'], 'a dir arg asks the shell for directories';
	is candidatesFor('list', 'x', ''),      ['none'], 'a string arg offers nothing';
	is candidatesFor('list', 'x', 'y', ''), ['none'], 'a slurpy arg keeps offering nothing';
	is candidatesFor('list', 'x', '-'),     ['none', '--long', '-l'], 'options stay available between positionals, hidden ones left out';
};

subtest 'rendering and errors' => sub {
	is $completion->renderCandidates(['delete', '--mode', ''], 2), "none\nhard\nsoft\n", 'one line each, directive first';
	like dies { $completion->candidates([], 'x') }, qr/completion index must be a non-negative integer/, 'index is checked';
	like dies { $completion->renderScript('fish') }, qr/no completion script for shell 'fish'/, 'unknown shell';
};

subtest 'scripts' => sub {
	my $bash = $completion->renderScript('bash');
	like $bash, qr/^complete -F _tool_completion tool$/m, 'bash registers the function';
	like $bash, qr/GETOPT_PAD_COMPLETE=bash GETOPT_PAD_COMPLETE_INDEX=/, 'bash calls back through the environment';

	my $zsh = $completion->renderScript('zsh');
	like $zsh, qr/^#compdef tool$/m, 'zsh compdef header';
	like $zsh, qr/^\tcompdef _tool_completion tool$/m, 'zsh registers the function when sourced';

	my $spaced = Getopt::Pad::Completion->new(spec => $spec, programName => 'my-tool.pl');
	like $spaced->renderScript('bash'), qr/^complete -F _my_tool_pl_completion my-tool\.pl$/m, 'function names are identifiers';

	my $request = dies { Getopt::Pad::Parser->new(spec => $spec, argv => ['--create-completions', 'zsh'])->parse };
	isa_ok $request, ['Getopt::Pad::ExitRequest'], '--create-completions throws its script';
	like $request->output, qr/^#compdef /, 'the requested shell';

	like dies { Getopt::Pad::Parser->new(spec => $spec, argv => ['--create-completions', 'fish'])->parse },
		qr/option '--create-completions': 'fish' is not one of: bash, zsh/, 'unsupported shells are rejected';

	my $help = $spec->helperFor($spec->root, programName => 'tool', width => 100, color => 0)->renderHelp;
	like $help, qr/^## Completion\n   --create-completions <>\s+Print a completion script/m, 'listed under its own group';
};

subtest 'GetOptions answers the shell instead of parsing' => sub {
	local $ENV{GETOPT_PAD_COMPLETE}       = 'bash';
	local $ENV{GETOPT_PAD_COMPLETE_INDEX} = 1;
	my $stderrHandle = gensym;
	my $pid = open3(my $stdinHandle, my $stdoutHandle, $stderrHandle, $^X, "-I$libDir", '-MGetopt::Pad', '-e',
		'GetOptions(options => { owner => { type => q(s), required => 1, valid => sub { [qw(dave eve)] } } }); print qq(parsed\n);', '--', '--owner', 'd');
	close $stdinHandle;
	local $/;
	my $stdout = (readline($stdoutHandle) // '') =~ s/\r\n/\n/gr;    # text-mode STDOUT on Windows
	waitpid $pid, 0;
	is $? >> 8, 0, 'exit status 0';
	is $stdout, "none\ndave\n", 'candidates printed, the required option never checked';
};

done_testing;
