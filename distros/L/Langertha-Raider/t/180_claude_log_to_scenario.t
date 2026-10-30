#!/usr/bin/env perl
# ABSTRACT: maint/claude-log-to-scenario drafts a scenario from a Claude Code session, and the draft runs
use strict;
use warnings;
use utf8;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
use IPC::Open3 qw( open3 );
use JSON::MaybeXS ();
use Path::Tiny;
use YAML::PP;
BEGIN {
  plan skip_all => 'maint/claude-log-to-scenario is development infrastructure, not in the tarball'
    unless -f "$FindBin::Bin/../maint/claude-log-to-scenario";
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::Scenario qw( run_scenario_files );

# t/data/claude-log/session.jsonl is a synthetic session of a project at
# /home/tester/work/demo (home /home/tester), in the shape Claude Code writes:
# prompt 1 -- a response split over three lines (thinking, text, Read), a
# response with an unknown tool (ToolSearch) and an Edit, a sidechain record,
# a response with a Read outside the project, a failing Bash and a Bash
# carrying a secret, a closing text; prompt 2 -- a Read in the home, an Agent
# call without a subagent log, a Read of a part of a file, a closing text;
# prompt 3 -- two Agent calls in one response, each with its subagent log
# under session/subagents/: a reviewer (found by its meta file) that reads
# app.txt and starts a nested agent in one response, hands its report back
# with SubagentHandback, closes with a text and gets a later SendMessage turn;
# an Explore agent in the background (found by the agentId of its result)
# that globs. Secrets in it are fake.

my $script = path("$FindBin::Bin/../maint/claude-log-to-scenario")->realpath;
my $log    = path("$FindBin::Bin/data/claude-log/session.jsonl")->realpath;
my $yaml   = YAML::PP->new( boolean => 'JSON::PP' );

sub convert {
  my ( @args ) = @_;
  my $err = Path::Tiny->tempfile;
  my $fh  = $err->openw_raw;
  my $pid = open3( my $in, my $out, '>&'.fileno($fh), $^X, "$script", @args );
  close $in;
  my $stdout = do { local $/; <$out> };
  waitpid $pid, 0;
  close $fh;
  utf8::decode($stdout);
  return { out => $stdout, err => $err->slurp_utf8, exit => $? >> 8 };
}

subtest 'the first prompt up to the next one' => sub {
  my $run = convert( "$log", '--home', '/home/tester' );
  is( $run->{exit}, 0, 'converts' ) or diag $run->{err};
  my $text = $run->{out};
  my $s    = $yaml->load_string($text);

  like( $text, qr/\A# DRAFT -- written by maint\/claude-log-to-scenario/, 'the head says it is a draft' );
  is( $s->{prompt}, 'Change two to 2 in app.txt. My key is REDACTED.', 'prompt: path relative, key redacted' );
  is( $s->{files}, { 'app.txt' => "one\ntwo\nthree\n\n" }, 'files: rebuilt from the whole Read, its trailing empty line kept' );
  ok( !exists $s->{home}, 'no home file' );
  is( $s->{script}, [
    { tool_calls => [ [ read_file => { path => 'app.txt' } ] ] },
    { tool_calls => [ [ edit_file => { path => 'app.txt', old_string => 'two', new_string => '2', replace_all => F() } ] ] },
    { tool_calls => [
      [ bash => { command => 'ls {{ROOT}}/no-such-dir', description => 'List a missing directory' } ],
      [ bash => { command => 'echo API_TOKEN=REDACTED > /dev/null', timeout => 30 } ],
    ] },
    { text => 'Done: two is now 2 in app.txt.' },
  ], 'script: one step per response (split lines joined), names and arguments translated, sidechain skipped' );
  is( $s->{expect}, {
    answer => 'Done: two is now 2 in app.txt.',
    tools  => [
      { name => 'read_file', text => 'one' },
      { name => 'edit_file' },
      { name => 'bash', error => T() },
      { name => 'bash' },
    ],
  }, 'expect: the answer and every call, the failed one an error, the whole read anchored' );

  like( $text, qr/^  # left out ToolSearch: raider has no such tool$/m, 'the unknown tool is noted' );
  like( $text, qr{^  # left out Read /etc/hostname: outside the project and the home$}m, 'the call outside is noted' );
  like( $text, qr/^    # Claude Code: Exit code 2$/m, "Claude Code's error is noted" );
  like( $text, qr/^  # model: I read the file first\.$/m, 'the text beside tool calls is noted' );
  unlike( $text, qr/sk-fake|ghp_fake|hunter22/, 'no secret left' );
  unlike( $text, qr{/home/tester}, 'no path of the session left' );
  unlike( $text, qr/side\.txt|plan/, 'neither sidechain nor thinking' );

  my $dir = Path::Tiny->tempdir;
  my $file = $dir->child('from-claude-log.yml');
  $file->spew_utf8($text);
  run_scenario_files("$file");
};

subtest 'the second prompt: the home, an agent, a partial read' => sub {
  my $run = convert( "$log", '--home', '/home/tester', '--from', 'u0000019' );
  is( $run->{exit}, 0, 'converts' ) or diag $run->{err};
  my $s = $yaml->load_string( $run->{out} );
  is( $s->{prompt}, 'Now look at my config.', 'the prompt it starts at' );
  is( $s->{home}, { '.config/demo.conf' => "name=demo\npassword=REDACTED\n" }, 'home: the file read there, its password redacted' );
  ok( !exists $s->{files}, 'big.txt is not rebuilt from a part' );
  like( $run->{out}, qr/^# big\.txt: not rebuilt, read only in part \(lines 10 to 14 of 40\)$/m, 'and that is noted' );
  is( $s->{script}[0], { tool_calls => [
    [ read_file => { path => '{{HOME}}/.config/demo.conf' } ],
    [ agent     => { description => 'Check', prompt => 'Look at {{ROOT}}', subagent_type => 'general-purpose' } ],
  ] }, 'a home path as {{HOME}}, Agent as agent with the root a placeholder' );
  is( $s->{script}[1], { text => 'All fine.' }, 'without a subagent log the subagent answers what Claude Code returned' );
  like( $run->{out}, qr/^  # subagent of Agent \(Check\): no log of its turns, it answers with what Claude Code returned$/m,
    'which is noted' );
  is( $s->{script}[2], { tool_calls => [ [ read_file => { path => 'big.txt', offset => 10, limit => 5 } ] ] },
    'the arguments raider does not know pass through' );
  is( $s->{expect}{tools}, [
    { name => 'read_file', text => 'name=demo' },
    { name => 'agent', text => '\A\s*All fine\.' },
    { name => 'read_file' },
  ], 'the agent result is anchored on the answer' );
};

subtest 'the third prompt: each subagent replays its own log after the call that starts it' => sub {
  my $run = convert( "$log", '--home', '/home/tester', '--from', 'u0000027' );
  is( $run->{exit}, 0, 'converts' ) or diag $run->{err};
  my $text = $run->{out};
  my $s    = $yaml->load_string($text);
  like( $text, qr/^# 2 model responses and 7 of subagents\./m, 'the head counts the subagent responses apart' )
    or diag $text;
  ok( !exists $s->{app}, 'a subagent of a subagent: within raider\'s default depth of 3, no app key' );
  unlike( $text, qr/max_agent_depth|deeper than/, 'nor a note' );
  is( $s->{files}, { 'app.txt' => "one\n2\nthree\n\n" }, "files: rebuilt from the subagent's whole Read" );
  is( $s->{script}, [
    { tool_calls => [
      [ agent => { description => 'Review app', prompt => 'Review {{ROOT}}/app.txt and report.', subagent_type => 'general-purpose' } ],
      [ agent => { description => 'Find files', prompt => 'List the text files.', subagent_type => 'Explore' } ],
    ] },
    { tool_calls => [
      [ read_file => { path => 'app.txt' } ],
      [ agent     => { description => 'Count lines', prompt => 'Count the lines of app.txt.' } ],
    ] },
    { tool_calls => [ [ bash => { command => 'wc -l app.txt', description => 'Count lines' } ] ] },
    { text => '4 lines' },
    { text => "The file is fine.\nIt has 4 lines." },
    { tool_calls => [ [ glob => { path => '.', pattern => '*.txt' } ] ] },
    { text => 'app.txt' },
    { text => 'Reviewer: fine. Explorer: app.txt.' },
  ], 'script: the caller, the reviewer up to its handback with the nested agent inside, the explorer, the caller' );
  is( $s->{expect}, {
    answer => 'Reviewer: fine. Explorer: app.txt.',
    tools  => [
      { name => 'bash' },
      { name => 'read_file', text => 'one' },
      { name => 'agent', text => '\A\s*4 lines' },
      { name => 'glob' },
      { name => 'agent', text => '\A\s*The file is fine\.' },
      { name => 'agent', text => '\A\s*app\.txt' },
    ],
  }, "expect: a subagent's results before those of the response that started it" );

  like( $text, qr/^  # subagent_type reviewer: no such agent file in \.claude\/agents of the project .*, general-purpose stands in$/m,
    'an agent file that is not there: general-purpose, noted' );
  unlike( $text, qr/subagent_type Explore:/, 'Explore stays: raider has it built in (ADR 0027)' );
  like( $text, qr/^  # subagent Explore of Agent \(Find files\), from agent-a0000000000000002\.jsonl /m, 'and runs as Explore' );
  like( $text, qr/^  # subagent reviewer \(as general-purpose\) of Agent \(Review app\), from agent-a0000000000000001\.jsonl$/m,
    'where a subagent starts is noted' );
  like( $text, qr/^  # left out 1 later response of this run, after SubagentHandback$/m, 'the text after the handback is left out' );
  like( $text, qr/^  # its log goes on after a later message to it \(SendMessage\): 1 more response not replayed$/m,
    'and so is the later turn' );
  like( $text, qr/from agent-a0000000000000002\.jsonl \(Claude Code ran it in the background, raider runs it to the end\)$/m,
    'the background agent runs to the end' );
  like( $text, qr/^    # Claude Code's result was only the launch notice: it ran the agent in the background$/m,
    'and its different result is noted' );
  unlike( $text, qr/SendMessage with to|<usage>|is it sorted|Briefing/, "neither Claude Code's appendix, the later turn nor the briefed prompt" );

  my $dir  = Path::Tiny->tempdir;
  my $file = $dir->child('agents-from-claude-log.yml');
  $file->spew_utf8($text);
  run_scenario_files("$file");
};

subtest "an agent file of the project goes into files:, without its skills" => sub {
  # the session again, in a project that exists here
  my $copy = Path::Tiny->tempdir;
  my $root = Path::Tiny->tempdir->realpath;
  my $from = $log->parent;
  for my $f ( grep { $_->is_file } map { $from->child($_) } 'session.jsonl', map { 'session/subagents/'.$_->basename } $from->child( 'session', 'subagents' )->children ) {
    ( my $content = $f->slurp_raw ) =~ s{/home/tester/work/demo}{$root}g;
    $copy->child( $f->relative($from) )->touchpath->spew_raw($content);
  }
  $root->child( '.claude', 'agents', 'review', 'reviewer.md' )->touchpath->spew_utf8(
    "---\nname: reviewer\ndescription: Reviews files, changes nothing.\nbriefing:\n  skills:\n    - review\n    - getty-perl-core\nmodel: sonnet\n---\n"
    ."REVIEWER-BODY: read in $root, never write. Not sk-fake2222222222222222222.\n" );
  my $run = convert( $copy->child('session.jsonl')->stringify, '--home', '/home/tester', '--from', 'u0000027' );
  is( $run->{exit}, 0, 'converts' ) or diag $run->{err};
  my $s = $yaml->load_string( $run->{out} );
  is( $s->{files}{'.claude/agents/review/reviewer.md'},
    "---\nname: reviewer\ndescription: Reviews files, changes nothing.\nmodel: sonnet\n---\nREVIEWER-BODY: read in {{ROOT}}, never write. Not REDACTED.\n",
    'the agent file, its skills taken out, the root a placeholder, the secret redacted' );
  like( $run->{out}, qr/^# \.claude\/agents\/review\/reviewer\.md: the agent reviewer, from the project, without its skills \(review, getty-perl-core\)$/m,
    'noted' );
  is( $s->{script}[0]{tool_calls}[0][1]{subagent_type}, 'reviewer', 'the call keeps its agent' );
  is( $s->{script}[0]{tool_calls}[1][1]{subagent_type}, 'Explore', 'so does the built-in Explore' );

  my $dir  = Path::Tiny->tempdir;
  my $file = $dir->child('agent-file-from-claude-log.yml');
  $file->spew_utf8( $run->{out} );
  run_scenario_files("$file");
};

subtest '--turns runs on over the next prompt' => sub {
  my $run = convert( "$log", '--home', '/home/tester', '--from', 'u0000012', '--turns', '3' );
  is( $run->{exit}, 0, 'converts' ) or diag $run->{err};
  my $s = $yaml->load_string( $run->{out} );
  is( $s->{prompts}, [ 'Change two to 2 in app.txt. My key is REDACTED.', 'Now look at my config.' ],
    'the prompt before the start, then the one met on the way' );
  is( [ map { $_->{text} // 'calls' } @{ $s->{script} } ], [ 'calls', 'Done: two is now 2 in app.txt.', 'calls', 'All fine.', 'done' ],
    'a turn cut short ends on a text answer' );
  like( $run->{out}, qr/# the turn ends here without a text answer in the log/, 'which is noted' );
};

subtest 'a session id is looked up in the Claude projects' => sub {
  my $config = Path::Tiny->tempdir;
  my $copy   = $config->child( 'projects', '-home-tester-work-demo', '00000000-0000-4000-8000-000000000001.jsonl' );
  $copy->touchpath;
  $log->copy($copy);
  local $ENV{CLAUDE_CONFIG_DIR} = "$config";
  my $by_id = convert( '00000000-0000-4000', '--home', '/home/tester' );
  is( $by_id->{exit}, 0, 'found by the start of its id' ) or diag $by_id->{err};
  like( $by_id->{out}, qr/^# 00000000-0000-4000-8000-000000000001, from record/m, 'the head names the session' );
  my $listed = convert( '00000000-0000-4000-8000-000000000001', '--list' );
  like( $listed->{out}, qr/^u0000001-\S+  \S+  PROMPT  Change two .* My key is REDACTED\.$/m, '--list shows the prompts, redacted' );
  like( $listed->{out}, qr/^u0000003-\S+  \S+  MODEL   "I read the file first\." Read$/m, 'and the responses' );
  like( $listed->{out}, qr/^u0000028-\S+  \S+  MODEL   "I hand both to agents\." Agent\[no subagent log\] Agent\[no subagent log\]$/m,
    'an Agent call whose subagent log is not there' );
  my $beside = convert( "$log", '--list' );
  like( $beside->{out},
    qr/^u0000028-\S+  \S+  MODEL   "I hand both to agents\." Agent\[agent-a0000000000000001\.jsonl, 3 responses\] Agent\[agent-a0000000000000002\.jsonl, 2 responses\]$/m,
    'and with its subagent logs: each with the responses of its first run' );
};

# t/data/claude-log/tools.jsonl (written by a throwaway script, synthetic like
# session.jsonl): prompt 1 -- TaskCreate, TaskUpdate; prompt 2 -- a Read, a
# MultiEdit of two edits; prompt 3 -- a TodoWrite and a failing TaskOutput.
my $tools_log = path("$FindBin::Bin/data/claude-log/tools.jsonl")->realpath;

subtest 'the task tools, MultiEdit as one multi_edit, TodoWrite mounts todo_write (ADR 0025)' => sub {
  my $dir = Path::Tiny->tempdir;
  my $tasks = convert( "$tools_log", '--home', '/home/tester', '--from', 't0000001' );
  is( $tasks->{exit}, 0, 'converts' ) or diag $tasks->{err};
  my $s = $yaml->load_string( $tasks->{out} );
  is( $s->{script}, [
    { tool_calls => [ [ task_create => { subject => 'Tidy app.txt', description => 'Fix the numbers', activeForm => 'Tidying app.txt' } ] ] },
    { tool_calls => [ [ task_update => { taskId => '1', status => 'in_progress' } ] ] },
    { text => 'One task, in progress.' },
  ], 'TaskCreate and TaskUpdate as task_create and task_update, arguments unchanged' );
  ok( !exists $s->{app}, 'the task tools are the default family: no app key' );
  $dir->child('tasks.yml')->spew_utf8( $tasks->{out} );

  my $multi = convert( "$tools_log", '--home', '/home/tester', '--from', 't0000007' );
  is( $multi->{exit}, 0, 'converts' ) or diag $multi->{err};
  $s = $yaml->load_string( $multi->{out} );
  is( $s->{script}[1], { tool_calls => [ [ multi_edit => { path => 'app.txt', edits => [
    { old_string => 'two', new_string => '2' }, { old_string => 'three', new_string => '3', replace_all => F() },
  ] } ] ] }, 'one MultiEdit is one multi_edit call with the edits as they are' );
  is( $s->{expect}{tools}, [ { name => 'read_file', text => 'one' }, { name => 'multi_edit' } ], 'one expectation for it' );
  is( $s->{files}, { 'app.txt' => "one\ntwo\nthree\n" }, 'the file rebuilt from the Read' );
  unlike( $multi->{out}, qr/all or none/, 'no note about splitting any more' );
  $dir->child('multi.yml')->spew_utf8( $multi->{out} );

  my $todo = convert( "$tools_log", '--home', '/home/tester', '--from', 't0000013' );
  is( $todo->{exit}, 0, 'converts' ) or diag $todo->{err};
  $s = $yaml->load_string( $todo->{out} );
  is( $s->{app}, { task_tools => F() }, 'a TodoWrite section mounts todo_write instead of the task tools' );
  is( $s->{script}[0]{tool_calls}[0][0], 'todo_write', 'TodoWrite as todo_write' );
  is( $s->{script}[1], { tool_calls => [ [ bash_output => { bash_id => 'bash_1', block => T() } ] ] },
    'TaskOutput as bash_output, task_id as bash_id' );
  is( $s->{expect}{tools}[1], { name => 'bash_output', error => T() }, "Claude Code's failed call expected to fail" );
  $dir->child('todo.yml')->spew_utf8( $todo->{out} );

  run_scenario_files( map { $dir->child($_)->stringify } qw( tasks.yml multi.yml todo.yml ) );
};

subtest 'SendMessage is left out and noted: raider would resume the agent in the background (ADR 0027)' => sub {
  my $dir  = Path::Tiny->tempdir;
  my $file = $dir->child('send.jsonl');
  my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
  my $n    = 0;
  my $line = sub {
    my ( $type, $message, %more ) = @_;
    $n++;
    return $json->encode( { cwd => '/home/tester/work/demo', isSidechain => JSON::MaybeXS->false, message => $message,
      parentUuid => undef, sessionId => '00000000-0000-4000-8000-000000000003',
      timestamp => sprintf( '2026-10-19T10:00:%02d.000Z', $n ), type => $type,
      uuid => sprintf( 's%07d-0000-4000-8000-%012d', $n, $n ), version => '2.1.300', %more } )."\n";
  };
  $file->spew_raw(
    $line->( user => { role => 'user', content => 'Ask the reviewer again.' } ),
    $line->( assistant => { id => 'msg_s1', model => 'claude-test', role => 'assistant', type => 'message', content => [
      { type => 'tool_use', id => 'toolu_s1', name => 'SendMessage',
        input => { to => 'a0000000000000001', message => 'Check it again.', summary => 'again' } } ] } ),
    $line->( user => { role => 'user', content => [ { type => 'tool_result', tool_use_id => 'toolu_s1',
      content => 'Message queued for delivery to a0000000000000001 at its next tool round.' } ] } ),
    $line->( assistant => { id => 'msg_s2', model => 'claude-test', role => 'assistant', type => 'message',
      content => [ { type => 'text', text => 'Asked.' } ] } ),
  );
  my $run = convert( "$file", '--home', '/home/tester' );
  is( $run->{exit}, 0, 'converts' ) or diag $run->{err};
  my $s = $yaml->load_string( $run->{out} );
  is( $s->{script}, [ { text => 'Asked.' } ], 'no send_message call in the script' );
  like( $run->{out}, qr/^  # left out SendMessage to a0000000000000001: continuing an agent runs it in the background in raider, which the draft does not replay$/m,
    'the note says why' ) or diag $run->{out};
};

subtest 'mistakes are refused with a message' => sub {
  my $result = convert( "$log", '--from', 'u0000006' );
  is( $result->{exit}, 2, 'a tool result is no start' );
  like( $result->{err}, qr/\Aclaude-log-to-scenario: Record u0000006-\S+ is a tool result: start at a prompt or a model response\n\z/,
    'said in one line' );
  my $missing = convert( "$log", '--from', 'nope' );
  is( $missing->{exit}, 2, 'an unknown record' );
  like( $missing->{err}, qr/No record nope/, 'is named' );
};

done_testing;
