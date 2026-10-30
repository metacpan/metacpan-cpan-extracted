#!/usr/bin/env perl
# ABSTRACT: send_message: deliver to a running agent, resume a finished one, find one of an earlier process (ADR 0027 §5, k161)
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
use Path::Tiny;
use Test::Raider::MockAI qw( mock_app );
use Test::Raider::SlowAI qw( slow_app );

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

my @roots;
sub root { my $dir = Path::Tiny->tempdir; push @roots, $dir; $dir->realpath }

sub collect { my ( $list ) = @_; return sub { my ( $type, %p ) = @_; push @$list, { type => $type, %p } } }

sub text_of { my ( $m ) = @_; my $c = $m->{content}; ref $c ? join( '', map { $_->{text} // '' } @$c ) : $c // '' }

sub results_of { my ( $app, $name ) = @_; [ map { $_->{result} } grep { $_->{tool_call}->name eq $name } @{ $app->mock_engine->results } ] }

sub conversation {
  my ( $request ) = @_;
  my @out;
  for my $m ( @{ $request->{messages} } ) {
    next if $m->{role} eq 'system';
    my $t = text_of($m);
    $t =~ s/\A\[situation\][^\n]*\n\n//;
    push @out, [ $m->{role}, $t ];
  }
  return \@out;
}

subtest 'a running agent gets the message before its next model request' => sub {
  my $app = slow_app(
    root      => ''.root(),
    sub_delay => 0.05,
    script    => [
      { tool_calls => [ [ agent => { description => 'Work', prompt => 'TASK', run_in_background => \1 } ] ] },
      { tool_calls => [ [ send_message => { to => 'agent_1', message => 'ALSO THIS', summary => 'one more thing' } ] ] },
      { text => 'main first' },
      { tool_calls => [ [ list_files => { path => '.' } ] ] },
      { text => 'agent done' },
      { text => 'main final' },
    ],
  );
  my $session = $app->create_session;
  is( $app->run_prompt( 'go', session => $session, wait_background => 1 )->{response}, 'main final', 'the run answers' );
  my ($sent) = @{ results_of( $app, 'send_message' ) };
  is( $sent->{content}[0]{text}, 'Message queued for delivery to agent_1 at its next tool round.', 'queued' );
  ok( !$sent->{isError}, 'not an error' );
  my $requests = $app->mock_engine->requests;
  is( conversation( $requests->[4] )->[-1], [ user => 'ALSO THIS' ], 'the agent\'s second request ends with the message' );
  is( conversation( $requests->[4] )->[-2][0], 'tool', 'after its tool results' );
  my ($child) = map { $_->{id} } $app->session_store->children_of( $session->id );
  my ($msg) = grep { $_->{type} eq 'message' && ( $_->{content} // '' ) eq 'ALSO THIS' } @{ $app->session_store->read($child)->events };
  ok( $msg && !$msg->{notification}, 'journaled in the agent\'s session as a plain user message' );
};

subtest 'a message that comes after the last request: the agent goes on with it before it ends' => sub {
  my $app = slow_app(
    root      => ''.root(),
    sub_delay => 0.05,
    script    => [
      { tool_calls => [ [ agent => { description => 'Work', prompt => 'TASK', run_in_background => \1 } ] ] },
      { tool_calls => [ [ send_message => { to => 'agent_1', message => 'LATE' } ] ] },
      { text => 'main first' },
      { text => 'agent first' },
      { text => 'agent second' },
      { text => 'main final' },
    ],
  );
  $app->run_prompt( 'go', wait_background => 1 );
  my $requests = $app->mock_engine->requests;
  is( [ @{ conversation( $requests->[4] ) }[ -3 .. -1 ] ], [ [ user => 'TASK' ], [ assistant => 'agent first' ], [ user => 'LATE' ] ],
    'the next raid of the agent' );
  like( text_of( $requests->[5]{messages}[-1] ), qr{<result>agent second</result>}, 'its last answer is the report' );
};

subtest 'a finished agent is resumed in the background with its history' => sub {
  my @events;
  my $app = mock_app(
    root     => ''.root(),
    on_event => collect( \@events ),
    script   => [
      { tool_calls => [ [ agent => { description => 'Look', prompt => 'TASK-1' } ] ] },
      { text => 'first report' },
      { tool_calls => [ [ send_message => { to => 'agent_1', message => 'FOLLOW UP' } ] ] },
      { text => 'main first' },
      { text => 'second report' },
      { text => 'main final' },
    ],
  );
  my $session = $app->create_session;
  is( $app->run_prompt( 'go', session => $session, wait_background => 1 )->{response}, 'main final', 'the run answers' );
  my ($sent) = @{ results_of( $app, 'send_message' ) };
  is( $sent->{content}[0]{text}, 'Resuming agent agent_1 in the background. You will be notified when it finishes.', 'resuming' );
  my $requests = $app->mock_engine->requests;
  is( [ @{ conversation( $requests->[4] ) } ], [ [ user => 'TASK-1' ], [ assistant => 'first report' ], [ user => 'FOLLOW UP' ] ],
    'the resumed agent has its history and the message' );
  like( text_of( $requests->[5]{messages}[-1] ),
    qr{\A<task-notification>\n<task-id>agent_1</task-id>\n<tool-use-id>c2</tool-use-id>\n<status>completed</status>\n<summary>Agent "Look" finished</summary>\n<result>second report</result>},
    'a notification follows, naming the send_message call' );

  my @started = grep { $_->{type} eq 'agent.started' } @events;
  is( scalar @started, 2, 'agent.started for each run' );
  like( $started[1], { agent_id => 'agent_1', background => T(), resumed => T(), call => 'c2', session => $started[0]{session} },
    'the second one resumed, in the same child session' );
  my $child = $app->session_store->read( $started[0]{session} );
  is( [ map { [ $_->{run}, $_->{status}, $_->{response} ] } @{ $child->runs } ],
    [ [ r1 => completed => 'first report' ], [ r2 => completed => 'second report' ] ], 'a new run in the same child session' );
  like( $app->tasks->get('agent_1'), { status => 'completed', background => T(), recipient => 'main', report => 'second report' },
    'the registry entry' );
};

subtest 'names: the newest agent of a name wins' => sub {
  my $app = slow_app(
    root      => ''.root(),
    sub_delay => 30,
    script    => [
      { tool_calls => [
        [ agent => { description => 'a', prompt => 'A', name => 'rev', run_in_background => \1 } ],
        [ agent => { description => 'b', prompt => 'B', name => 'rev', run_in_background => \1 } ],
        [ send_message => { to => 'rev', message => 'hi' } ],
      ] },
      { text => 'done' },
    ],
  );
  $app->run('go');
  is( results_of( $app, 'send_message' )->[0]{content}[0]{text}, 'Message queued for delivery to agent_2 at its next tool round.',
    'agent_2, the newer one' );
  is( $app->tasks->pending('agent_2'), 1, 'queued for it' );
  $app->stop_background;
};

subtest 'errors' => sub {
  my $app = mock_app(
    root   => ''.root(),
    script => [
      { tool_calls => [ [ send_message => { to => 'nope', message => 'x' } ] ] },
      { tool_calls => [ [ send_message => { to => 'bash_1', message => 'x' } ] ] },
      { text => 'ok' },
    ],
  );
  $app->tasks->add( id => 'bash_1', kind => 'bash', status => 'completed' );
  $app->run('go');
  my @r = @{ results_of( $app, 'send_message' ) };
  ok( $r[0]{isError} && $r[1]{isError}, 'error results' );
  is( $r[0]{content}[0]{text}, 'No agent found with ID or name: nope', 'unknown' );
  is( $r[1]{content}[0]{text}, 'bash_1 is a background shell, not an agent; read it with bash_output.', 'a shell' );
};

subtest 'one-shot agents cannot be continued' => sub {
  my $app = mock_app(
    root   => ''.root(),
    script => [
      { tool_calls => [ [ agent => { description => 'x', prompt => 'y', subagent_type => 'Explore' } ] ] },
      { text => 'found' },
      { tool_calls => [ [ send_message => { to => 'agent_1', message => 'more' } ] ] },
      { text => 'ok' },
    ],
  );
  skip_all 'no Explore built-in in this tree' unless $app->context->agent_catalog->find('Explore');
  $app->run('go');
  my ($r) = @{ results_of( $app, 'send_message' ) };
  ok( $r->{isError}, 'an error' );
  is( $r->{content}[0]{text}, 'Agent agent_1 (Explore) is one-shot and cannot be continued.', 'says why' );
};

subtest 'an agent of an earlier process is found in the child sessions and resumed' => sub {
  my $root = root();
  my $first = mock_app(
    root   => "$root",
    script => [ { tool_calls => [ [ agent => { description => 'Look', prompt => 'OLD TASK', name => 'scout' } ] ] }, { text => 'old report' }, { text => 'bye' } ],
  );
  my $session = $first->create_session;
  $first->run_prompt( 'go', session => $session );
  my $id = $session->id;
  $session->release;
  undef $first;

  my @events;
  my $app = mock_app(
    root     => "$root",
    on_event => collect( \@events ),
    script   => [
      { tool_calls => [ [ send_message => { to => 'scout', message => 'AND NOW' } ] ] },
      { text => 'main first' },
      { text => 'new report' },
      { tool_calls => [ [ agent => { description => 'Other', prompt => 'NEW' } ] ] },
      { text => 'other report' },
      { text => 'main final' },
    ],
  );
  my $again = $app->open_session($id);
  $app->replay_session($again);
  is( $app->run_prompt( 'continue', session => $again, wait_background => 1 )->{response}, 'main final', 'the run answers' );
  my ($sent) = @{ results_of( $app, 'send_message' ) };
  is( $sent->{content}[0]{text}, 'Resuming agent agent_1 in the background. You will be notified when it finishes.',
    'found by its name in the child sessions' );
  my $requests = $app->mock_engine->requests;
  is( conversation( $requests->[2] ), [ [ user => 'OLD TASK' ], [ assistant => 'old report' ], [ user => 'AND NOW' ] ],
    'its history replayed' );
  like( text_of( $requests->[3]{messages}[-1] ), qr{<task-id>agent_1</task-id>.*<summary>Agent "Look" finished</summary>\n<result>new report</result>}s,
    'notified with the description of its first start' );
  like( results_of( $app, 'agent' )->[0]{content}[0]{text}, qr/\Aother report\nagentId: agent_2 /,
    'a new agent does not take the old agent\'s ID' );
  my ($child) = grep { ( $_->{created}{agent_id} // '' ) eq 'agent_1' } $app->session_store->children_of($id);
  is( [ map { $_->{run} } @{ $app->session_store->read( $child->{id} )->runs } ], [qw( r1 r2 )], 'a second run in its session' );
};

subtest 'an agent with the caller\'s MCP tools: views of the same connection, resumed and ended without touching it (ADR 0029 §11)' => sub {
  my $home = path( $ENV{HOME} );
  my $server = path(__FILE__)->absolute->parent->child( 'lib', 'mcp-test-server.pl' )->stringify;
  $home->child('.raider')->mkpath;
  $home->child( '.raider', 'config.yml' )->spew_utf8("mcp:\n  t:\n    command: \"$^X\"\n    args: [ \"$server\", \"normal\" ]\n");
  my $root = root();
  $root->child('.raider/agents/reader.md')->touchpath->spew_utf8("---\nname: reader\ndescription: Reads\ntools: Read, mcp__t__echo_env\n---\nYou read.\n");
  my $app = slow_app(
    root            => "$root",
    permission_mode => 'bypassPermissions',
    delay           => 0.2,
    script          => [
      { tool_calls => [ [ agent => { description => 'Look', prompt => 'Ask the server.', subagent_type => 'reader' } ] ] },
      { tool_calls => [ [ mcp__t__echo_env => { name => 'HOME' } ] ] },
      { text => 'first look' },
      { tool_calls => [ [ send_message => { to => 'agent_1', message => 'Again.' } ] ] },
      { tool_calls => [ [ mcp__t__echo_env => { name => 'HOME' } ] ] },
      { text => 'second look' },
      { text => 'sent' },
      { tool_calls => [ [ mcp__t__echo_env => { name => 'HOME' } ] ] },
      { text => 'done' },
    ],
  );
  my $out = $app->run_prompt( 'go', wait_background => 1 );
  is( $out->{status}, 'completed', 'completed' ) or diag $out->{error};
  is( $out->{response}, 'done', 'the main run answers last' );
  my $echo = results_of( $app, 'mcp__t__echo_env' );
  is( scalar @$echo, 3, 'three calls: the agent, the resumed agent, the main run' );
  ok( !( grep { $_->{isError} } @$echo ), 'none failed' ) or diag explain $echo;
  like( [ map { $_->{content}[0]{text} } @$echo ], [ qr/\AHOME=/, qr/\AHOME=/, qr/\AHOME=/ ], 'each answered by the server' );
  my ($client) = @{ $app->configured_mcp->clients };
  is( $client->status, 'connected', 'the application\'s connection is still up after the agent ended twice' );
  ok( $client->pid, 'one server process, still running' );
  like( $app->tasks->get('agent_1'), { status => 'completed', report => 'second look' }, 'the agent ended' );
  my $sub = $app->tasks->get('agent_1')->{subagent};
  my @views = grep { $_->isa('Langertha::Raider::MCP::View') } @{ $sub->_mcps };
  is( scalar @views, 1, 'the agent has a view of it' );
  my %offered = map { ( $_->{function}{name} // $_->{name} // '' ) => 1 } @{ $app->mock_engine->requests->[1]{tools} // [] };
  ok( $offered{mcp__t__echo_env} && !$offered{mcp__t__with_dot}, 'the agent is offered the MCP tool its file names, not the others' );
  $app->shutdown_mcp if $app->can('shutdown_mcp');
};

done_testing;
