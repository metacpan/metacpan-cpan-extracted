#!/usr/bin/env perl
# ABSTRACT: The REPL and background subagents: the loop runs at the prompt, notification turns, reminders, the end of input (ADR 0027 §3, §4, k161)
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
use IO::Handle;
use Path::Tiny;
use Test::Raider::MockAI ();
use Test::Raider::SlowAI ();
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::REPL;
use Langertha::Raider::Loadguard;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

# The raider CLI on the scripted mock model of Test::Raider::SlowAI.
package My::CLI {
  use Moose;
  extends 'Langertha::Raider::CLI';
  has script    => ( is => 'ro', default => sub { [] } );
  has delay     => ( is => 'ro', default => 0 );
  has sub_delay => ( is => 'ro', default => 0 );
  has usage     => ( is => 'ro' );
  sub mock_engine { $_[0]->_engine }
  sub _build_engine { Test::Raider::SlowAI::App::_build_engine(@_) }
  sub build_subagent_engine { Test::Raider::SlowAI::App::build_subagent_engine(@_) }
  __PACKAGE__->meta->make_immutable;
}

package main;

my @roots;
sub root { my $dir = Path::Tiny->tempdir; push @roots, $dir; $dir->realpath }

sub cli {
  return My::CLI->new(
    root => ''.root(), engine => 'openai', api_key => 'mock', trace => 0, detect => 0,
    loadguard => Langertha::Raider::Loadguard->new( env => { LOADGUARD_THROTTLE => 0 } ),
    @_,
  );
}

sub text_of { my ( $m ) = @_; my $c = $m->{content}; ref $c ? join( '', map { $_->{text} // '' } @$c ) : $c // '' }

# A REPL on the read end of a pipe; returns it, the write end and a reader
# of what it printed.
sub repl {
  my ( $app, %o ) = @_;
  pipe my $r, my $w or die $!;
  $w->autoflush(1);
  my $out = '';
  open my $fh, '>', \$out or die $!;
  my $repl = Langertha::Raider::CLI::REPL->new(
    app => $app, in => $r, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ),
    session_store => $app->session_store, %o,
  );
  return ( $repl, $w, sub { $out } );
}

subtest 'piped input ends: the REPL waits for the background agent and delivers its notification' => sub {
  my $app = cli( script => [
    { tool_calls => [ [ agent => { description => 'Later', prompt => 'BG', run_in_background => \1 } ] ] },
    { text => 'first answer' },
    { text => 'BG REPORT' },
    { text => 'after the note' },
  ] );
  my ( $repl, $w, $out ) = repl($app);
  print {$w} "go\n";
  close $w;
  $repl->run;
  like( $out->(), qr/first answer.*^background agent agent_1 finished\n.*after the note/ms, 'the notification turn after the end of input' );
  like( text_of( $app->mock_engine->requests->[3]{messages}[-1] ), qr{\A<task-notification>\n<task-id>agent_1</task-id>.*<result>BG REPORT</result>}s,
    'its message is the notification' );
  my $runs = $app->session_store->read( $repl->session->id )->runs;
  is( scalar @$runs, 2, 'two runs' );
  like( $runs->[1], { prompt => qr/\A<task-notification>/, response => 'after the note', status => 'completed' }, 'the second delivers it' );
  my ($note) = grep { $_->{type} eq 'message' && $_->{run} eq 'r2' && $_->{role} eq 'user' } @{ $app->session_store->read( $repl->session->id )->events };
  ok( $note->{notification}, 'journaled with notification 1' );
};

subtest 'idle at the prompt: the loop runs, and the notification starts a turn of its own' => sub {
  my $w;
  my $app = cli(
    script => [
      { tool_calls => [ [ agent => { description => 'Later', prompt => 'BG', run_in_background => \1 } ] ] },
      { text => 'first answer' },
      { text => 'BG REPORT' },
      { text => 'after the note' },
    ],
    # The input stays open until the notification turn has answered.
    on_event => sub { my ( $type, %p ) = @_; close $w if $w && $type eq 'message' && ( $p{content} // '' ) eq 'after the note' },
  );
  ( my $repl, $w, my $out ) = repl($app);
  print {$w} "go\n";
  $repl->run;
  like( $out->(), qr/first answer.*^background agent agent_1 finished\n.*after the note/ms, 'the agent finished while the REPL waited' );
  is( scalar @{ $app->mock_engine->requests }, 4, 'go, the agent, the notification turn' );
};

subtest 'a line submitted while notifications wait: they go in front of it, as reminders' => sub {
  my $app = cli(
    delay  => 0.05,
    script => [
      { tool_calls => [ [ agent => { description => 'Fast', prompt => 'BG', run_in_background => \1 } ] ] },
      { text => 'BG REPORT' },     # the agent, while the main run waits for its model
      { text => 'first answer' },  # ends the run; the notification came too late for it
      { text => 'second answer' },
    ],
  );
  my ( $repl, $w, $out ) = repl($app);
  print {$w} "go\nnext\n";
  close $w;
  $repl->run;
  my $last = text_of( $app->mock_engine->requests->[3]{messages}[-1] );
  $last =~ s/\A\[situation\][^\n]*\n\n//;
  like( $last, qr{\A<system-reminder>\n\[SYSTEM NOTIFICATION - NOT USER INPUT\]\nThis is an automated background-task event, NOT a message from the user\. It is delivered in the same turn as a genuine message from the user}, 'Claude Code\'s same-turn wrapper first' );
  like( $last, qr{\n\n<task-notification>\n<task-id>agent_1</task-id>.*</task-notification>\n</system-reminder>\n\nnext\z}s, 'then the line' );
  like( $out->(), qr/first answer.*^background agent agent_1 finished\n.*second answer/ms, 'the meta line before the turn' );
  my $journal = $app->session_store->read( $repl->session->id );
  is( $journal->runs->[1]{prompt}, 'next', 'the run\'s prompt is the line' );
  is( [ map { [ $_->{notification} ? 1 : 0, $_->{content} =~ /\A<system-reminder>/ ? 'reminder' : $_->{content} ] }
        grep { $_->{type} eq 'message' && $_->{run} eq 'r2' && $_->{role} eq 'user' } @{ $journal->events } ],
    [ [ 1, 'reminder' ], [ 0, 'next' ] ], 'journaled: the reminders as a notification, then the line' );
};

subtest 'a /command submitted while notifications wait: they go in front of its prompt too (ADR 0030)' => sub {
  my $app = cli(
    delay  => 0.05,
    script => [
      { tool_calls => [ [ agent => { description => 'Fast', prompt => 'BG', run_in_background => \1 } ] ] },
      { text => 'BG REPORT' },
      { text => 'first answer' },
      { text => 'greeted' },
    ],
  );
  my $root = path( $app->root );
  $root->child('CLAUDE.md')->spew_utf8("Project.\n");
  $root->child('.claude/commands/greet.md')->touchpath->spew_utf8("---\ndescription: Greets.\n---\nSay hello to \$ARGUMENTS. GREET-CMD\n");
  my ( $repl, $w, $out ) = repl($app);
  print {$w} "go\n/greet Alice\n";
  close $w;
  $repl->run;
  my $last = text_of( $app->mock_engine->requests->[3]{messages}[-1] );
  like( $last, qr{<system-reminder>\n\[SYSTEM NOTIFICATION - NOT USER INPUT\].*<task-id>agent_1</task-id>.*</system-reminder>\n\n.*Say hello to Alice\. GREET-CMD}s,
    'the reminders, then the command\'s prompt' );
  like( $out->(), qr/^background agent agent_1 finished\n.*greeted/ms, 'with the meta line' );
  is( $app->notifications_pending, 0, 'nothing left waiting' );
};

for my $command (qw( /clear /reset /new )) {
  subtest $command.' stops the background agents quietly; a background shell goes on and notifies' => sub {
    my $w;
    my $app = cli(
      permission_mode => 'bypassPermissions',
      sub_delay       => 30,
      script          => [
        { tool_calls => [
          [ agent => { description => 'Slow', prompt => 'BG', run_in_background => \1 } ],
          [ bash  => { command => 'sleep 2', description => 'Nap', run_in_background => \1 } ],
        ] },
        { text => 'first answer' },
        { text => 'noted the nap' },
      ],
      # The input stays open until the shell's notification turn has answered.
      on_event => sub { my ( $type, %p ) = @_; close $w if $w && $type eq 'message' && ( $p{content} // '' ) eq 'noted the nap' },
    );
    ( my $repl, $w, my $out ) = repl($app);
    print {$w} "go\n$command\n";
    my $t0 = time;
    $repl->run;
    ok( time - $t0 < 10, 'without waiting for the agent\'s model' );
    like( $app->tasks->get('agent_1'), { status => 'killed', quiet => T() }, 'the agent was stopped' );
    unlike( $out->(), qr/background agent agent_1/, 'and nothing was delivered for it' );
    like( $out->(), qr/history cleared\..*^background shell bash_1 completed\n.*noted the nap/ms, 'the shell notified after the clear' );
    my $last = text_of( $app->mock_engine->requests->[-1]{messages}[-1] );
    like( $last, qr{<task-id>bash_1</task-id>.*<summary>Background command "Nap" completed \(exit code 0\)</summary>}s, 'its notification' );
    unlike( $last, qr{agent_1}, 'without the agent' );
  };
}

subtest '/quit stops the background agents' => sub {
  my $app = cli(
    sub_delay => 30,
    script    => [
      { tool_calls => [ [ agent => { description => 'Slow', prompt => 'BG', run_in_background => \1 } ] ] },
      { text => 'first answer' },
    ],
  );
  my ( $repl, $w ) = repl($app);
  print {$w} "go\n/quit\n";
  close $w;
  my $t0 = time;
  $repl->run;
  ok( time - $t0 < 10, 'without waiting for the agent\'s model' );
  is( $app->tasks->get('agent_1')->{status}, 'killed', 'the agent was stopped' );
};

subtest 'read_line: the prompt, a line, the end; notifications only while nothing is typed' => sub {
  my $app = cli();
  my ( $repl, $w, $out ) = repl($app);
  my $in = $repl->in;
  print {$w} "hello\n";
  is( $repl->read_line( $in, 'raider> ' ), "hello\n", 'a line, as read' );
  is( $out->(), 'raider> ', 'after the prompt' );

  $app->tasks->notify( main => 'N', id => 'agent_9', label => 'x' );
  is( $repl->read_line( $in, 'raider> ' ), \'notifications', 'nothing typed, a notification due: a turn' );
  is( $out->(), "raider> raider> \n", 'the prompt line is ended' );

  print {$w} "par";
  my $timer = $app->loop->delay_future( after => 0.1 )->on_done( sub { print {$w} "tial\n" } );
  is( $repl->read_line($in), "partial\n", 'started typing: the line, not the notification' );
  is( $app->notifications_pending, 1, 'which still waits' );
  $app->take_notifications;

  my $later = $app->loop->delay_future( after => 0.1 )->on_done( sub { $app->tasks->notify( main => 'M' ) } );
  is( $repl->read_line($in), \'notifications', 'the loop ran while it waited, and the notification ended the wait' );
  $app->take_notifications;

  print {$w} "last line";
  close $w;
  is( $repl->read_line($in), 'last line', 'a last line without a newline' );
  is( $repl->read_line($in), undef, 'then the end' );
};

# Stands in for Term::ReadLine::Gnu, which is not installed everywhere: its
# callback interface over a handle, one character per callback_read_char.
package Fake::Term {
  sub new { my ( $class, $in ) = @_; bless { in => $in, buffer => '', attribs => { line_buffer => '' } }, $class }
  sub Attribs { $_[0]{attribs} }
  sub callback_handler_install { my ( $self, $ps, $cb ) = @_; $self->{cb} = $cb; $self->{installs}++; return }
  sub callback_handler_remove { delete $_[0]{cb}; $_[0]{removes}++; return }
  sub callback_read_char {
    my ( $self ) = @_;
    my $n = sysread $self->{in}, my $char, 1;
    my $cb = $self->{cb} or return;
    return $cb->(undef) unless $n;
    if ( $char eq "\n" ) {
      my $line = $self->{attribs}{line_buffer};
      $self->{attribs}{line_buffer} = '';
      return $cb->($line);
    }
    $self->{attribs}{line_buffer} .= $char;
    return;
  }
}

package main;

subtest 'the Term::ReadLine::Gnu callback reader' => sub {
  my $app = cli();
  my ( $repl, $w, $out ) = repl($app);
  my $term = Fake::Term->new( $repl->in );
  my $read = $repl->_callback_reader( $term, 'raider> ' );
  print {$w} "one\n";
  is( $read->(), 'one', 'a line, fed character by character from the loop' );
  is( $term->{installs}, 1, 'the handler was installed' );
  ok( !$term->{cb}, 'and removed with the line' );

  $app->tasks->notify( main => 'N' );
  is( $read->(), \'notifications', 'nothing typed, a notification due: a turn' );
  ok( !$term->{cb}, 'the handler removed for it' );
  $app->take_notifications;

  print {$w} "ty";
  my $timer = $app->loop->delay_future( after => 0.1 )->on_done( sub { $app->tasks->notify( main => 'N' ); print {$w} "ped\n" } );
  is( $read->(), 'typed', 'once something is typed the line comes first' );
  $app->take_notifications;

  close $w;
  is( $read->(), undef, 'the end of input' );
};

done_testing;
