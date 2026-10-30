#!/usr/bin/env perl
# ABSTRACT: Hooks and permission rules see the new Claude Code names: MultiEdit, TaskStop, the task tools, EnterPlanMode (ADR 0025)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use IO::Async::Loop;
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Raider::Hooks;
use Langertha::Raider::Permissions::Rule;

# Fake hooks are small sh scripts in a temp dir; HOME and CLAUDE_CONFIG_DIR
# point at temp dirs, so the real ~/.claude is never read.
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
# A hook that keeps its stdin in $file and prints a JSON answer.
sub answer {
  my ( $file, $data ) = @_;
  return script( 'cat > "'.$file.'"'."\nprintf '%s' '".$json->encode($data)."'" );
}
sub group { my ( $matcher, $cmd ) = @_; { matcher => $matcher, hooks => [ { type => 'command', command => $cmd } ], source => 'test', plugin => undef } }
sub runner { Langertha::Raider::Hooks->new( loop => $loop, root => "$root", @_ ) }

subtest 'a hook on Edit|MultiEdit gets multi_edit as MultiEdit and its updatedInput comes back' => sub {
  my $seen  = $bin->child('multi.json');
  my $edits = [ { old_string => 'a', new_string => 'b' }, { old_string => 'c', new_string => 'd', replace_all => JSON::MaybeXS->true } ];
  my $hook  = answer( "$seen", { hookSpecificOutput => { hookEventName => 'PreToolUse', permissionDecision => 'allow',
    updatedInput => { file_path => "$root/lib/A.pm", edits => [ { old_string => 'a', new_string => 'B' } ] } } } );
  my $r = runner( groups => { PreToolUse => [ group( 'Edit|MultiEdit', $hook ) ] } )
    ->run( PreToolUse => { tool_name => 'multi_edit', tool_input => { path => 'lib/A.pm', edits => $edits } } );
  is( scalar( grep { $_->{outcome} ne 'skipped' } @{ $r->runs } ), 1, 'the matcher matches' );
  my $in = $json->decode( $seen->slurp_raw );
  is( $in->{tool_name}, 'MultiEdit', 'tool_name is the Claude name' );
  is( $in->{tool_input}, { file_path => "$root/lib/A.pm", edits => $edits },
    'tool_input in Claude form, file_path absolute as Claude Code hands it, the edits as they are' );
  is( $r->updated_input, { path => 'lib/A.pm', edits => [ { old_string => 'a', new_string => 'B' } ] },
    'updatedInput back in raider form; the unchanged absolute path is the relative one again' );

  my $edit_only = runner( groups => { PreToolUse => [ group( 'Edit', answer( "$bin/x.json", {} ) ) ] } )
    ->run( PreToolUse => { tool_name => 'multi_edit', tool_input => { path => 'a', edits => [] } } );
  is( scalar( grep { $_->{outcome} ne 'skipped' } @{ $edit_only->runs } ), 0, 'a matcher Edit alone does not match MultiEdit' );
};

subtest 'kill_shell is TaskStop to a hook, task_create TaskCreate' => sub {
  my $seen = $bin->child('stop.json');
  my $hook = answer( "$seen", { hookSpecificOutput => { hookEventName => 'PreToolUse', updatedInput => { task_id => 'bash_2' } } } );
  my $r = runner( groups => { PreToolUse => [ group( 'TaskStop', $hook ) ] } )
    ->run( PreToolUse => { tool_name => 'kill_shell', tool_input => { shell_id => 'bash_1' } } );
  my $in = $json->decode( $seen->slurp_raw );
  is( [ $in->{tool_name}, $in->{tool_input} ], [ 'TaskStop', { task_id => 'bash_1' } ], 'TaskStop with task_id' );
  is( $r->updated_input, { shell_id => 'bash_2' }, 'task_id back to shell_id' );

  my $out = $bin->child('output.json');
  my $wait = answer( "$out", { hookSpecificOutput => { hookEventName => 'PreToolUse', updatedInput => { task_id => 'bash_1', timeout => 5000 } } } );
  $r = runner( groups => { PreToolUse => [ group( 'TaskOutput', $wait ) ] } )
    ->run( PreToolUse => { tool_name => 'bash_output', tool_input => { bash_id => 'bash_1' } } );
  is( $json->decode( $out->slurp_raw ), hash { field tool_name => 'TaskOutput';
    field tool_input => { task_id => 'bash_1', block => F() }; etc },
    'bash_output is TaskOutput; raider does not wait, so block false' );
  is( $r->updated_input, { bash_id => 'bash_1', timeout => 5, block => T() },
    "a TaskOutput updatedInput: seconds, and TaskOutput's default block true" );

  my $task = $bin->child('task.json');
  runner( groups => { PreToolUse => [ group( 'Task.*', answer( "$task", {} ) ) ] } )
    ->run( PreToolUse => { tool_name => 'task_create', tool_input => { subject => 's', description => 'd' } } );
  is( $json->decode( $task->slurp_raw )->{tool_name}, 'TaskCreate', 'TaskCreate' );
};

subtest 'permission rules under the new Claude names' => sub {
  my $rule = sub { Langertha::Raider::Permissions::Rule->new( text => $_[0], kind => 'deny', source => 'test' ) };
  is( $rule->('TaskCreate')->tools, ['task_create'], 'TaskCreate' );
  is( $rule->('TaskStop')->tools, ['kill_shell'], 'TaskStop' );
  is( $rule->('KillShell')->tools, ['kill_shell'], 'KillShell, the older name' );
  is( $rule->('EnterPlanMode')->tools, ['enter_plan_mode'], 'EnterPlanMode' );
  is( $rule->('TaskOutput')->tools, ['bash_output'], 'TaskOutput' );
  is( $rule->('BashOutput')->tools, ['bash_output'], 'BashOutput, the older name' );
  ok( !$rule->('NotebookEdit')->is_valid, 'NotebookEdit names no raider tool: an invalid rule, never a guess' );
};

done_testing;
