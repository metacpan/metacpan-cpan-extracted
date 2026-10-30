#!/usr/bin/env perl
# ABSTRACT: kill_shell and bash_output reach agents, background shells notify through the registry, a cancelled turn spares a background agent's command (ADR 0027 §4, §10, k161)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use IO::Async::Loop;
use JSON::MaybeXS ();
use Path::Tiny;
use Time::HiRes ();
use Langertha::Raider::BashTools;
use Langertha::Raider::Tasks;
use Test::Raider::Env qw( clear_engine_env );
use Test::Raider::SlowAI qw( slow_app );
use Test::Raider::StubEngine qw( stub_engine );

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};
clear_engine_env();

my $repo = path(__FILE__)->absolute->parent->parent;

# Each root lives as long as the test does.
my @roots;
sub root { my $dir = Path::Tiny->tempdir; push @roots, $dir; $dir->realpath }

sub app { slow_app( root => ''.root(), permission_mode => 'bypassPermissions', @_ ) }

sub text_of { my ( $m ) = @_; my $c = $m->{content}; ref $c ? join( '', map { $_->{text} // '' } @$c ) : $c // '' }

# The result texts of the calls named $name, in the order they came back.
sub texts_of {
  my ( $app, $name ) = @_;
  return [ map { $_->{result}{content}[0]{text} } grep { $_->{tool_call}->name eq $name } @{ $app->mock_engine->results } ];
}

# Every user message text of every request, in order.
sub user_texts {
  my ( $app ) = @_;
  return [ map { text_of($_) } grep { $_->{role} eq 'user' } map { @{ $_->{messages} } } @{ $app->mock_engine->requests } ];
}

# Lets the loop run until $done is true, at most $seconds.
sub spin {
  my ( $app, $done, $seconds ) = @_;
  my $until = Time::HiRes::time() + ( $seconds // 10 );
  $app->loop->loop_once(0.02) while !$done->() && Time::HiRes::time() < $until;
  return $done->();
}

subtest 'kill_shell stops a running background agent; its notification says so' => sub {
  my $app = app(
    delay     => 0.05,
    sub_delay => 30,
    script    => [
      { tool_calls => [ [ agent => { description => 'Slow work', prompt => 'P', run_in_background => \1, name => 'slowpoke' } ] ] },
      { tool_calls => [ [ kill_shell => { shell_id => 'slowpoke' } ] ] },
      { tool_calls => [ [ kill_shell => { shell_id => 'agent_1' } ], [ kill_shell => { shell_id => 'agent_9' } ] ] },
      { text => 'done' },
    ],
  );
  my $outcome = $app->run_prompt( 'go', wait_background => 1 );
  is( $outcome->{response}, 'done', 'the run answers' );
  is( texts_of( $app, 'kill_shell' ), [
    'Successfully stopped task: agent_1 (Slow work)',
    'Task agent_1 is not running (status: killed)',
    'No task found with ID: agent_9',
  ], 'stopped by name, then not running, unknown ID' );
  is( [ map { $_->{result}{isError} ? 1 : 0 } grep { $_->{tool_call}->name eq 'kill_shell' } @{ $app->mock_engine->results } ],
    [ 0, 1, 1 ], 'only the stop is no error' );
  my @notes = grep { /<task-notification>/ } @{ user_texts($app) };
  is( scalar @notes, 1, 'one notification' );
  like( $notes[0], qr{<task-id>agent_1</task-id>\n<tool-use-id>c1</tool-use-id>\n<status>killed</status>\n<summary>Agent "Slow work" was stopped</summary>},
    'killed, was stopped' );
  is( $app->tasks->get('agent_1')->{status}, 'killed', 'the registry says killed' );
};

subtest 'bash_output answers with an agent\'s status, and with block waits for its report' => sub {
  my $app = app(
    delay     => 0.05,
    sub_delay => 0.5,
    script    => [
      { tool_calls => [ [ agent => { description => 'Count', prompt => 'P', run_in_background => \1 } ] ] },
      { tool_calls => [ [ bash_output => { bash_id => 'agent_1' } ] ] },
      { tool_calls => [ [ bash_output => { bash_id => 'agent_1', block => \1, timeout => 20 } ] ] },
      { text => "THE REPORT\n" },
      { text => 'done' },
    ],
  );
  is( '' . $app->run('go'), 'done', 'the run answers' );
  is( texts_of( $app, 'bash_output' ), [
    '<status>running</status>',
    "<status>completed</status>\n\n<output>\nTHE REPORT\n</output>",
  ], 'running at first; block waited on the loop for the end and the report' );
};

subtest 'a background shell notifies the run that started it when it ends' => sub {
  my $app = app( delay => 0, script => [
    { tool_calls => [ [ bash => { command => 'sleep 0.2; exit 3', run_in_background => \1 } ] ] },
    { tool_calls => [ [ bash => { command => 'sleep 60', description => 'Long sleep', run_in_background => \1 } ] ] },
    { text => 'started' },
  ] );
  my $outcome = $app->run_prompt( 'go', wait_background => 1 );
  is( $outcome->{status}, 'completed', 'a run with background shells ends: nothing waits for them' );
  my $bash = texts_of( $app, 'bash' );
  is( $bash->[0], 'Command running in background with ID: bash_1. You will be notified when it completes. '
    .'Read its output and see whether it has finished with bash_output (bash_id: bash_1); stop it with kill_shell (shell_id: bash_1).',
    'the text says it will be notified' );
  like( $app->tasks->get('bash_2'), { kind => 'bash', status => 'running', recipient => 'main', tool_use_id => 'c2',
    description => 'Long sleep', background => T() }, 'the shell is in the registry' );

  ok( spin( $app, sub { $app->notifications_pending } ), 'the loop reaps it and the notification is due' );
  my ($item) = $app->take_notifications;
  is( $item->{text}, join( "\n",
    '<task-notification>',
    '<task-id>bash_1</task-id>',
    '<tool-use-id>c1</tool-use-id>',
    '<status>failed</status>',
    '<summary>Background command "sleep 0.2; exit 3" failed with exit code 3</summary>',
    '</task-notification>',
  ), 'failed with its exit code; the command stands in for the description' );
  is( $item->{label}, 'background shell bash_1 failed', 'the line a surface shows' );
  is( $app->tasks->get('bash_1')->{status}, 'failed', 'the registry says failed' );

  my ( $text ) = $app->bash_tools->kill_shell({ shell_id => 'bash_2' });
  is( $text, 'Successfully stopped task: bash_2 (sleep 60)', 'killed' );
  my @items = $app->take_notifications;
  is( scalar @items, 1, 'one notification for the kill' );
  like( $items[0]{text}, qr{<status>killed</status>\n<summary>Background command "Long sleep" was stopped</summary>}, 'was stopped' );
  $app->loop->loop_once(0.1);
  is( $app->notifications_pending, 0, 'and no second one when the loop sees it gone' );
};

subtest 'a non-interactive run does not wait for a background shell' => sub {
  my $app = app( delay => 0, script => [
    { tool_calls => [ [ bash => { command => 'sleep 30', run_in_background => \1 } ] ] },
    { text => 'left it running' },
  ] );
  my $t0 = Time::HiRes::time();
  my $outcome = $app->run_prompt( 'go', wait_background => 1 );
  ok( Time::HiRes::time() - $t0 < 10, 'the run ends at once' );
  is( $outcome->{response}, 'left it running', 'with its answer' );
  is( $app->background_running, 0, 'a shell is no background agent' );
  is( scalar( () = $app->bash_tools->background_pids ), 1, 'the shell still runs' );
  $app->bash_tools->stop_all;
};

subtest 'the one-shot CLI ends while its background shell runs, and stops it' => sub {
  my $root = Path::Tiny->tempdir;
  my $pidfile = $root->child('shell.pid');
  my ( $stub, $url ) = stub_engine( bash => { command => 'echo $$ > '.$pidfile.'; exec sleep 60', run_in_background => JSON::MaybeXS->true } );
  my $out = $root->child('out');
  my $pid = fork // die 'fork: '.$!;
  unless ($pid) {
    open STDIN,  '<', '/dev/null' or die $!;
    open STDOUT, '>', "$out"      or die $!;
    open STDERR, '>&', \*STDOUT   or die $!;
    exec $^X, '-I'.$repo->child('lib'), ''.$repo->child( 'bin', 'raider' ), '-r', "$root", '-e', 'openai', '-k', 'test',
      '-m', 'stub-model', '--no-trace', '--dangerously-skip-permissions', '-o', 'url='.$url, '--json', 'start it';
    die 'exec: '.$!;
  }
  my $t0 = Time::HiRes::time();
  {
    local $SIG{ALRM} = sub { kill KILL => $pid };
    alarm 60;
    waitpid $pid, 0;
    alarm 0;
  }
  my $status = $?;
  kill KILL => $stub;
  waitpid $stub, 0;
  is( $status, 0, 'raider exits 0' ) or diag $out->slurp_utf8;
  ok( Time::HiRes::time() - $t0 < 30, 'without waiting for the shell' );
  like( $out->slurp_utf8, qr/"status"\s*:\s*"completed"/, 'the run completed' );
  my $shell = -e $pidfile ? 0 + $pidfile->slurp : 0;
  ok( $shell, 'the shell had started' );
  ok( !( $shell && kill 0 => $shell ), 'and is gone with raider' );
};

subtest 'a subagent\'s background shell notifies the subagent while it runs' => sub {
  my $app = app( delay => 0, script => [
    { tool_calls => [ [ agent => { description => 'Build', prompt => 'P' } ] ] },
    { tool_calls => [ [ bash => { command => 'true', run_in_background => \1 } ] ] },
    { tool_calls => [ [ bash_output => { bash_id => 'bash_1', block => \1, timeout => 20 } ] ] },
    { text => 'built' },
    { text => 'done' },
  ] );
  is( '' . $app->run('go'), 'done', 'the run answers' );
  like( $app->tasks->get('bash_1'), { recipient => 'agent_1', tool_use_id => 'c1', status => 'completed' },
    'the subagent started it, with its own call id' );
  my $requests = $app->mock_engine->requests;
  my ($sub_last) = grep { grep { text_of($_) =~ /\n\nP\z/ } @{ $_->{messages} } } reverse @$requests;
  like( text_of( $sub_last->{messages}[-1] ), qr{\A<task-notification>\n<task-id>bash_1</task-id>\n<tool-use-id>c1</tool-use-id>\n<status>completed</status>\n<summary>Background command "true" completed \(exit code 0\)</summary>},
    'its notification reached the subagent' );
  ok( !( grep { /task-id>bash_1/ } map { text_of($_) } map { @{ $_->{messages} } } $requests->[-1] ), 'not the main run' );
  is( $app->notifications_pending, 0, 'nothing for the main conversation' );
};

subtest 'background_pids: a detached caller\'s foreground command belongs to the session' => sub {
  my $loop = IO::Async::Loop->new;
  my $tasks = Langertha::Raider::Tasks->new( loop => $loop );
  my $shell = Langertha::Raider::BashTools->new( loop => $loop, tasks => $tasks );
  for my $case ( [ 1, 'detached: kept' ], [ 0, 'attached: not kept' ] ) {
    my ( $detached, $label ) = @$case;
    my @seen;
    local $SIG{ALRM} = sub { @seen = $shell->background_pids };
    Time::HiRes::alarm(0.3);
    my ( $text ) = $shell->bash( { command => 'sleep 1; echo ok' }, { detached => $detached } );
    Time::HiRes::alarm(0);
    is( $text, 'ok', 'the command ran in the foreground' );
    is( scalar @seen, $detached ? 1 : 0, $label );
  }
  is( [ $tasks->entries ], [], 'a foreground command is no registry entry' );
};

subtest 'without the registry: no notification, the old texts' => sub {
  my $loop  = IO::Async::Loop->new;
  my $shell = Langertha::Raider::BashTools->new( loop => $loop );
  my ( $text ) = $shell->bash({ command => 'true', run_in_background => 1 });
  unlike( $text, qr/notified/, 'nothing promises a notification' );
  is( [ $shell->kill_shell({ shell_id => 'agent_1' }) ], [ 'No task found with ID: agent_1', 1 ], 'no agents either' );
  $shell->stop_all;
};

done_testing;
