#!/usr/bin/env perl
# ABSTRACT: The todo_write and ask_user tools, the REPL's way of asking, and the Application state they feed
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Langertha::Raider::TodoTools;
use Langertha::Raider::AskTools;
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::REPL;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

sub invoke {
  my ( $server, $name, $args ) = @_;
  my ($tool) = grep { $_->name eq $name } @{ $server->tools };
  return $tool->code->( $tool, $args );
}
sub text { $_[0]{content}[0]{text} }

subtest 'todo_write checks and stores the whole list' => sub {
  my @seen;
  my $todos = Langertha::Raider::TodoTools->new( on_update => sub { push @seen, $_[0] } );
  my $r = invoke( $todos->server, todo_write => { todos => [
    { content => 'Read the code', status => 'completed' },
    { content => 'Write the test', status => 'in_progress', activeForm => 'Writing the test' },
    { content => 'Fix it', status => 'pending' },
  ] } );
  ok( !$r->{isError}, 'accepted' );
  is( text($r), "Todo list updated: 1 completed, 1 in progress, 1 pending\n[x] Read the code\n[>] Write the test\n[ ] Fix it", 'the answer shows the list' );
  is( $seen[0], [
    { content => 'Read the code', status => 'completed',   activeForm => 'Read the code' },
    { content => 'Write the test', status => 'in_progress', activeForm => 'Writing the test' },
    { content => 'Fix it', status => 'pending', activeForm => 'Fix it' },
  ], 'on_update gets the list, activeForm defaults to the content' );

  my $empty = invoke( $todos->server, todo_write => { todos => [] } );
  is( text($empty), 'Todo list is empty.', 'an empty list clears' );
  is( $seen[1], [], 'and is reported' );
};

subtest 'a bad list is an error and changes nothing' => sub {
  my $calls = 0;
  my $server = Langertha::Raider::TodoTools->new( on_update => sub { $calls++ } )->server;
  my %bad = (
    'two in progress'  => [ { content => 'a', status => 'in_progress' }, { content => 'b', status => 'in_progress' } ],
    'unknown status'   => [ { content => 'a', status => 'doing' } ],
    'no content'       => [ { content => '  ', status => 'pending' } ],
    'not an object'    => ['a'],
  );
  my %want = (
    'two in progress' => qr/todo 2 is a second item in_progress \(todo 1 is\)/,
    'unknown status'  => qr/todo 1 has the status "doing", expected one of pending, in_progress, completed/,
    'no content'      => qr/todo 1 has no content/,
    'not an object'   => qr/todo 1 is not an object/,
  );
  for my $name ( sort keys %bad ) {
    my $r = invoke( $server, todo_write => { todos => $bad{$name} } );
    ok( $r->{isError}, "$name: error" );
    like( text($r), $want{$name}, "$name: says what is wrong" );
    unlike( text($r), qr/ at \S+ line \d+/, "$name: no source location" );
  }
  is( $calls, 0, 'on_update never called' );
  ok( invoke( $server, todo_write => { todos => 'x' } )->{isError}, 'not a list' );
};

subtest 'ask_user refuses plainly when nobody can answer' => sub {
  for my $ask ( Langertha::Raider::AskTools->new, Langertha::Raider::AskTools->new( answerer => sub { undef } ) ) {
    my $r = invoke( $ask->server, ask_user => { question => 'Which one?' } );
    ok( $r->{isError}, 'an error result' );
    like( text($r), qr/ask_user is not available: this run is not interactive, nobody can answer\. Decide yourself .* state your assumption/, 'the model is told what to do' );
  }
};

subtest 'ask_user puts the question to the person and returns the answer' => sub {
  my @asked;
  my $ask = Langertha::Raider::AskTools->new( answerer => sub { sub { push @asked, [@_]; 'blue' } } );
  my $r = invoke( $ask->server, ask_user => { question => 'Which colour?', options => [qw( red blue )] } );
  ok( !$r->{isError}, 'ok' );
  is( text($r), 'User answered: blue', 'the answer' );
  is( \@asked, [ [ 'Which colour?', [qw( red blue )] ] ], 'question and options' );
  invoke( $ask->server, ask_user => { question => 'Plain?' } );
  is( $asked[1], [ 'Plain?', [] ], 'no options: an empty list' );

  my $none = Langertha::Raider::AskTools->new( answerer => sub { sub { undef } } );
  my $r2 = invoke( $none->server, ask_user => { question => 'Anyone?' } );
  ok( $r2->{isError}, 'no answer is an error' );
  like( text($r2), qr/gave no answer/, 'says so' );
};

subtest 'the answerer is asked on every call' => sub {
  my $ready;
  my $ask = Langertha::Raider::AskTools->new( answerer => sub { $ready ? sub { 'late' } : undef } );
  ok( invoke( $ask->server, ask_user => { question => 'q' } )->{isError}, 'not ready: refused' );
  $ready = 1;
  is( text( invoke( $ask->server, ask_user => { question => 'q' } ) ), 'User answered: late', 'ready: answered' );
};

sub cli {
  my ( %arg ) = @_;
  return Langertha::Raider::CLI->new(
    root => tempdir( CLEANUP => 1 ), engine => 'openai', api_key => 'test', model => 'gpt-4o-mini', trace => 0, detect => 0,
    %arg,
  );
}

subtest 'the application keeps the list as run state and reports every change' => sub {
  # todo_write is the family of RAIDER_ENABLE_TASKS=0; the task tools: t/197.
  my $app = cli( task_tools => 0 );
  is( $app->todos, [], 'empty to begin with' );
  my @events;
  $app->begin_run( on_event => sub { push @events, [@_] } );
  my ($tool) = grep { $_->name eq 'todo_write' } $app->_mounted_tools;
  ok( $tool, 'the tool is mounted' );
  $tool->code->( $tool, { todos => [ { content => 'a', status => 'in_progress' }, { content => 'b', status => 'pending' } ] } );
  is( [ map { $_->{content}.'/'.$_->{status} } @{ $app->todos } ], [ 'a/in_progress', 'b/pending' ], 'todos holds the list' );
  my ($ev) = grep { $_->[0] eq 'todo.updated' } @events;
  ok( $ev, 'todo.updated event' );
  is( { @{$ev}[ 1 .. $#$ev ] }->{todos}[1]{content}, 'b', 'with the whole list' );
  $app->todos->[0]{content} = 'changed';
  is( $app->todos->[0]{content}, 'a', 'todos is a copy' );
  $app->end_run('completed');
  $app->begin_run;
  is( $app->todos, [], 'a new run starts with an empty list' );
  $app->end_run('completed');
};

subtest 'the application hands its on_ask_user to the tool, per call' => sub {
  my $app = cli();
  my ($tool) = grep { $_->name eq 'ask_user' } $app->_mounted_tools;
  ok( $tool, 'the tool is mounted' );
  my $r = $tool->code->( $tool, { question => 'x?' } );
  ok( $r->{isError}, 'no handler: refused' );
  $app->on_ask_user( sub { "re: $_[0]" } );
  is( text( $tool->code->( $tool, { question => 'x?' } ) ), 'User answered: re: x?', 'handler set later: used' );
  $app->on_ask_user(undef);
  ok( $tool->code->( $tool, { question => 'x?' } )->{isError}, 'cleared: refused again' );
};

subtest 'the REPL asks the person on its input' => sub {
  my $app = cli();
  my $run = sub {
    my ( $input, @ask ) = @_;
    open my $in, '<', \$input or die $!;
    my $out = '';
    open my $fh, '>', \$out or die $!;
    my $repl = Langertha::Raider::CLI::REPL->new(
      app => $app, in => $in, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ), can_ask => 1,
    );
    my $answer = $repl->ask_user(@ask);
    return ( $answer, $out );
  };
  my ( $a1, $o1 ) = $run->( "2\n", 'Colour?', [qw( red blue )] );
  is( $a1, 'blue', 'a number picks the option' );
  like( $o1, qr/\? Colour\?\n  1\) red\n  2\) blue\nanswer \(a number picks an option\)> \z/, 'question, numbered options, prompt' );
  is( [ $run->( "green\n", 'Colour?', [qw( red blue )] ) ]->[0], 'green', 'free text is the answer' );
  is( [ $run->( "7\n", 'Colour?', [qw( red blue )] ) ]->[0], '7', 'a number out of range is text' );
  is( [ $run->( "  yes  \n", 'Sure?' ) ]->[0], 'yes', 'trimmed' );
  is( [ $run->( "\n", 'Sure?' ) ]->[0], undef, 'an empty line is no answer' );
  is( [ $run->( '', 'Sure?' ) ]->[0], undef, 'closed input is no answer' );
};

subtest 'the REPL registers itself only where a person is' => sub {
  my $mk = sub {
    my ( %o ) = @_;
    my $app = cli();
    open my $in, '<', \"/quit\n" or die $!;
    my $out = '';
    open my $fh, '>', \$out or die $!;
    my $repl = Langertha::Raider::CLI::REPL->new(
      app => $app, in => $in, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ), %o,
    );
    $repl->run;
    return $app;
  };
  ok( !$mk->()->has_on_ask_user, 'input that is no terminal: not registered (defaults to can_ask 0)' );
  ok( $mk->( can_ask => 1 )->has_on_ask_user, 'can_ask: registered' );
};

done_testing;
