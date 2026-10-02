#!/usr/bin/env perl
# ABSTRACT: raider session fork ID and session rm ID (ADR 0003, ADR 0015)

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

subtest 'session fork: a new session with the history, the original untouched' => sub {
  my $root = tempdir(CLEANUP => 1);
  main_run('', '-r', $root, engine(), 'eins');
  my $store = Langertha::Raider::SessionStore->new(root => $root);
  my ( $id ) = $store->ids;
  my $before = path($store->path_of($id))->slurp_raw;
  my ( $tail ) = $id =~ /-([0-9a-f]{4})\z/;

  # the original is open for writing elsewhere: a fork only reads it
  my $writer = $store->open($id);
  my ( $exit, $out, $err ) = main_run('', 'session', 'fork', $tail, '-r', $root);
  $writer->release;
  is($exit, 0, 'exits 0');
  my ( $fork ) = grep { $_ ne $id } $store->ids;
  ok($fork, 'a new session');
  is($out, "forked session $id as $fork (".$store->path_of($fork)."): 2 messages\n", 'says so on stdout');
  is($err, '', 'nothing on stderr');
  is(path($store->path_of($id))->slurp_raw, $before, 'the original journal is unchanged');

  my @e = events($store->path_of($fork));
  like($e[0], { type => 'session.created', id => $fork, forked_from => $id, root => path($root)->absolute->stringify },
    'session.created names the origin, same project');
  is([ map { [ $_->{type}, $_->{role}, $_->{content}, exists $_->{run} ? 'run' : 'no run' ] } @e[ 1 .. $#e ] ],
    [ [ message => user => 'eins', 'no run' ], [ message => assistant => 'Fertig ✓', 'no run' ] ],
    'the history as message events, outside any run');
  is([ map { $_->{seq} } @e ], [ 1 .. 3 ], 'its own sequence');

  ( $exit, $out, $err ) = main_run('', '-r', $root, engine(), '--session', $fork, 'zwei');
  is($exit, 0, 'the fork goes on');
  is($err, "resumed session $fork: 0 runs, 2 messages in the history\n", 'with the history');
  is([ map { $_->{content} } grep { $_->{role} eq 'user' } @{ $Test::Raider::SeqEngine::REQUESTS[0] } ],
    [ 'eins', match qr/\nzwei\z/ ], 'the model sees the original conversation');
  is([ map { $_->{run} } grep { $_->{type} eq 'run.finished' } events($store->path_of($fork)) ], [ 'r1' ],
    'recorded as the fork\'s r1');
  is(path($store->path_of($id))->slurp_raw, $before, 'the original still unchanged');

  ( $exit, $out ) = main_run('', 'session', 'show', $fork, '-r', $root);
  like($out, qr/^forked from \Q$id\E$/m, 'session show names the origin');
};

subtest 'session fork: after /clear only what came later; --json; behind options' => sub {
  my $root = tempdir(CLEANUP => 1);
  main_run("eins\n/clear\nzwei\n", '-r', $root, engine(), '-i');
  my $store = Langertha::Raider::SessionStore->new(root => $root);
  my ( $id ) = $store->ids;
  my ( $exit, $out ) = main_run('', '-r', $root, 'session', 'fork', $id, '--json');
  is($exit, 0, 'exits 0');
  my $doc = doc($out);
  my ( $fork ) = grep { $_ ne $id } $store->ids;
  is($doc, { version => 1, id => $fork, path => ''.$store->path_of($fork), forked_from => $id, messages => 2 },
    'the document');
  is([ map { $_->{content} } grep { $_->{type} eq 'message' } events($store->path_of($fork)) ],
    [ 'zwei', 'Fertig ✓' ], 'the cleared part stays behind');
};

subtest 'session fork: errors' => sub {
  my $root = tempdir(CLEANUP => 1);
  my ( $exit, $out, $err ) = main_run('', 'session', 'fork', '20200101-000000-0000', '-r', $root);
  is($exit, 2, 'unknown session');
  is($err, "unknown session 20200101-000000-0000\n", 'reported');
  ok(!-e path($root, '.raider'), 'nothing created');
  ( $exit, $out, $err ) = main_run('', 'session', 'fork', '-r', $root);
  is($exit, 2, 'no id');
  like($err, qr/\AUsage: raider session list \| show ID \| resume ID \| fork ID \| rm ID/, 'usage');
  ( $exit, $out, $err ) = main_run('', 'session', 'fork', 'abcd', '-r', $root, '--stream-json');
  is($exit, 2, 'no stream');
  ( $exit, $out ) = main_run('', '-r', $root, engine(), 'session', 'fork', 'me');
  is($exit, 0, '"session fork me" behind options stays a prompt');
  like($out, qr/Fertig/, 'answered');
};

subtest 'session rm: explicit, refused under the lock' => sub {
  my $root = tempdir(CLEANUP => 1);
  main_run('', '-r', $root, engine(), 'eins');
  sleep 1;
  main_run('', '-r', $root, engine(), 'zwei');
  my $store = Langertha::Raider::SessionStore->new(root => $root);
  my ( $keep, $id ) = $store->ids;

  my $writer = $store->open($id);
  my ( $exit, $out, $err ) = main_run('', 'session', 'rm', $id, '-r', $root);
  is($exit, 4, 'in use: exit 4');
  is($err, "session $id is in use by another raider\n", 'reported');
  ok($store->exists($id), 'not removed');
  $writer->release;

  ( $exit, $out, $err ) = main_run('', 'session', 'rm', substr($id, 0, 15), '-r', $root);
  is($exit, 0, 'removed by a prefix');
  is($out, "removed session $id\n", 'says so');
  ok(!-e $store->path_of($id), 'the journal is gone');
  ok(!-e path($store->dir, $id.'.lock'), 'and its lock file');
  is([ $store->ids ], [ $keep ], 'the other session stays');

  ( $exit, $out, $err ) = main_run('', 'session', 'rm', $id, '-r', $root);
  is($exit, 2, 'gone: unknown session');
  is($err, "unknown session $id\n", 'reported');

  ( $exit, $out ) = main_run('', '-r', $root, 'session', 'rm', $keep, '--json');
  is($exit, 0, 'behind options, --json');
  is(doc($out), { version => 1, id => $keep, path => ''.$store->path_of($keep), removed => T() },
    'the document');
  is([ $store->ids ], [], 'no sessions left');
  ok(-d $store->dir, 'the sessions directory stays');
};

done_testing;
