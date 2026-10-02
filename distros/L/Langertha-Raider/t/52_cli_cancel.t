#!/usr/bin/env perl
# ABSTRACT: a one-shot raider cancelled by SIGINT: the cancelled document or run.finished, then death by SIGINT; a second SIGINT interrupts

use strict;
use warnings;
use Test2::V0;
use Config;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use POSIX qw( WIFSIGNALED WTERMSIG );
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::StubEngine qw( stub_engine alive );

clear_engine_env();

my $repo = path(__FILE__)->absolute->parent->parent;
my $bin  = $repo->child('bin', 'raider');
my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

my %signo;
@signo{ split ' ', $Config{sig_name} } = split ' ', $Config{sig_num};

sub died_of {
  my ( $status, $signal, $name ) = @_;
  ok(WIFSIGNALED($status) && WTERMSIG($status) == $signo{$signal},
    $name.': died of SIG'.$signal.' (shell status '.(128 + $signo{$signal}).')')
    or diag 'wait status '.$status;
}

sub journal_of {
  my ( $doc ) = @_;
  return [ map { $json->decode($_) } path($doc->{session}{path})->lines_raw({ chomp => 1 }) ];
}

# Starts bin/raider in $root with @args and the output in files; returns
# its pid and the stdout and stderr files.
sub spawn_raider {
  my ( $root, @args ) = @_;
  my $out = path($root)->child('out');
  my $err = path($root)->child('err');
  my $pid = fork // die 'fork: '.$!;
  unless ($pid) {
    open STDIN,  '<', '/dev/null' or die $!;
    open STDOUT, '>', "$out"      or die $!;
    open STDERR, '>', "$err"      or die $!;
    exec $^X, '-I'.$repo->child('lib'), "$bin", '-r', $root, '-e', 'openai', '-k', 'test',
      '-m', 'stub-model', '--no-trace', @args;
    die 'exec: '.$!;
  }
  return ( $pid, $out, $err );
}

sub reap {
  my ( $pid ) = @_;
  local $SIG{ALRM} = sub { kill KILL => $pid };
  alarm 30;
  waitpid $pid, 0;
  my $status = $?;
  alarm 0;
  return $status;
}

#### SIGINT while the model request is in flight

# Runs raider against a stub engine that answers the chat completion only
# after 60 seconds (the session embedding request gets its 404 at once),
# sends SIGINT once the run started and its request is on the way; returns
# ( wait status, stdout, stderr ).
sub cancelled_run {
  my ( @flags ) = @_;
  my $root = tempdir(CLEANUP => 1);
  my ( $stub, $url ) = stub_engine(bash => { command => 'true' }, delay => 60);
  my ( $pid, $out, $err ) = spawn_raider($root, '-o', 'url='.$url, @flags, 'hang please');
  my $sessions = path($root)->child('.raider', 'sessions');
  my $started;
  for (1 .. 300) {
    $started = grep { /"run\.started"/ } map { $_->lines_raw } -d $sessions ? $sessions->children(qr/\.jsonl\z/) : ()
      and last;
    select undef, undef, undef, 0.1;
  }
  if ($started) {
    select undef, undef, undef, 1;   # the request is on its way
    kill INT => $pid;
  }
  else {
    kill KILL => $pid;
  }
  my $status = reap($pid);
  kill KILL => $stub;
  waitpid $stub, 0;
  return ( $status, $out->slurp_raw, $err->slurp_utf8 );
}

subtest '--json: SIGINT during the model request writes the cancelled document' => sub {
  my ( $status, $stdout, $stderr ) = cancelled_run('--json');
  died_of($status, 'INT', '--json');
  my $doc = eval { $json->decode($stdout) };
  is($doc, { version => 1, status => 'cancelled', elapsed => D(),
    session => { id => T(), path => T() } },
    'one document, status cancelled') or diag 'stdout: '.$stdout."\nstderr: ".$stderr;
  unlike($stderr, qr/ at \S+ line \d+/, 'no Perl error on stderr') or diag $stderr;
  my $journal = journal_of($doc);
  is([ map { $_->{type} } @$journal ], [qw( session.created run.started message run.finished )],
    'the session journal ends the run');
  like($journal->[-1], { run => 'r1', status => 'cancelled' }, 'as cancelled');
};

subtest '--stream-json: SIGINT ends with run.state cancelled and run.finished' => sub {
  my ( $status, $stdout, $stderr ) = cancelled_run('--stream-json');
  died_of($status, 'INT', '--stream-json');
  my @events = map { $json->decode($_) } split /\n/, $stdout;
  is([ map { $_->{type} } @events ], [qw( run.started run.state run.state run.finished )],
    'event sequence') or diag 'stdout: '.$stdout."\nstderr: ".$stderr;
  is($events[2]{state}, 'cancelled', 'last state change is cancelled');
  like($events[-1], { status => 'cancelled', elapsed => D(), seq => 4 },
    'run.finished carries the cancelled document');
};

subtest 'human output: a note, no Perl error, death by SIGINT' => sub {
  my ( $status, $stdout, $stderr ) = cancelled_run();
  died_of($status, 'INT', 'human');
  like($stdout.$stderr, qr/cancelled \(SIGINT\)/, 'says it was cancelled')
    or diag 'stdout: '.$stdout."\nstderr: ".$stderr;
  unlike($stdout.$stderr, qr/interrupted/, 'not interrupted');
  unlike($stderr, qr/ at \S+ line \d+/, 'no Perl error on stderr') or diag $stderr;
};

#### SIGINT while a tool subprocess runs

SKIP: {
  skip 'needs /proc to find the tool subprocess', 2 unless -d '/proc/'.$$;

  # Runs raider --json against a stub engine calling bash with $command
  # (PIDFILE replaced by a file the command writes its pid to), sends
  # SIGINT once that pid is there -- and with $second another SIGINT
  # $second seconds later. Returns ( wait status, stdout, tool pid ).
  my $tool_run = sub {
    my ( $command, $second ) = @_;
    my $root    = tempdir(CLEANUP => 1);
    my $pidfile = path($root)->child('tool.pid');
    $command =~ s/PIDFILE/$pidfile/g;
    my ( $stub, $stub_url ) = stub_engine(bash => { command => $command });
    my ( $pid, $out ) = spawn_raider($root, '-o', 'url='.$stub_url, '--json', 'run the tool');
    my $tool_pid;
    for (1 .. 300) {
      ( $tool_pid ) = ( eval { $pidfile->slurp } // '' ) =~ /(\d+)/ and last;
      select undef, undef, undef, 0.1;
    }
    if ($tool_pid) {
      kill INT => $pid;
      if ($second) {
        select undef, undef, undef, $second;
        kill INT => $pid;
      }
    }
    else {
      kill KILL => $pid;
    }
    my $status = reap($pid);
    kill KILL => $stub;
    waitpid $stub, 0;
    return ( $status, $out->slurp_raw, $tool_pid );
  };

  my $gone = sub {
    my ( $tool_pid ) = @_;
    my $gone;
    for (1 .. 50) { $gone = !alive($tool_pid) and last; select undef, undef, undef, 0.1 }
    unless ($gone) { kill KILL => -$tool_pid; kill KILL => $tool_pid }
    return $gone;
  };

  subtest 'SIGINT during bash cancels the run and ends the tool subprocess' => sub {
    my ( $status, $stdout, $tool_pid ) = $tool_run->('echo $$ > PIDFILE; sleep 300');
    ok($tool_pid, 'bash started and wrote its pid') or return;
    died_of($status, 'INT', 'raider');
    my $doc = eval { $json->decode($stdout) };
    like($doc, { status => 'cancelled' }, 'the cancelled document') or diag 'stdout: '.$stdout;
    ok($gone->($tool_pid), 'the bash subprocess is gone');
    my $journal = journal_of($doc);
    ok((grep { $_->{type} eq 'tool.call' && $_->{name} eq 'bash' } @$journal), 'after the tool call');
    my ( $result ) = grep { $_->{type} eq 'tool.result' } @$journal;
    like($result, { name => 'bash', status => 'cancelled' }, 'the cut-off call reported cancelled');
    like($journal->[-1], { type => 'run.finished', status => 'cancelled' }, 'the run as cancelled');
  };

  # The command ignores SIGTERM, so ending it takes the grace period; the
  # second SIGINT comes while raider is still cancelling.
  subtest 'a second SIGINT while cancelling interrupts the run' => sub {
    my ( $status, $stdout, $tool_pid ) = $tool_run->(q{trap '' TERM; echo $$ > PIDFILE; sleep 300}, 0.5);
    ok($tool_pid, 'bash started and wrote its pid') or return;
    died_of($status, 'INT', 'raider');
    my $doc = eval { $json->decode($stdout) };
    is($doc, { version => 1, status => 'interrupted', signal => 'INT', elapsed => D(),
      session => { id => T(), path => T() } },
      'one document, status interrupted') or diag 'stdout: '.$stdout;
    ok($gone->($tool_pid), 'the bash subprocess is gone');
    like(journal_of($doc)->[-1], { type => 'run.finished', status => 'interrupted', signal => 'INT' },
      'the run as interrupted');
  };
}

done_testing;
