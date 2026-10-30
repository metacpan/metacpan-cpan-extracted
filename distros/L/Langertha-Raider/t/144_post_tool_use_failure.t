#!/usr/bin/env perl
# ABSTRACT: PostToolUseFailure fires for an error result, a refused call and a cancelled one; PostToolUse stays success-only (ADR 0034 §4, k172)
use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
use JSON::MaybeXS ();
use Path::Tiny;
use Test::Raider::Env qw( isolate_home );
BEGIN { isolate_home() }
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Test::Raider::MockAI qw( mock_app );

delete $ENV{CLAUDE_CONFIG_DIR};
my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my @keep;

# A Claude-layout root whose PostToolUse and PostToolUseFailure hooks append
# the event name and their stdin to inputs.jsonl; %more adds hooks.
sub project {
  my ( %more ) = @_;
  my $root = Path::Tiny->tempdir;
  push @keep, $root;
  $root = $root->realpath;
  my $record = '${CLAUDE_PROJECT_DIR}/hooks/record';
  $root->child('.claude')->mkpath;
  $root->child('.claude/settings.json')->spew_raw( $json->encode({ hooks => {
    PostToolUse        => [ { hooks => [ { type => 'command', command => $record.' PostToolUse' } ] } ],
    PostToolUseFailure => [ { hooks => [ { type => 'command', command => $record.' PostToolUseFailure' } ] } ],
    %more,
  } }) );
  my $f = $root->child( 'hooks', 'record' );
  $f->touchpath->spew_raw( "#!/bin/sh\n".'printf \'{"event":"%s","input":%s}\n\' "$1" "$(cat)" >> "$CLAUDE_PROJECT_DIR/inputs.jsonl"'."\n" );
  $f->chmod(0755);
  return $root;
}

sub inputs {
  my ( $root ) = @_;
  my $file = $root->child('inputs.jsonl');
  return [] unless $file->exists;
  return [ map { $json->decode($_) } $file->lines_raw({ chomp => 1 }) ];
}

sub run_in {
  my ( $root, %a ) = @_;
  my @events;
  my $app;
  $app = mock_app( root => "$root", permission_mode => $a{mode} // 'bypassPermissions',
    on_event => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p }; $a{on_event}->( $app, $type, %p ) if $a{on_event} },
    script => $a{script} );
  my $end = $app->run_prompt('go');
  return ( $end, \@events, $app );
}

subtest 'an error result: PostToolUseFailure with Claude Code\'s fields; a success: PostToolUse' => sub {
  my $root = project();
  $root->child('here.txt')->spew("here\n");
  my ( $end, $events, $app ) = run_in( $root, script => [
    { tool_calls => [ [ read_file => { path => 'gone.txt' } ] ] },
    { tool_calls => [ [ read_file => { path => 'here.txt' } ] ] },
    { text => 'done' },
  ] );
  is( $end->{status}, 'completed', 'the run completes' );
  my $in = inputs($root);
  is( [ map { $_->{event} } @$in ], [qw( PostToolUseFailure PostToolUse )], 'failure first, then the success' );
  my $fail = $in->[0]{input};
  like( $fail, {
    hook_event_name => 'PostToolUseFailure',
    tool_name       => 'Read',
    tool_input      => { file_path => T() },
    tool_use_id     => T(),
    error           => qr/\AFile does not exist\./,
    is_interrupt    => F(),
    session_id      => T(),
    cwd             => "$root",
    permission_mode => 'bypassPermissions',
  }, 'tool_name, tool_input, tool_use_id, error, is_interrupt' );
  ok( !exists $fail->{tool_response}, 'no tool_response' );
  my $id = $app->mock_engine->requests->[1]{body}{messages};
  my ($tc) = grep { $_->{role} eq 'assistant' && $_->{tool_calls} } @$id;
  is( $fail->{tool_use_id}, $tc->{tool_calls}[0]{id}, 'tool_use_id is the model\'s id of the call' );
  ok( !exists $in->[1]{input}{error} && exists $in->[1]{input}{tool_response}, 'PostToolUse: tool_response, no error' );
  like( [ grep { $_->{type} eq 'hook.ran' } @$events ],
    [ { hook_event => 'PostToolUseFailure', call => 'c1' }, { hook_event => 'PostToolUse', call => 'c2' } ],
    'hook.ran names the call' );
};

subtest 'a call the gate refuses' => sub {
  my $root = project();
  my ( $end, $events ) = run_in( $root, mode => 'default', script => [
    { tool_calls => [ [ write_file => { path => 'a.txt', content => "a\n" } ] ] },
    { text => 'done' },
  ] );
  ok( !$root->child('a.txt')->exists, 'not written' );
  my $in = inputs($root);
  is( [ map { $_->{event} } @$in ], ['PostToolUseFailure'], 'PostToolUseFailure, as ADR 0034 decides (Claude Code does not fire it here)' );
  like( $in->[0]{input}, { tool_name => 'Write', error => qr/Permission to use write_file has been denied/, is_interrupt => F() },
    'the refusal is the error' );
  like( [ grep { $_->{type} =~ /\A(?:permission\.denied|hook\.ran)\z/ } @$events ],
    [ { type => 'permission.denied', call => 'c1' }, { type => 'hook.ran', hook_event => 'PostToolUseFailure', call => 'c1' } ],
    'both name the call' );
};

subtest 'a call a PreToolUse hook denies' => sub {
  my $root = project( PreToolUse => [ { matcher => 'Bash', hooks => [ { type => 'command', command => 'echo nope >&2; exit 2' } ] } ] );
  my ( $end, $events ) = run_in( $root, script => [
    { tool_calls => [ [ bash => { command => 'echo hi' } ] ] },
    { text => 'done' },
  ] );
  like( inputs($root), [ { event => 'PostToolUseFailure', input => { tool_name => 'Bash', error => qr/nope/ } } ], 'fires with the hook\'s reason' );
  like( [ grep { $_->{type} eq 'hook.ran' } @$events ],
    [ { hook_event => 'PreToolUse', call => 'c1', outcome => 'block' }, { hook_event => 'PostToolUseFailure', call => 'c1' } ],
    'the PreToolUse hook.ran names the call too' );
};

subtest 'a call to a tool the run does not offer (k177)' => sub {
  my $root = project( PreToolUse => [ { hooks => [ { type => 'command', command => '${CLAUDE_PROJECT_DIR}/hooks/record PreToolUse' } ] } ] );
  my ( $end, $events, $app ) = run_in( $root, script => [
    { tool_calls => [ [ nonesuch => { x => 1 } ] ] },
    { text => 'done' },
  ] );
  is( $end->{status}, 'completed', 'the run completes' );
  my $in = inputs($root);
  is( [ map { $_->{event} } @$in ], ['PostToolUseFailure'], 'PostToolUseFailure, and no PreToolUse (the call ends at resolve, ADR 0005)' );
  like( $in->[0]{input}, {
    hook_event_name => 'PostToolUseFailure',
    tool_name       => 'nonesuch',
    tool_input      => { x => 1 },
    tool_use_id     => T(),
    error           => '<tool_use_error>Error: No such tool available: nonesuch</tool_use_error>',
    is_interrupt    => F(),
  }, 'with Claude Code\'s fields; the error is the text the model gets' );
  like( [ grep { $_->{type} =~ /\Atool\.|\Ahook\.ran\z/ } @$events ], [
    { type => 'tool.call',   call => 'c1', name => 'nonesuch' },
    { type => 'hook.ran',    call => 'c1', hook_event => 'PostToolUseFailure' },
    { type => 'tool.result', call => 'c1', name => 'nonesuch', status => 'failed', ok => F() },
  ], 'one tool.call, one tool.result' );
  my $text = join "\n", map { $_->{text} // '' } @{ $app->mock_engine->results->[0]{result}{content} };
  is( $text, '<tool_use_error>Error: No such tool available: nonesuch</tool_use_error>', 'the model gets the same text as before' );
};

subtest 'a cancelled call: is_interrupt' => sub {
  my $root = project();
  my ( $end, $events ) = run_in( $root,
    on_event => sub { my ( $app, $type ) = @_; $app->cancel_run if $type eq 'tool.call' },
    script => [ { tool_calls => [ [ bash => { command => 'sleep 5' } ] ] }, { text => 'never' } ] );
  is( $end->{status}, 'cancelled', 'the run is cancelled' );
  my ($result) = grep { $_->{type} eq 'tool.result' } @$events;
  is( $result->{status}, 'cancelled', 'the call was cut off' );
  like( inputs($root), [ { event => 'PostToolUseFailure', input => { tool_name => 'Bash', is_interrupt => T(), error => T() } } ],
    'PostToolUseFailure with is_interrupt true' );
};

subtest 'its feedback reaches the model' => sub {
  my $root = project();
  my $settings = $json->decode( $root->child('.claude/settings.json')->slurp_raw );
  $settings->{hooks}{PostToolUseFailure} = [ { hooks => [ { type => 'command',
    command => q{cat >/dev/null; echo '{"hookSpecificOutput":{"hookEventName":"PostToolUseFailure","additionalContext":"try list_files first"}}'} } ] } ];
  $root->child('.claude/settings.json')->spew_raw( $json->encode($settings) );
  my ( $end, $events, $app ) = run_in( $root, script => [
    { tool_calls => [ [ read_file => { path => 'gone.txt' } ] ] },
    { text => 'done' },
  ] );
  my $text = join "\n", map { $_->{text} // '' } @{ $app->mock_engine->results->[0]{result}{content} };
  like( $text, qr{<system-reminder>\nPostToolUseFailure:Read hook additional context: try list_files first\n</system-reminder>},
    'additionalContext as a system-reminder after the error' );
};

done_testing;
