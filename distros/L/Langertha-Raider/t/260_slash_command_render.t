#!/usr/bin/env perl
# ABSTRACT: The renderer of /name and the skill tool: arguments, shell injection through the permission policy, @file attachments (ADR 0030 §2)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use Time::HiRes ();
use Langertha::Raider::FileTools::ReadState;
use Langertha::Raider::Permissions;
use Langertha::Raider::SlashCommand;

my @keep;
sub tempdir { push @keep, Path::Tiny->tempdir; return $keep[-1]->realpath }

my $ROOT = tempdir();
my $HOME = tempdir();

sub policy {
  my ( %o ) = @_;
  return Langertha::Raider::Permissions->new(
    root  => "$ROOT",
    home  => "$HOME",
    mode  => $o{mode} // 'default',
    rules => {
      map { my $k = $_; $k => [ map { { rule => $_, source => 'test' } } @{ $o{$k} // [] } ] } qw( allow ask deny )
    },
    ( $o{dirs} ? ( additional_directories => [ map { { path => $_, source => 'test' } } @{ $o{dirs} } ] ) : () ),
  );
}

# A renderer whose commands do not run: the runner records them and answers
# from %$answers (default: exit 0, output "OUT:<command>").
sub renderer {
  my ( %o ) = @_;
  my $ran = $o{ran} // [];
  my $answers = delete $o{answers} // {};
  delete $o{ran};
  return Langertha::Raider::SlashCommand->new(
    root   => "$ROOT",
    runner => sub {
      my ( $command, $root, $timeout ) = @_;
      push @$ran, $command;
      return $answers->{$command} // { exit_code => 0, output => 'OUT:'.$command };
    },
    %o,
  );
}

my $skill   = { name => 'pdf', dir => '/skills/pdf', kind => 'skill', frontmatter => {} };
my $command = { name => 'review', dir => '/cmds', kind => 'command', frontmatter => {} };

sub text_of {
  my ( $r, $entry, $body, $args, %o ) = @_;
  my $res = $r->render( entry => $entry, body => $body, arguments => $args, %o );
  return $res->{error} // $res->{text};
}

#### Arguments

subtest 'arguments are split shell-style' => sub {
  my $r = renderer();
  is [ $r->split_arguments(q{a "b c" d\ e 'f g'}) ], [ 'a', 'b c', 'd e', 'f g' ], 'quotes group, backslash escapes';
  is [ $r->split_arguments(q{it's here}) ], [ q{it's}, 'here' ], 'unbalanced quotes: split at whitespace';
  is [ $r->split_arguments('   ') ], [], 'nothing';
  is [ $r->split_arguments(undef) ], [], 'undef';
};

subtest 'placeholders' => sub {
  my $r = renderer( session_id => 'sess-1' );
  is text_of( $r, $command, 'All: $ARGUMENTS', 'one "two three"' ), 'All: one "two three"', '$ARGUMENTS is the whole string';
  is text_of( $r, $command, 'First $0, second $ARGUMENTS[1], third $2', 'a "b c"' ),
    'First a, second b c, third $2', '0-based; a missing index stays as typed';
  is text_of( $r, $command, 'x $ARGUMENTS y' ), 'x  y', 'no arguments: $ARGUMENTS is empty';
  is text_of( $r, $command, 'x $0 y' ), 'x $0 y', 'no arguments: $0 stays as typed';
  is text_of( $r, $command, 'cost \$5 and \$ARGUMENTS', 'z' ), 'cost $5 and $ARGUMENTS'."\n\nARGUMENTS: z",
    '\$ is a literal $ and no placeholder';
  is text_of( $r, $command, '$ARGUMENTSX $ARGUMENTS', 'v' ), '$ARGUMENTSX v', 'only the whole word';
  is text_of( $r, { %$command, dir => '/d', plugin_root => '/plug' },
    '${CLAUDE_SKILL_DIR} ${CLAUDE_PROJECT_DIR} ${CLAUDE_SESSION_ID} ${CLAUDE_PLUGIN_ROOT}' ),
    "/d $ROOT sess-1 /plug", 'the ${CLAUDE_*} variables';
  is text_of( renderer(), $command, '[${CLAUDE_SESSION_ID}] ${CLAUDE_PLUGIN_ROOT}' ), '[] ${CLAUDE_PLUGIN_ROOT}',
    'no session: empty; not a plugin entry: stays as typed';
};

subtest 'named arguments' => sub {
  my $r = renderer();
  my $list   = { %$command, frontmatter => { arguments => [ 'issue', 'branch' ] } };
  my $string = { %$command, frontmatter => { arguments => 'issue branch' } };
  is text_of( $r, $list, 'Fix $issue on $branch.', '42 main' ), 'Fix 42 on main.', 'a list';
  is text_of( $r, $string, 'Fix $issue on $branch.', '42' ), 'Fix 42 on .', 'a string; missing is empty';
  is text_of( $r, $string, '$issues $issue', '7' ), '$issues 7', 'whole names only';
};

subtest 'inserted values are not expanded again' => sub {
  my $r = renderer();
  is text_of( $r, $command, '<$ARGUMENTS> <$0>', '$1 ${CLAUDE_PROJECT_DIR}' ),
    '<$1 ${CLAUDE_PROJECT_DIR}> <$1>', 'one pass';
};

subtest 'ARGUMENTS: is appended when no placeholder takes them' => sub {
  my $r = renderer();
  is text_of( $r, $command, "Do it.\n\n", 'now please' ), "Do it.\n\nARGUMENTS: now please", 'appended after a blank line';
  is text_of( $r, $command, 'Do $5.', 'a' ), 'Do $5.', 'a placeholder without its argument still takes them';
  is text_of( $r, $command, 'Do it.' ), 'Do it.', 'nothing without arguments';
};

subtest 'a skill keeps the base directory line, a command has none' => sub {
  my $r = renderer();
  # The shape of Langertha::Raider::Context::Skills->tool_text.
  is text_of( $r, $skill, "Use \$ARGUMENTS.\n", 'report.pdf' ), "Base directory for this skill: /skills/pdf\n\nUse report.pdf.\n",
    'as tool_text, with $ARGUMENTS';
  is text_of( $r, $skill, "Body\n", 'x' ), "Base directory for this skill: /skills/pdf\n\nBody\n\nARGUMENTS: x",
    'as tool_text, appended';
  is text_of( $r, { %$skill, kind => undef }, 'B' ), "Base directory for this skill: /skills/pdf\n\nB", 'no kind is a skill';
  is text_of( $r, $command, 'B' ), 'B', 'a command';
};

#### allowed-tools

subtest 'allowed-tools as rule texts' => sub {
  my $r = renderer();
  is [ $r->allowed_tool_rules('Bash(git add:*), Bash(git status:*) Read') ],
    [ 'Bash(git add:*)', 'Bash(git status:*)', 'Read' ], 'a string: commas and spaces outside parentheses';
  is [ $r->allowed_tool_rules({ frontmatter => { 'allowed-tools' => [ 'Bash(npm run test:*)', 'Grep, Glob', 'NoSuchTool', 'mcp__github' ] } }) ],
    [ 'Bash(npm run test:*)', 'Grep', 'Glob', 'mcp__github' ], 'a YAML list from an entry; an unknown tool is left out';
  is [ $r->allowed_tool_rules({ frontmatter => {} }) ], [], 'none';
  is [ $r->allowed_tool_rules({ frontmatter => { 'allowed-tools' => { a => 1 } } }) ], [], 'not a list or string';
};

#### Shell injection

subtest 'commands run only on allow' => sub {
  my @ran;
  my $r = renderer( ran => \@ran, permissions => policy( allow => [ 'Bash(git status:*)' ] ) );
  my $res = $r->render( entry => $command, body => "Status:\n!`git status --short`\nend" );
  is $res->{text}, "Status:\nOUT:git status --short\nend", 'output replaces the placeholder';
  is \@ran, [ 'git status --short' ], 'ran once';
  is $res->{commands}, [ { command => 'git status --short', verdict => 'allow', exit_code => 0 } ], 'traced';

  @ran = ();
  $res = $r->render( entry => $command, body => 'A !`git status` B !`rm -rf x`' );
  like $res->{error}, qr/\AShell command permission check failed for pattern "!`rm -rf x`" in \/review: default mode asks/,
    'ask in default mode aborts with the reason';
  ok !exists $res->{text}, 'no text';
  is \@ran, [], 'nothing ran: every command is checked first';
  is [ map { $_->{verdict} } @{ $res->{commands} } ], [ 'allow', 'ask' ], 'both traced';
};

subtest 'deny rules, ask rules and the mode' => sub {
  my @ran;
  my $deny = renderer( ran => \@ran, permissions => policy( mode => 'bypassPermissions', deny => [ 'Bash(curl:*)' ] ) );
  like $deny->render( entry => $command, body => '!`curl x`' )->{error}, qr/denied by rule 'Bash\(curl:\*\)'/, 'deny';
  is $deny->render( entry => $command, body => '!`ls`' )->{text}, 'OUT:ls', 'bypassPermissions allows the rest';
  my $plan = renderer( permissions => policy( mode => 'plan', allow => [ 'Bash(ls)' ] ) );
  like $plan->render( entry => $command, body => '!`make`' )->{error}, qr/plan mode/, 'plan mode refuses';
  my $none = renderer();
  like $none->render( entry => $command, body => '!`ls`' )->{error}, qr/no permission policy/, 'no policy, no command';
};

subtest 'allowed-tools grant the commands of this entry' => sub {
  my @ran;
  my $entry = { %$command, frontmatter => { 'allowed-tools' => 'Bash(git diff:*), Bash(git log:*)' } };
  my $r = renderer( ran => \@ran, permissions => policy( ask => [ 'Bash(git log:*)' ] ) );
  my $res = $r->render( entry => $entry, body => '!`git diff HEAD`' );
  is $res->{text}, 'OUT:git diff HEAD', 'allowed by the entry';
  is $res->{commands}[0]{verdict}, 'allow', 'traced as allow';
  like $r->render( entry => $entry, body => '!`git log`' )->{error}, qr/asks before this call/, 'an ask rule still wins';
  like $r->render( entry => $command, body => '!`git diff`' )->{error}, qr/default mode asks/, 'not for another entry';
  is $r->permissions->run_rules, [], 'the grant is taken out of the policy after the render';
  $r->permissions->add_run_rules( [ 'Bash(git diff:*)' ], $r->grant_source($entry) );
  my $verdict = $r->check_command('git diff');
  is $verdict->{source}, '/review allowed-tools', 'a run rule names its source';
  $r->permissions->clear_run_rules;
  like $r->check_command('git diff')->{reason}, qr/default mode asks/, 'cleared';
};

subtest 'exit codes' => sub {
  my $r = renderer(
    permissions => policy( mode => 'bypassPermissions' ),
    answers     => {
      'false'          => { exit_code => 1, output => 'boom' },
      'grep x f'       => { exit_code => 1, output => '' },
      '/usr/bin/diff a b' => { exit_code => 1, output => '< a' },
      'grep -q y f'    => { exit_code => 2, output => 'grep: f: No such file' },
      'slow'           => { error => 'timed out after 120 seconds' },
    },
  );
  like $r->render( entry => $command, body => '!`false`' )->{error}, qr/\AShell command failed for pattern "!`false`" in \/review: exit code 1\nboom\z/,
    'non-zero aborts with the output';
  is $r->render( entry => $command, body => '[ !`grep x f`]' )->{text}, '[ ]', 'exit 1 of grep is not a failure';
  is $r->render( entry => $command, body => '!`/usr/bin/diff a b`' )->{text}, '< a', 'exit 1 of diff by path';
  like $r->render( entry => $command, body => '!`grep -q y f`' )->{error}, qr/exit code 2/, 'exit 2 of grep fails';
  like $r->render( entry => $command, body => '!`slow`' )->{error}, qr/timed out after 120 seconds/, 'a timeout aborts';
};

subtest 'where a command is recognised' => sub {
  my @ran;
  my $r = renderer( ran => \@ran, permissions => policy( mode => 'bypassPermissions' ) );
  is $r->render( entry => $command, body => 'a!`no` `!`no2`' )->{text}, 'a!`no` `!`no2`', 'not inside a word';
  is \@ran, [], 'nothing ran';
  my $body = "Before\n```!\ngit status\ngit diff --stat\n```\nAfter !`date`\n";
  is $r->render( entry => $command, body => $body )->{text},
    "Before\nOUT:git status\ngit diff --stat\nAfter OUT:date\n", 'a fenced block and an inline command';
  is \@ran, [ "git status\ngit diff --stat", 'date' ], 'the block runs as one script';
};

subtest 'command output is not scanned again' => sub {
  my $file = $ROOT->child('secret.txt');
  $file->spew_utf8("S\n");
  my $r = renderer(
    permissions => policy( mode => 'bypassPermissions' ),
    answers     => { 'gen' => { exit_code => 0, output => '!`rm x` $ARGUMENTS @secret.txt' } },
  );
  my $res = $r->render( entry => $command, body => 'Got: !`gen` $ARGUMENTS', arguments => 'A', attach_files => 1 );
  is $res->{text}, 'Got: !`rm x` $ARGUMENTS @secret.txt A', 'output stays as it came';
  is $res->{files_read}, [], 'no attachment from output';
  is [ map { $_->{command} } @{ $res->{commands} } ], [ 'gen' ], 'no second command';
  $file->remove;
};

subtest 'disableSkillShellExecution' => sub {
  my @ran;
  my $r = renderer( ran => \@ran, disable_shell => 1 );
  my $res = $r->render( entry => $command, body => "x !`rm -rf /`\n```!\necho\n```\n" );
  is $res->{text}, "x [shell command execution disabled by policy]\n[shell command execution disabled by policy]\n",
    'each command replaced, without a policy';
  is \@ran, [], 'nothing ran';
  is [ map { $_->{verdict} } @{ $res->{commands} } ], [ 'disabled', 'disabled' ], 'traced';
};

subtest 'the loadguard gate' => sub {
  my @ran;
  my @asked;
  my $r = renderer(
    ran         => \@ran,
    permissions => policy( mode => 'bypassPermissions' ),
    validator   => sub { push @asked, [@_]; $_[0] =~ /prove/ ? 'refused by loadguard: heavy command (prove)' : 1 },
  );
  is $r->render( entry => $command, body => '!`ls`' )->{text}, 'OUT:ls', 'a light command runs';
  is $asked[0], [ 'ls', "$ROOT" ], 'asked with the command and the root';
  my $res = $r->render( entry => $command, body => '!`prove -r t`' );
  like $res->{error}, qr/Command refused by loadguard: heavy command \(prove\)/, 'a refusal aborts';
  is $res->{commands}[0]{verdict}, 'refused', 'traced';
  is \@ran, [ 'ls' ], 'the heavy one did not run';
};

subtest 'commands really run with bash in the root' => sub {
  my $r = Langertha::Raider::SlashCommand->new( root => "$ROOT", permissions => policy( mode => 'bypassPermissions' ) );
  my $res = $r->render( entry => $command, body => "[ !`echo hello; echo oops >&2; pwd`]" );
  is $res->{text}, "[ hello\noops\n$ROOT]", 'stdout and stderr together, in the root, trailing newline off';
  is $r->run_command('exit 3'), { exit_code => 3, output => '' }, 'the exit code';
  is $r->render( entry => $command, body => "[ !`grep -q nothing /dev/null`]" )->{text}, '[ ]', 'a real grep without match';

  my $quick = Langertha::Raider::SlashCommand->new( root => "$ROOT", timeout => 0.3, kill_grace => 0.2,
    permissions => policy( mode => 'bypassPermissions' ) );
  my $t0 = Time::HiRes::time();
  like $quick->render( entry => $command, body => '!`sleep 30`' )->{error}, qr/timed out after 0\.3 seconds/, 'a timeout aborts';
  ok Time::HiRes::time() - $t0 < 5, 'and stops the command';
};

#### @file

subtest '@file attachments' => sub {
  $ROOT->child('lib')->mkpath;
  $ROOT->child('lib/App.pm')->spew_utf8("package App;\n1;\n");
  $ROOT->child('my notes.txt')->spew_utf8("note\n");
  my $outside = tempdir();
  $outside->child('x.txt')->spew_utf8("outside\n");
  my $extra = tempdir();
  $extra->child('e.txt')->spew_utf8("extra\n");
  $ROOT->child('.env')->spew_utf8("KEY=1\n");

  my $r = renderer( permissions => policy( deny => [ 'Read(./.env)' ], dirs => [ "$extra" ] ) );
  my $app = $ROOT->child('lib/App.pm')->stringify;

  my $res = $r->render( entry => $command, body => 'Review @lib/App.pm.', attach_files => 1 );
  is $res->{text}, "Review \@lib/App.pm.\n\n"
    ."<system-reminder>\nCalled the read_file tool with the following input: {\"path\":\"$app\"}\n</system-reminder>\n"
    ."<system-reminder>\nResult of calling the read_file tool:\n1\tpackage App;\n2\t1;\n3\t\n</system-reminder>",
    'a file as read_file returns it, sentence dot not part of the path';
  is $res->{files_read}, [ { path => $app, kind => 'file', bytes => "package App;\n1;\n" } ], 'recorded as read whole';

  my $state = Langertha::Raider::FileTools::ReadState->new;
  ok $state->write_problem($app), 'not read before';
  $r->record_reads( $res, $state );
  is $state->write_problem($app), undef, 'record_reads: counts as read for read-before-write';

  $res = $r->render( entry => $command, body => '@lib', attach_files => 1 );
  like $res->{text}, qr/Called the list_files tool with the following input: \{"path":"\Q$ROOT\E\/lib"\}.*Result of calling the list_files tool:\nApp\.pm\n/s,
    'a directory as a listing';
  is $res->{files_read}[0]{kind}, 'directory', 'traced';

  $res = $r->render( entry => $command, body => 'see @"my notes.txt" and @'.$extra->child('e.txt'), attach_files => 1 );
  is [ map { $_->{path} } @{ $res->{files_read} } ],
    [ $ROOT->child('my notes.txt')->stringify, $extra->child('e.txt')->stringify ], 'quoted path; an additional directory';

  for my $case (
    [ '@'.$outside->child('x.txt'), 'outside the allowed roots' ],
    [ '@missing.txt',              'a file that is not there' ],
    [ '@.env',                     'a file a deny rule hides' ],
    [ 'mail me@lib/App.pm',        'not after whitespace' ],
    [ '@../'.$outside->basename.'/x.txt', 'out of the root by ..' ],
  ) {
    my ( $body, $what ) = @$case;
    my $got = $r->render( entry => $command, body => $body, attach_files => 1 );
    is $got->{text}, $body, $what.': stays text';
    is $got->{files_read}, [], $what.': nothing read';
  }

  $res = $r->render( entry => $command, body => '@lib/App.pm @lib/App.pm', attach_files => 1 );
  is scalar @{ $res->{files_read} }, 1, 'the same file once';
  $res = $r->render( entry => $command, body => '@lib/App.pm', arguments => '' );
  is $res->{text}, '@lib/App.pm', 'without attach_files (the skill tool) nothing is attached';
  $res = $r->render( entry => $command, body => 'Look at $ARGUMENTS', arguments => '@lib/App.pm', attach_files => 1 );
  is scalar @{ $res->{files_read} }, 1, 'a reference in the arguments is attached';

  $ROOT->child('img.png')->spew_raw("\x89PNG\r\n\x1a\n");
  $res = $r->render( entry => $command, body => '@img.png', attach_files => 1 );
  is $res->{text}, '@img.png', 'an image is not attached';
};

subtest 'a skill with an attachment keeps its base line first' => sub {
  $ROOT->child('a.txt')->spew_utf8("A\n");
  my $res = renderer( permissions => policy() )->render( entry => $skill, body => "Read \@a.txt\n", attach_files => 1 );
  like $res->{text}, qr/\ABase directory for this skill: \/skills\/pdf\n\nRead \@a\.txt\n\n<system-reminder>\n/, 'base line, text, attachment';
};

done_testing;
