#!/usr/bin/env perl
# ABSTRACT: a subagent on an engine with embeddings ends without losing its session embeddings in flight (k160)

use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::StubEngine qw( stub_engine );

clear_engine_env();

# The openai engine embeds every session history entry in the background
# (simple_embedding_f, the stub answers 404). The child raider of the agent
# tool ends with the embedding of its answer still in flight; dropped with
# it, that async sub wakes up without its future and Future::AsyncAwait
# warns "Suspended async sub ... lost its returning future" on stderr.

my $repo = path(__FILE__)->absolute->parent->parent;
my $bin  = $repo->child('bin', 'raider');
my $root = tempdir(CLEANUP => 1);

my ( $stub, $url ) = stub_engine(agent => { description => 'look', prompt => 'child please',
  subagent_type => 'general-purpose' });
my $out = path($root)->child('out');
my $err = path($root)->child('err');
my $pid = fork // die 'fork: '.$!;
unless ($pid) {
  open STDIN,  '<', '/dev/null' or die $!;
  open STDOUT, '>', "$out"      or die $!;
  open STDERR, '>', "$err"      or die $!;
  exec $^X, '-I'.$repo->child('lib'), "$bin", '-r', $root, '-e', 'openai', '-k', 'test',
    '-m', 'stub-model', '-o', 'url='.$url, '--no-trace', '--dangerously-skip-permissions', 'go';
  die 'exec: '.$!;
}
{
  local $SIG{ALRM} = sub { kill KILL => $pid };
  alarm 120;
  waitpid $pid, 0;
  alarm 0;
}
my $status = $?;
kill KILL => $stub;
waitpid $stub, 0;

my $stderr = $err->slurp_utf8;
is($status, 0, 'raider exits 0') or diag 'stdout: '.$out->slurp_utf8."\nstderr: ".$stderr;
my $sessions = path($root)->child('.raider', 'sessions');
my $journals = join '', map { $_->slurp_utf8 } -d $sessions ? $sessions->children(qr/\.jsonl\z/) : ();
like($journals, qr/"status":"completed","time":[\d.]+,"type":"agent\.finished"/, 'the subagent ran to its end');
unlike($stderr, qr/lost its returning future/, 'no async sub lost its future') or diag $stderr;

done_testing;
