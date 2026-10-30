#!/usr/bin/env perl
# ABSTRACT: What the model is told when a PreToolUse hook denies, in Claude Code's words (ADR 0022 addendum)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use IO::Async::Loop;
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Raider::Hooks;

my $home = path( tempdir( CLEANUP => 1 ) );
local $ENV{HOME} = "$home";
local $ENV{CLAUDE_CONFIG_DIR} = '';

my $loop = IO::Async::Loop->new;
my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $bin  = path( tempdir( CLEANUP => 1 ) );
my $root = path( tempdir( CLEANUP => 1 ) );

my $n = 0;
sub script {
  my ( $body ) = @_;
  my $file = $bin->child( 'hook'.++$n );
  $file->spew_raw( "#!/bin/sh\n".$body."\n" );
  $file->chmod(0755);
  return "$file";
}
sub answer { my ( $data ) = @_; script( "cat >/dev/null\nprintf '%s' '".$json->encode($data)."'" ) }
sub deny_json { my ( $why ) = @_; answer({ hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'deny', ( defined $why ? ( permissionDecisionReason => $why ) : () ) } }) }
sub exit2 { my ( $err ) = @_; script( "cat >/dev/null\n".( defined $err ? "echo '$err' >&2\n" : '' )."exit 2" ) }

sub run_with {
  my ( $tool, @cmds ) = @_;
  my $h = Langertha::Raider::Hooks->new( loop => $loop, root => "$root", groups => { PreToolUse => [
    { matcher => undef, hooks => [ map { { type => 'command', command => $_ } } @cmds ], source => 'test', plugin => undef },
  ] } );
  return $h->run( PreToolUse => { tool_name => $tool, tool_input => { command => 'ls' } } );
}

subtest 'exit 2: the stderr as a hook error, with the tool in Claude\'s name' => sub {
  my $r = run_with( bash => exit2('rm is not allowed') );
  is( $r->decision, 'deny', 'denied' );
  is( $r->deny_message, 'PreToolUse:Bash hook error: rm is not allowed', 'Claude\'s text' );
  is( $r->reason, 'rm is not allowed', 'reason keeps the bare stderr' );
  is( run_with( edit_file => exit2('no edits') )->deny_message, 'PreToolUse:Edit hook error: no edits', 'raider tool names map to Claude\'s' );
  is( run_with( 'mcp__x__y' => exit2('no') )->deny_message, 'PreToolUse:mcp__x__y hook error: no', 'an MCP tool keeps its name' );
};

subtest 'JSON deny: the reason as it stands' => sub {
  my $r = run_with( bash => deny_json('never touch .env') );
  is( $r->decision, 'deny', 'denied' );
  is( $r->deny_message, 'never touch .env', 'no prefix' );
};

subtest 'no reason at all' => sub {
  is( run_with( bash => exit2() )->deny_message, 'PreToolUse:Bash hook blocked the tool call', 'exit 2 without stderr' );
  is( run_with( bash => deny_json() )->deny_message, 'PreToolUse:Bash hook blocked the tool call', 'JSON deny without a reason' );
};

subtest 'several denying hooks: one line each, in order; allow and ask say nothing' => sub {
  my $r = run_with( bash => exit2('first'), deny_json('second'), answer({ hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'allow' } }) );
  is( $r->deny_messages, [ 'PreToolUse:Bash hook error: first', 'second' ], 'both denials' );
  my $ask = run_with( bash => answer({ hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'ask', permissionDecisionReason => 'sure?' } }) );
  is( $ask->decision, 'ask', 'ask' );
  is( $ask->deny_message, undef, 'no deny message' );
};

done_testing;
