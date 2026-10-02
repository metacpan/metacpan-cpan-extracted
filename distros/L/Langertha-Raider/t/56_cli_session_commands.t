#!/usr/bin/env perl
# ABSTRACT: raider session list/show/resume, --session ID and --continue: replay, crash rules, the lock (ADR 0015)

use strict;
use warnings;
use utf8;
use Test2::V0;
use Encode qw( decode_utf8 encode_utf8 );
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::SeqEngine;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::SessionStore;

clear_engine_env();

package My::Main {
  use Moose;
  extends 'Langertha::Raider::CLI::Main';
  sub app_class { 'Test::Raider::SeqEngine::App' }
  __PACKAGE__->meta->make_immutable;
}

sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; decode_utf8($buf) } );
}

sub main_run {
  my ( $stdin, @argv ) = @_;
  my ( $out, $read_out ) = buffer();
  my ( $err, $read_err ) = buffer();
  open my $in, '<', \$stdin or die $!;
  local $ENV{ANSI_COLORS_DISABLED};
  @Test::Raider::SeqEngine::REQUESTS = ();
  @Test::Raider::SeqEngine::CALLS    = ();
  my $exit = My::Main->new(
    output => Langertha::Raider::CLI::Output->new(out => $out, color => 0),
    err    => $err,
    in     => $in,
  )->run(@argv);
  return ( $exit, $read_out->(), $read_err->() );
}

my $json = JSON::MaybeXS->new(utf8 => 1);
sub events { map { $json->decode($_) } path($_[0])->lines_raw({ chomp => 1 }) }
sub doc    { $json->decode(encode_utf8($_[0])) }
sub engine { ( '-e', 'openai', '-k', 'test', '-m', 'seq-model', '--no-trace' ) }

subtest 'session list' => sub {
  my $root = tempdir(CLEANUP => 1);
  my ( $exit, $out, $err ) = main_run('', 'session', 'list', '-r', $root);
  is($exit, 0, 'exits 0 without sessions');
  like($out, qr/\Ano sessions in \Q$root\E/, 'says so');
  ok(!-e path($root, '.raider'), 'creates nothing');

  main_run('', '-r', $root, engine(), 'first prompt');
  sleep 1;
  main_run('', '-r', $root, engine(), 'fail');
  my $store = Langertha::Raider::SessionStore->new(root => $root);
  my @ids = $store->ids;

  ( $exit, $out ) = main_run('', 'session', 'list', '-r', $root);
  like($out, qr/\A\Q$ids[0]\E\s+1 run \s+failed\s+fail\n\Q$ids[1]\E\s+1 run \s+completed\s+first prompt\n\z/,
    'newest first: id, runs, last status, first prompt');

  ( $exit, $out ) = main_run('', '-r', $root, engine(), 'session', 'list', '--json');
  is($exit, 0, 'behind options, with --json');
  my $doc = doc($out);
  is($doc->{version}, 1, 'versioned');
  is([ map { $_->{id} } @{ $doc->{sessions} } ], \@ids, 'every session');
  like($doc->{sessions}[1], { runs => 1, status => 'completed', prompt => 'first prompt', damaged => 0,
    created => qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/, path => "".$store->path_of($ids[1]) }, 'summary');

  ( $exit, $out, $err ) = main_run('', 'session', 'list', '-r', $root, '--stream-json');
  is($exit, 2, 'no stream');
  ( $exit, $out, $err ) = main_run('', 'session', 'list', 'more');
  is($exit, 2, 'nothing after list');
  like($err, qr/\AUsage: raider session list \| show ID \| resume ID/, 'usage');
};

subtest 'prompts that only start with "session" stay prompts' => sub {
  my $root = tempdir(CLEANUP => 1);
  for my $prompt ([qw( session is lost )], [qw( session show me )], [qw( session list all )]) {
    my ( $exit, $out ) = main_run('', '-r', $root, engine(), @$prompt);
    is($exit, 0, "@$prompt: a run");
    like($out, qr/Fertig/, 'answered');
  }
  my ( $exit, $out ) = main_run('', 'session', 'is', 'lost', '-r', $root, engine());
  is($exit, 0, 'also as the first words');
  my @runs = grep { $_->[0]{content} } map { [ grep { $_->{role} eq 'user' } @$_ ] } @Test::Raider::SeqEngine::REQUESTS;
  like($runs[0][0]{content}, qr/\nsession is lost\z/, 'sent as the prompt');
};

subtest 'session show' => sub {
  my $root = tempdir(CLEANUP => 1);
  main_run('', '-r', $root, engine(), 'hallo');
  my $store = Langertha::Raider::SessionStore->new(root => $root);
  my ( $id ) = $store->ids;

  my ( $exit, $out ) = main_run('', 'session', 'show', $id, '-r', $root);
  is($exit, 0, 'exits 0');
  like($out, qr/^session\s+\Q$id\E$/m, 'the id');
  like($out, qr/^r1 started\s+openai seq-model$/m, 'run.started');
  like($out, qr/^r1 user\s+hallo$/m, 'the input');
  like($out, qr/^r1 tool\s+c1 bash \{"command":"ls"\}$/m, 'the tool call');
  like($out, qr/^r1 result\s+c1 succeeded, 1500 chars: x+\.\.\.$/m, 'its result, short');
  like($out, qr/^r1 result\s+c2 failed, 14 chars: nope: ä line 2$/m, 'a failed tool');
  like($out, qr/^r1 assistant Fertig ✓$/m, 'the answer');
  like($out, qr/^r1 finished\s+completed, [\d.]+s$/m, 'the end');

  ( $exit, $out ) = main_run('', '-r', $root, 'session', 'show', $id, '--json');
  my $doc = doc($out);
  is($doc->{id}, $id, '--json: behind options too');
  is(scalar @{ $doc->{events} }, 9, 'every event');
  is(length $doc->{events}[4]{content}, 1500, 'the whole tool output');
  is($doc->{runs}, [ { run => 'r1', status => 'completed' } ], 'runs');
  is($doc->{unknown}, [], 'no unknown calls');

  my ( $e, $o, $err ) = main_run('', 'session', 'show', '20200101-000000-0000', '-r', $root);
  is($e, 2, 'unknown session: usage error');
  is($err, "unknown session 20200101-000000-0000\n", 'reported');
  ( $e, $o, $err ) = main_run('', 'session', 'show', 'x', '-r', $root);
  is($e, 2, 'not an id');
  ( $e, $o, $err ) = main_run('', 'session', 'show', '-r', $root);
  is($e, 2, 'no id');
};

subtest '--session ID and --continue: the conversation goes on in the same journal' => sub {
  my $root = tempdir(CLEANUP => 1);
  main_run('', '-r', $root, engine(), 'eins');
  my $store = Langertha::Raider::SessionStore->new(root => $root);
  my ( $id ) = $store->ids;

  my ( $exit, $out, $err ) = main_run('', '-r', $root, engine(), '--session', $id, 'zwei');
  is($exit, 0, 'exits 0');
  is($err, "resumed session $id: 1 run, 2 messages in the history\n", 'says what was resumed');
  my $first = $Test::Raider::SeqEngine::REQUESTS[0];
  is([ map { [ $_->{role}, $_->{content} ] } grep { $_->{role} ne 'system' } @$first ],
    [ [ user => 'eins' ], [ assistant => 'Fertig ✓' ], [ user => match qr/\nzwei\z/ ] ], 'the model sees the history');
  is(scalar(my @ids = $store->ids), 1, 'no new session');
  my @e = events($store->path_of($id));
  is([ map { $_->{run} // '-' } grep { $_->{type} eq 'run.started' } @e ], [qw( r1 r2 )], 'recorded as r2');
  is([ map { $_->{seq} } @e ], [ 1 .. scalar @e ], 'seq goes on');
  my $raider = $Test::Raider::SeqEngine::APP->raider;
  like($raider->session_history->[0], { role => 'user', content => 'eins' }, 'session_history replayed');
  ok((grep { ref $_->{content} eq 'ARRAY' && ($_->{content}[0]{name} // '') eq 'bash' } @{ $raider->session_history }),
    'with the tool calls');

  sleep 1;
  main_run('', '-r', $root, engine(), 'other session');
  ( $exit, $out, $err ) = main_run('', '-r', $root, engine(), '--continue', '--json', 'drei');
  is($exit, 0, '--continue');
  my ( $latest ) = $store->ids;
  isnt($latest, $id, 'there is a newer session');
  is(doc($out)->{session}{id}, $latest, 'continues the newest one');
  like($err, qr/\Aresumed session \Q$latest\E: 1 run/, 'notes on stderr also with a machine format');
};

subtest 'resume: interrupted runs and unknown tool calls are reported, never run again' => sub {
  my $root = tempdir(CLEANUP => 1);
  my $store = Langertha::Raider::SessionStore->new(root => $root);
  my $s = $store->create;
  my $id = $s->id;
  $s->append('run.started', run => 'r1');
  $s->append('message', run => 'r1', role => 'user', content => 'eins');
  $s->append('message', run => 'r1', role => 'assistant', content => 'ok');
  $s->append('run.finished', run => 'r1', status => 'completed');
  $s->append('run.started', run => 'r2');
  $s->append('message', run => 'r2', role => 'user', content => 'lösche alles');
  $s->append('tool.call', run => 'r2', call => 'c1', name => 'bash', arguments => { command => 'rm -rf x' },
    status => 'dispatched');
  $s->release;
  path($store->path_of($id))->append_raw('{"v":1,"seq":9,"ty');

  my ( $exit, $out, $err ) = main_run('', '-r', $root, engine(), '--session', $id, 'weiter');
  is($exit, 0, 'resumed');
  is([ split /\n/, $err ], [
    "resumed session $id: 2 runs, 2 messages in the history",
    'line 9 of the journal is damaged and was skipped',
    'run r2 has no end: interrupted',
    'tool call bash (r2 c1) has no result: its outcome is unknown, it is not run again',
  ], 'every crash rule reported');
  is([ map { $_->[1]{command} // '' } grep { $_->[0] eq 'bash' } @Test::Raider::SeqEngine::CALLS ], [ 'ls' ],
    'rm -rf x was not run again; only the new run called bash');
  my $first = $Test::Raider::SeqEngine::REQUESTS[0];
  is([ map { $_->{content} } grep { $_->{role} eq 'user' } @$first ], [ 'eins', match qr/\nweiter\z/ ],
    'the interrupted input is not in the history');
  ok((grep { ($_->{content} // '') =~ /\Aunknown: no result/ } @{ $Test::Raider::SeqEngine::APP->raider->session_history }),
    'session_history marks the call as unknown');
  my $journal = $store->read($id);
  is([ map { [ $_->{run}, $_->{status} ] } @{ $journal->runs } ],
    [ [ r1 => 'completed' ], [ r2 => 'interrupted' ], [ r3 => 'completed' ] ], 'the new run is r3');
  is($journal->damaged, [9], 'the damaged line stays where it is');

  ( $exit, $out ) = main_run('', 'session', 'show', $id, '-r', $root);
  like($out, qr/^note: run r2 has no end: interrupted$/m, 'show reports it too');
};

subtest 'usage and lock errors' => sub {
  my $root = tempdir(CLEANUP => 1);
  my ( $exit, $out, $err ) = main_run('', '-r', $root, engine(), '--continue', 'hi');
  is($exit, 2, '--continue without a session');
  like($err, qr/\Ano session to continue in /, 'reported');
  ok(!-e path($root, '.raider'), 'nothing created');
  ( $exit, $out, $err ) = main_run('', '-r', $root, engine(), '--session', '20200101-000000-0000', 'hi');
  is($exit, 2, 'unknown session');
  ( $exit, $out, $err ) = main_run('', '-r', $root, engine(), '--session', 'latest', 'hi');
  is($exit, 2, 'not an id');
  is($err, "--session: not a session id: 'latest'\n", 'reported');
  ( $exit, $out, $err ) = main_run('', '-r', $root, engine(), '--continue', '--no-session', 'hi');
  is($exit, 2, '--continue with --no-session');
  is($err, "--continue, --no-session: only one of them at a time\n", 'reported');

  main_run('', '-r', $root, engine(), 'hi');
  my $store = Langertha::Raider::SessionStore->new(root => $root);
  my ( $id ) = $store->ids;
  my $writer = $store->open($id);
  ( $exit, $out, $err ) = main_run('', '-r', $root, engine(), '--session', $id, '--json', 'hi');
  is($exit, 4, 'a session in use: exit 4');
  is($err, "session $id is in use by another raider\n", 'reported');
  is($out, '', 'no document, nothing ran');
  is(scalar @Test::Raider::SeqEngine::REQUESTS, 0, 'no engine request');
  ( $exit ) = main_run("hi\n", 'session', 'resume', $id, '-r', $root, engine());
  is($exit, 4, 'session resume too');
  $writer->release;

  ( $exit, $out, $err ) = main_run('', 'session', 'resume', $id, '-r', $root, engine(), '--json');
  is($exit, 2, 'resume is the REPL: no machine output');
};

subtest 'session resume ID: the REPL on the session' => sub {
  my $root = tempdir(CLEANUP => 1);
  main_run('', '-r', $root, engine(), 'eins');
  my $store = Langertha::Raider::SessionStore->new(root => $root);
  my ( $id ) = $store->ids;
  my ( $exit, $out ) = main_run("zwei\n", 'session', 'resume', $id, '-r', $root, engine());
  is($exit, 0, 'exits 0');
  like($out, qr/^session:  \Q$id\E \(/m, 'the banner names the session');
  like($out, qr/^resumed session \Q$id\E: 1 run, 2 messages in the history$/m, 'and what was resumed');
  unlike($out, qr/^session \Q$id\E \(/m, 'no second "session created" line');
  is([ map { $_->{content} } grep { $_->{role} eq 'user' } @{ $Test::Raider::SeqEngine::REQUESTS[0] } ],
    [ 'eins', match qr/\nzwei\z/ ], 'the conversation goes on');
  is([ map { $_->{run} } grep { $_->{type} eq 'run.finished' } events($store->path_of($id)) ], [qw( r1 r2 )],
    'recorded as r2');
  is(scalar(my @ids = $store->ids), 1, 'one session');

  ( $exit, $out ) = main_run("drei\n", '-r', $root, engine(), '-i', '--continue');
  like($out, qr/^resumed session \Q$id\E: 2 runs/m, '-i --continue');
};

subtest 'short ids: a unique prefix or the four hex digits' => sub {
  my $root = tempdir(CLEANUP => 1);
  my $dir = path($root, '.raider', 'sessions');
  main_run('', '-r', $root, engine(), 'eins');
  my $store = Langertha::Raider::SessionStore->new(root => $root);
  my ( $id ) = $store->ids;
  my ( $tail ) = $id =~ /-([0-9a-f]{4})\z/;
  # two more sessions of another day, told apart only by their time
  my $other = $tail eq 'beef' ? 'cafe' : 'beef';
  $dir->child('20200101-000000-'.$other.'.jsonl')->spew_raw('');
  $dir->child('20200101-000001-'.$other.'.jsonl')->spew_raw('');

  my ( $exit, $out, $err ) = main_run('', 'session', 'show', $tail, '-r', $root);
  is($exit, 0, 'session show TAIL');
  like($out, qr/^session\s+\Q$id\E$/m, 'the whole id');
  ( $exit, $out ) = main_run('', '-r', $root, 'session', 'show', substr($id, 0, 11), '--json');
  is(doc($out)->{id}, $id, 'a prefix, behind options');

  ( $exit, $out, $err ) = main_run('', '-r', $root, engine(), '--session', $tail, 'zwei');
  is($exit, 0, '--session TAIL');
  like($err, qr/\Aresumed session \Q$id\E: 1 run/, 'resumed the whole id');

  ( $exit, $out, $err ) = main_run('', 'session', 'show', '20200101', '-r', $root);
  is($exit, 2, 'ambiguous: usage error');
  is($err, "session 20200101 is ambiguous: 20200101-000001-$other, 20200101-000000-$other\n", 'names the candidates');
  ( $exit, $out, $err ) = main_run('', '-r', $root, engine(), '--session', $other, 'hi');
  is($exit, 2, 'an ambiguous tail for --session');
  like($err, qr/\Asession \Q$other\E is ambiguous: /, 'reported');
  is(scalar @Test::Raider::SeqEngine::REQUESTS, 0, 'nothing ran');
  ( $exit, $out, $err ) = main_run('', 'session', 'show', '0000', '-r', $root);
  is($exit, 2, 'no match');
  is($err, "unknown session 0000\n", 'reported');
};

subtest '/clear is recorded, and a resume starts after it' => sub {
  my $root = tempdir(CLEANUP => 1);
  main_run("eins\n/clear\nzwei\n", '-r', $root, engine(), '-i');
  my $store = Langertha::Raider::SessionStore->new(root => $root);
  my ( $id ) = $store->ids;
  my @e = events($store->path_of($id));
  is([ map { $_->{type} eq 'message' ? $_->{content} : $_->{type} } grep { $_->{type} =~ /\A(?:message|history\.cleared)\z/ } @e ],
    [ 'eins', 'Fertig ✓', 'history.cleared', 'zwei', 'Fertig ✓' ], 'history.cleared between the runs');
  ok(!exists((grep { $_->{type} eq 'history.cleared' } @e)[0]{run}), 'outside any run');

  my ( $exit, $out, $err ) = main_run('', '-r', $root, engine(), '--session', $id, 'drei');
  is($err, "resumed session $id: 2 runs, 2 messages in the history\n", 'only what came after /clear');
  is([ map { $_->{content} } grep { $_->{role} eq 'user' } @{ $Test::Raider::SeqEngine::REQUESTS[0] } ],
    [ 'zwei', match qr/\ndrei\z/ ], 'the cleared input is not sent again');

  main_run("/clear\n/help\n", '-r', $root, engine(), '-i');
  is(scalar(my @ids = $store->ids), 1, '/clear before any prompt starts no session');
};

done_testing;
