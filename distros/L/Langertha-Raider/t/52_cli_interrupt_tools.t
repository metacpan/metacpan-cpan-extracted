#!/usr/bin/env perl
# ABSTRACT: raider interrupted while a tool subprocess runs: the bash command and the perl_eval child go with it

use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use POSIX qw( WIFSIGNALED WTERMSIG );
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::StubEngine qw( stub_engine alive );

clear_engine_env();

skip_all 'needs /proc to find the tool subprocess' unless -d '/proc/'.$$;

my $repo = path(__FILE__)->absolute->parent->parent;
my $bin  = $repo->child('bin', 'raider');
my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

# Runs bin/raider --json against a stub engine calling $tool with
# $arguments (PIDFILE in a string replaced by a file the tool writes its
# pid to), sends SIGTERM once that pid is there and returns ( wait status,
# stdout, tool pid ).
sub interrupted_tool_run {
  my ( $tool, $arguments, @flags ) = @_;
  my $root    = tempdir(CLEANUP => 1);
  my $pidfile = path($root)->child('tool.pid');
  s/PIDFILE/$pidfile/g for values %$arguments;
  my ( $stub, $url ) = stub_engine($tool, $arguments);
  my $out = path($root)->child('out');
  my $pid = fork // die 'fork: '.$!;
  unless ($pid) {
    open STDIN,  '<', '/dev/null'           or die $!;
    open STDOUT, '>', "$out"                or die $!;
    open STDERR, '>', path($root)->child('err')->stringify or die $!;
    exec $^X, '-I'.$repo->child('lib'), "$bin", '-r', $root, '-e', 'openai', '-k', 'test',
      '-m', 'stub-model', '-o', 'url='.$url, '--no-trace', '--json', @flags, 'run the tool';
    die 'exec: '.$!;
  }
  my $tool_pid;
  for (1 .. 300) {
    ( $tool_pid ) = ( eval { $pidfile->slurp } // '' ) =~ /(\d+)/ and last;
    select undef, undef, undef, 0.1;
  }
  $tool_pid ? kill TERM => $pid : kill KILL => $pid;
  local $SIG{ALRM} = sub { kill KILL => $pid };
  alarm 30;
  waitpid $pid, 0;
  my $status = $?;
  alarm 0;
  kill KILL => $stub;
  waitpid $stub, 0;
  return ( $status, $out->slurp_raw, $tool_pid );
}

for my $case (
  [ bash      => { command => 'echo $$ > PIDFILE; sleep 300' } ],
  [ perl_eval => { code => 'open my $f, q{>}, q{PIDFILE} or die; print {$f} $$; close $f; sleep 300' }, '--perl' ],
) {
  my ( $tool, $arguments, @flags ) = @$case;
  subtest 'SIGTERM during '.$tool.' ends the tool subprocess' => sub {
    my ( $status, $stdout, $tool_pid ) = interrupted_tool_run($tool, $arguments, @flags);
    ok($tool_pid, $tool.' started and wrote its pid') or return;
    ok(WIFSIGNALED($status) && WTERMSIG($status) == 15, 'raider died of SIGTERM')
      or diag 'wait status '.$status;
    like(eval { $json->decode($stdout) }, { status => 'interrupted', signal => 'TERM' },
      'the interrupted document') or diag 'stdout: '.$stdout;
    my $gone;
    for (1 .. 50) { $gone = !alive($tool_pid) and last; select undef, undef, undef, 0.1 }
    ok($gone, 'the '.$tool.' subprocess is gone');
    unless ($gone) { kill KILL => -$tool_pid; kill KILL => $tool_pid }
  };
}

done_testing;
