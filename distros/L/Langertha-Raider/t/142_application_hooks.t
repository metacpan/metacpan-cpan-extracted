#!/usr/bin/env perl
# ABSTRACT: The application runs the Claude Code hooks: gate weighing, sessions, Stop, async (ADR 0022, k155)
use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
use JSON::MaybeXS ();
use Path::Tiny;
use Time::HiRes ();
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::MockAI qw( mock_app );

# A fresh root in the Claude layout (.claude/settings.json) per test, $HOME
# at a temp dir; hook scripts are sh files in the root.

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my @keep;

sub project {
  my ( %a ) = @_;
  my $home = Path::Tiny->tempdir;
  my $root = Path::Tiny->tempdir;
  push @keep, $home, $root;
  $ENV{HOME} = $home->realpath->stringify;
  delete $ENV{CLAUDE_CONFIG_DIR};
  $root = $root->realpath;
  $root->child('.claude')->mkpath;
  $root->child('.claude/settings.json')->spew_raw($json->encode({ hooks => $a{hooks} // {}, %{ $a{settings} // {} } }));
  for my $name (keys %{ $a{scripts} // {} }) {
    my $f = $root->child('hooks', $name);
    $f->touchpath->spew_raw("#!/bin/sh\n".$a{scripts}{$name}."\n");
    $f->chmod(0755);
  }
  return $root;
}

sub hook { my ( $cmd, %more ) = @_; { hooks => [ { type => 'command', command => $cmd, %more } ], %{ $more{group} // {} } } }

sub app_for {
  my ( $root, %a ) = @_;
  my @events;
  my $app = mock_app( root => "$root", permission_mode => 'bypassPermissions',
    on_event => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } }, %a );
  return ( $app, \@events );
}

local %ENV = %ENV;

subtest 'the gate weighs a hook decision against the policy' => sub {
  my $root = project( settings => { permissions => { ask => [ 'Bash(git push:*)' ] } } );
  my $gate = sub { my ( $app, %call ) = @_; $app->tool_gate->( undef, { source => 'engine:1', %call } ) };

  my ( $app ) = app_for( $root, permission_mode => 'default' );
  is( $gate->( $app, name => 'write_file', arguments => { path => 'a' } )->{verdict}, 'deny',
    'default mode, nobody to ask: write_file refused without a hook' );
  my $v = $gate->( $app, name => 'write_file', arguments => { path => 'a' }, hook => { decision => 'allow', reason => 'PreToolUse hook: ok' } );
  is( [ @$v{qw( verdict by )} ], [ 'allow', 'hook' ], 'a hook allow spares the mode question' );
  $v = $gate->( $app, name => 'bash', arguments => { command => 'git push origin' }, hook => { decision => 'allow' } );
  is( [ @$v{qw( verdict by )} ], [ 'deny', 'noninteractive' ], 'an ask rule still asks (and nobody can answer)' );

  ( $app ) = app_for( $root, permission_mode => 'plan' );
  $v = $gate->( $app, name => 'write_file', arguments => { path => 'a' }, hook => { decision => 'allow' } );
  is( [ @$v{qw( verdict by )} ], [ 'deny', 'mode' ], 'plan mode: a hook allow changes nothing for a change' );

  my @asked;
  ( $app ) = app_for( $root, on_permission_request => sub { push @asked, $_[0]; { answer => 'once' } } );
  $v = $gate->( $app, name => 'read_file', arguments => { path => 'a' }, hook => { decision => 'ask', reason => 'PreToolUse hook: check this' } );
  is( $v->{verdict}, 'allow', 'bypassPermissions + hook ask: the person is asked, says once' );
  is( $asked[0]{reason}, 'PreToolUse hook: check this', '... with the hook\'s reason' );

  ( $app ) = app_for( $root );
  my $p = $app->permissions;
  is( $p->rule_matches( 'Bash(git *)', { name => 'bash', source => 'engine:1', arguments => { command => 'npm test && git push' } } ), 1,
    'rule_matches (a hook\'s "if"): any part of the command' );
  is( $p->rule_matches( 'Edit(*.ts)', { name => 'edit_file', source => 'engine:1', arguments => { path => 'lib/A.pm' } } ), 0, '... a path that does not match' );
  is( $p->rule_matches( 'NoSuchTool', { name => 'bash', arguments => {} } ), undef, '... an invalid rule cannot be decided' );
  $v = $gate->( $app, name => 'read_file', arguments => { path => 'a' }, hook => { decision => 'ask', reason => 'r' } );
  is( $v->{verdict}, 'deny', 'hook ask without a person: refused' );
  unlike( $v->{reason}, qr/To allow it, add/, 'no rule is suggested: a rule cannot lift a hook ask' );
};

subtest 'session input, journal events, SessionStart sources' => sub {
  my $root = project(
    hooks   => { SessionStart => [ hook('${CLAUDE_PROJECT_DIR}/hooks/start', args => []) ] },
    scripts => { start => 'cat > "$CLAUDE_PROJECT_DIR/stdin.json"; printf "%s\n" "$(sed -e \'s/.*"source":"\([a-z]*\)".*/\1/\' "$CLAUDE_PROJECT_DIR/stdin.json")" >> "$CLAUDE_PROJECT_DIR/sources"; echo "systemMessage-free context"' },
  );
  # claude => 1: create_session makes .raider/, which would make this a raider project.
  my ( $app, $events ) = app_for( $root, claude => 1, script => [ { text => 'a' }, { text => 'b' }, { text => 'c' }, { text => 'd' } ] );
  my $session = $app->create_session;
  $app->run_prompt( 'one', session => $session );
  my $in = $json->decode( $root->child('stdin.json')->slurp_raw );
  is( [ @$in{qw( hook_event_name session_id transcript_path permission_mode source cwd )} ],
    [ 'SessionStart', $session->id, ''.$session->path, 'bypassPermissions', 'startup', "$root" ], 'the common input' );
  $app->run_prompt( 'two', session => $session );
  $app->note_history_cleared;
  $app->run_prompt( 'three', session => $session );
  $session->release;

  # The session store made .raider/ in the root, which a new start reads as
  # a raider project; claude => 1 keeps the Claude layout for the resume.
  my ( $app2 ) = app_for( $root, claude => 1, script => [ { text => 'e' } ] );
  my $again = $app2->open_session( $session->id );
  $app2->replay_session($again);
  $app2->run_prompt( 'four', session => $again );
  is( [ $root->child('sources')->lines({ chomp => 1 }) ], [qw( startup clear resume )], 'startup once, clear after /clear, resume after a replay' );

  my @journal = map { $json->decode($_) } $again->path->lines_raw;
  my @ran = grep { $_->{type} eq 'hook.ran' } @journal;
  is( scalar @ran, 3, 'hook.ran in the journal, once per run that fired it' ) or diag $json->encode(\@journal);
  like( $ran[0], { hook_event => 'SessionStart', outcome => 'success', exit => 0, source => '.claude/settings.json',
    stdout => "systemMessage-free context\n" }, 'with outcome, exit and output' );
  ok( ( grep { $_->{type} eq 'message' && ( $_->{content} // '' ) eq 'one' } @journal ), 'the user message is journaled as typed' );
};

subtest 'Stop: at most stop_hook_limit continuations' => sub {
  my $root = project( hooks => { Stop => [ hook('cat >/dev/null; echo again >&2; exit 2') ] } );
  my ( $app, $events ) = app_for( $root, script => [] );
  my $end = $app->run_prompt('go');
  is( $end->{status}, 'completed', 'the run ends' );
  is( scalar @{ $app->mock_engine->requests }, 1 + $app->stop_hook_limit, 'one answer plus stop_hook_limit continuations' );
  like( [ grep { $_->{type} eq 'hook.message' } @$events ]->[-1], { kind => 'error', text => qr/kept the run going 8 times/ },
    'the cap is reported' );
};

subtest 'PreToolUse context on the result; continue false cancels' => sub {
  my $root = project( hooks => {
    PreToolUse  => [ hook(q{cat >/dev/null; printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"the tree is frozen"}}'}, group => { matcher => 'Bash' }) ],
    PostToolUse => [ hook(q{cat >/dev/null; printf '%s' '{"continue":false,"stopReason":"enough"}'}, group => { matcher => 'Write' }) ],
  } );
  my ( $app, $events ) = app_for( $root, script => [
    { tool_calls => [ [ bash => { command => 'echo hi' } ] ] },
    { tool_calls => [ [ write_file => { path => 'a.txt', content => 'x' } ], [ bash => { command => 'echo never' } ] ] },
    { text => 'not reached' },
  ] );
  my $end = $app->run_prompt('go');
  my @results = @{ $app->mock_engine->results };
  my $first = join "\n", map { $_->{text} // '' } @{ $results[0]{result}{content} };
  like( $first, qr/hi.*<system-reminder>\nPreToolUse:Bash hook additional context: the tree is frozen\n<\/system-reminder>/s,
    'PreToolUse additionalContext next to the result' );
  is( $end->{status}, 'cancelled', 'continue: false on PostToolUse cancels the run' );
  ok( $root->child('a.txt')->exists, 'the tool had run' );
  like( [ grep { $_->{type} eq 'hook.message' } @$events ]->[-1], { kind => 'stopped', text => 'enough' }, 'the stop reason for the person' );
  like( [ grep { $_->{type} eq 'tool.result' } @$events ]->[0]{content}, qr/PreToolUse:Bash hook additional context: the tree is frozen/,
    'tool.result is the result as the model got it' );
};

subtest 'async hooks deliver on the next turn; shutdown stops them' => sub {
  my $root = project( hooks => {
    UserPromptSubmit => [ hook(q{cat >/dev/null; printf '%s' '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"lint is clean"}}'}, async => JSON::MaybeXS->true) ],
  } );
  my ( $app ) = app_for( $root, script => [ { text => 'a' }, { text => 'b' } ] );
  $app->run_prompt('first');
  my $end = Time::HiRes::time() + 10;
  $app->loop->loop_once(0.05) while $app->hooks->running_async && Time::HiRes::time() < $end;
  $app->run_prompt('second');
  my $seen = $json->encode( $app->mock_engine->requests->[1]{body}{messages} );
  like( $seen, qr/UserPromptSubmit hook additional context: lint is clean/, 'the first turn\'s async context arrives with the second prompt' );
  $app->shutdown_hooks;
  is( $app->hooks->running_async, 0, 'shutdown_hooks leaves nothing running' );
};

subtest 'no hooks outside the Claude layout' => sub {
  my $root = project( hooks => { UserPromptSubmit => [ hook('cat >/dev/null; exit 2') ] } );
  my ( $bare ) = app_for( $root, bare => 1, script => [ { text => 'ok' } ] );
  is( $bare->hooks, undef, '--bare: no runner' );
  is( $bare->run_prompt('go')->{status}, 'completed', '... and nothing blocks' );
  $root->child('.raider')->mkpath;
  $root->child('.raider/instructions.md')->spew_raw("x\n");
  my ( $native ) = app_for( $root, script => [ { text => 'ok' } ] );
  is( $native->hooks, undef, 'a raider project: no runner' );
};

done_testing;
