#!/usr/bin/env perl
# ABSTRACT: the REPL left by Ctrl-C twice or SIGTERM while a tool runs: the bash command and the perl_eval child go with it

use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::StubEngine qw( stub_engine alive );

clear_engine_env();

skip_all 'needs /proc to find the tool subprocess' unless -d '/proc/'.$$;

my $repo = path(__FILE__)->absolute->parent->parent;
my $bin  = $repo->child('bin', 'raider');

sub wait_until {
  my ( $cond ) = @_;
  for (1 .. 50) { return 1 if $cond->(); select undef, undef, undef, 0.1 }
  return 0;
}

# The same within 1.5 seconds, so a second Ctrl-C still falls in the
# two-strike window.
sub wait_until_quick {
  my ( $cond ) = @_;
  for (1 .. 30) { return 1 if $cond->(); select undef, undef, undef, 0.05 }
  return 0;
}

sub journal_events {
  my ( $out ) = @_;
  my $dir = $out->parent->child('.raider', 'sessions');
  my ( $journal ) = -d $dir ? $dir->children(qr/\.jsonl\z/) : ();
  my $json = JSON::MaybeXS->new(utf8 => 1);
  return map { $json->decode($_) } $journal ? $journal->lines_raw({ chomp => 1 }) : ();
}

# Whether the session journal has the run.finished of $run (stdout is a
# buffered file until raider ends).
sub finished {
  my ( $out, $run ) = @_;
  return scalar grep { $_->{type} eq 'run.finished' && $_->{run} eq $run } journal_events($out);
}

# Starts bin/raider -i with its stdin a pipe kept open (the REPL reads lines
# without a terminal), sends a prompt the stub engine answers with a call of
# $tool, and returns ( raider pid, tool pid, stdout file, stub pid, pipe ).
sub repl_in_tool {
  my ( $tool, $arguments, @flags ) = @_;
  my $root    = tempdir(CLEANUP => 1);
  my $pidfile = path($root)->child('tool.pid');
  s/PIDFILE/$pidfile/g for values %$arguments;
  my ( $stub, $url ) = stub_engine($tool, $arguments);
  my $out = path($root)->child('out');
  pipe(my $r, my $w) or die 'pipe: '.$!;
  my $pid = fork // die 'fork: '.$!;
  unless ($pid) {
    close $w;
    open STDIN,  '<&', $r                   or die $!;
    open STDOUT, '>', "$out"                or die $!;
    open STDERR, '>', path($root)->child('err')->stringify or die $!;
    exec $^X, '-I'.$repo->child('lib'), "$bin", '-r', $root, '-e', 'openai', '-k', 'test',
      '-m', 'stub-model', '-o', 'url='.$url, '--no-trace', '-i', @flags;
    die 'exec: '.$!;
  }
  close $r;
  syswrite $w, "run the tool\n";
  my $tool_pid;
  for (1 .. 300) {
    ( $tool_pid ) = ( eval { $pidfile->slurp } // '' ) =~ /(\d+)/ and last;
    select undef, undef, undef, 0.1;
  }
  return ( $pid, $tool_pid, $out, $stub, $w );
}

# Waits for raider to end (KILL after 30s), returns its wait status and
# cleans up the stub and a tool process that survived.
sub finish {
  my ( $pid, $tool_pid, $stub ) = @_;
  local $SIG{ALRM} = sub { kill KILL => $pid };
  alarm 30;
  waitpid $pid, 0;
  my $status = $?;
  alarm 0;
  kill KILL => $stub;
  waitpid $stub, 0;
  return $status;
}

for my $case (
  [ bash      => INT  => { command => 'echo $$ > PIDFILE; sleep 300' } ],
  [ perl_eval => INT  => { code => 'open my $f, q{>}, q{PIDFILE} or die; print {$f} $$; close $f; sleep 300' }, '--perl' ],
  [ bash      => TERM => { command => 'echo $$ > PIDFILE; sleep 300' } ],
) {
  my ( $tool, $signal, $arguments, @flags ) = @$case;
  my $how = $signal eq 'INT' ? 'Ctrl-C twice' : 'SIGTERM';
  subtest $how.' in the REPL during '.$tool.' ends the tool subprocess' => sub {
    my ( $pid, $tool_pid, $out, $stub, $w ) = repl_in_tool($tool, $arguments, @flags);
    unless (ok($tool_pid, $tool.' started and wrote its pid')) {
      kill KILL => $pid;
      finish($pid, 0, $stub);
      return;
    }

    if ($signal eq 'INT') {
      kill INT => $pid;
      # The second one has to follow within two seconds.
      ok(wait_until_quick(sub { !alive($tool_pid) }), 'the first Ctrl-C ends the '.$tool.' subprocess');
      ok(wait_until_quick(sub { finished($out, 'r1') }), 'and cancels the turn');
      ok(alive($pid), 'raider still runs after the first Ctrl-C');
    }
    kill $signal => $pid;
    my $status = finish($pid, $tool_pid, $stub);
    is($status, 0, 'raider left the REPL with exit status 0');
    like($out->slurp, qr/cancelling the turn; press Ctrl-C again within 2s to quit.*^turn cancelled$/ms,
      'the first Ctrl-C said so') if $signal eq 'INT';
    like($out->slurp, qr/bye\.\n\z/, 'and said bye');

    my @events = journal_events($out);
    like($events[-1], $signal eq 'INT'
      ? { type => 'run.finished', run => 'r1', status => 'cancelled' }
      : { type => 'run.finished', run => 'r1', status => 'interrupted', signal => $signal },
      'the session journal ends the run as '.($signal eq 'INT' ? 'cancelled' : 'interrupted'));
    ok((grep { $_->{type} eq 'tool.call' && $_->{name} eq $tool } @events), 'after the tool call');

    my $gone = wait_until(sub { !alive($tool_pid) });
    ok($gone, 'the '.$tool.' subprocess is gone');
    unless ($gone) { kill KILL => -$tool_pid; kill KILL => $tool_pid }
    close $w;
  };
}

subtest 'Ctrl-C while the model answers abandons the request' => sub {
  my $root = tempdir(CLEANUP => 1);
  # The stub answers the first request after 60 seconds only.
  my ( $stub, $url ) = stub_engine(bash => { command => 'true' }, delay => 60);
  my $out = path($root)->child('out');
  pipe(my $r, my $w) or die 'pipe: '.$!;
  my $pid = fork // die 'fork: '.$!;
  unless ($pid) {
    close $w;
    open STDIN,  '<&', $r                   or die $!;
    open STDOUT, '>', "$out"                or die $!;
    open STDERR, '>', path($root)->child('err')->stringify or die $!;
    exec $^X, '-I'.$repo->child('lib'), "$bin", '-r', $root, '-e', 'openai', '-k', 'test',
      '-m', 'stub-model', '-o', 'url='.$url, '--no-trace', '-i';
    die 'exec: '.$!;
  }
  close $r;
  syswrite $w, "hello\n";
  ok(wait_until(sub { scalar grep { $_->{type} eq 'run.started' } journal_events($out) }), 'the run started');
  select undef, undef, undef, 1;   # the request is on its way
  my $t0 = time;
  kill INT => $pid;
  ok(wait_until(sub { finished($out, 'r1') }), 'the turn ends');
  ok(time - $t0 < 10, 'without waiting for the model');
  close $w;
  is(finish($pid, 0, $stub), 0, 'the REPL ends with its input, exit status 0');
  my @events = journal_events($out);
  like($events[-1], { type => 'run.finished', run => 'r1', status => 'cancelled' }, 'cancelled');
  ok(!(grep { $_->{type} =~ /^tool\./ } @events), 'no tool was called');
  like($out->slurp, qr/^turn cancelled$/m, 'said so');
};

subtest 'Ctrl-C once cancels the turn, the REPL goes on' => sub {
  my $mark = path(tempdir(CLEANUP => 1))->child('mark');
  # The first call hangs, every later one returns at once.
  my ( $pid, $tool_pid, $out, $stub, $w ) = repl_in_tool(bash =>
    { command => 'test -e '.$mark.' && echo quick || { touch '.$mark.'; echo $$ > PIDFILE; sleep 300; }' });
  unless (ok($tool_pid, 'bash started and wrote its pid')) {
    kill KILL => $pid;
    finish($pid, 0, $stub);
    return;
  }
  kill INT => $pid;
  is(wait_until(sub { finished($out, 'r1') }), 1, 'the turn ends');
  ok(wait_until(sub { !alive($tool_pid) }), 'the bash subprocess is gone');
  select undef, undef, undef, 2.5;   # the two-strike window is over
  ok(alive($pid), 'raider still runs');

  syswrite $w, "again\n";
  ok(wait_until(sub { finished($out, 'r2') }), 'the next prompt runs to its end');
  close $w;
  is(finish($pid, $tool_pid, $stub), 0, 'the REPL ends with its input, exit status 0');
  like($out->slurp, qr/^turn cancelled\n.*^done$/ms, 'cancelled, then answered');

  my @events = journal_events($out);
  is([ map { [ $_->{run}, $_->{status} ] } grep { $_->{type} eq 'run.finished' } @events ],
    [ [ r1 => 'cancelled' ], [ r2 => 'completed' ] ], 'r1 cancelled, r2 completed');
  my ( $first ) = grep { $_->{type} eq 'tool.result' && $_->{run} eq 'r1' } @events;
  like($first, { name => 'bash', status => 'cancelled' }, 'the cut-off call has its result');
  is([ map { $_->{content} } grep { $_->{type} eq 'message' && $_->{role} eq 'assistant' } @events ], [ 'done' ],
    'only r2 answered');
};

done_testing;
