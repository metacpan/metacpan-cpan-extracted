#!/usr/bin/env perl
# ABSTRACT: the REPL's !CMD (only the shell) and ?CMD (the shell, then the model), Ctrl-C during the command

use strict;
use warnings;
use utf8;
use Test2::V0;
use Encode qw( decode_utf8 );
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::SeqEngine;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::CLI::REPL;
use Langertha::Raider::SessionStore;

clear_engine_env();

# A raider CLI whose run answers without a model and keeps every prompt.
package My::App {
  use Moose;
  extends 'Langertha::Raider::CLI';
  has calls => ( is => 'ro', default => sub { [] } );
  sub run {
    my ( $self, $text ) = @_;
    push @{ $self->calls }, $text;
    return 'answer '.scalar @{ $self->calls };
  }
  __PACKAGE__->meta->make_immutable;
}

package My::SmallREPL {
  use Moose;
  extends 'Langertha::Raider::CLI::REPL';
  sub shell_output_limit { 100 }
  __PACKAGE__->meta->make_immutable;
}

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

sub input { my ( $text ) = @_; open my $fh, '<', \$text or die $!; $fh }

# Runs the code with file descriptor 1 on a file -- where a !CMD, which
# inherits the terminal, writes -- and returns what landed there.
sub fd1 {
  my ( $code ) = @_;
  my $file = path(tempdir(CLEANUP => 1))->child('fd1');
  STDOUT->flush;
  open my $saved, '>&', \*STDOUT or die $!;
  open STDOUT, '>', "$file" or die $!;
  my $ok = eval { $code->(); 1 };
  my $error = $@;
  STDOUT->flush;
  open STDOUT, '>&', $saved or die $!;
  die $error unless $ok;
  return decode_utf8($file->slurp_raw);
}

# Runs the REPL (or $class) on My::App with the lines; returns the app, what
# the REPL printed and what the commands wrote to file descriptor 1.
sub repl {
  my ( $lines, $class ) = @_;
  my $root = tempdir(CLEANUP => 1);
  my $app = My::App->new(root => $root, engine => 'openai', api_key => 'test', trace => 0, mission => 'M');
  my ( $fh, $read ) = buffer();
  my $fd1 = fd1(sub {
    ( $class // 'Langertha::Raider::CLI::REPL' )->new(
      app    => $app,
      output => Langertha::Raider::CLI::Output->new(out => $fh, color => 0),
      in     => input($lines),
    )->run;
  });
  return ( $app, $read->(), $fd1, $root );
}

subtest '!CMD runs in the shell only' => sub {
  my ( $app, $text, $fd1, $root ) = repl("!echo hi\n!  pwd\n! exit 3\n!echo grüß\n");
  is($app->calls, [], 'no model call');
  is($fd1, "hi\n".path($root)->realpath."\ngrüß\n", 'the commands wrote to the terminal, in --root');
  like($text, qr/^exit status 3$/m, 'a non-zero exit status is reported');
  is([ $text =~ /^exit status/mg ], [ 'exit status' ], 'only that one');
  unlike($text, qr/answer/, 'the model never answered');
};

subtest '?CMD runs in the shell, then sends the command to the model' => sub {
  my ( $app, $text, $fd1, $root ) = repl("?echo hi\n");
  is(scalar @{ $app->calls }, 1, 'exactly one model call');
  my ( $prompt ) = @{ $app->calls };
  like($prompt, qr/^\$ echo hi$/m, 'the prompt has the command');
  like($prompt, qr/^Result: exit status 0$/m, 'its exit status');
  like($prompt, qr/^hi$/m, 'and its output');
  like($prompt, qr/\Q$root\E/, 'and where it ran');
  like($text, qr/^hi\n.*^answer 1$/ms, 'the output shown live, then the answer');
  is($fd1, '', 'nothing bypassed the output');
};

subtest '?CMD: stderr, a failing command, where it runs, UTF-8' => sub {
  my ( $app, $text, undef, $root ) = repl("?echo out; echo err >&2; pwd; echo grüß; exit 4\n");
  my ( $prompt ) = @{ $app->calls };
  like($prompt, qr/^Result: exit status 4$/m, 'the exit status');
  like($prompt, qr/^out\nerr\n\Q${\ path($root)->realpath }\E\ngrüß$/m, 'stdout and stderr, in --root, decoded');
  like($text, qr/^exit status 4$/m, 'the exit status shown');
};

subtest '?CMD with a long output keeps its head and its tail' => sub {
  my $cmd = '?'.$^X.q{ -e 'print q{H} x 80, (q{MID}.q{DLE}) x 20, q{T} x 80'};
  my ( $app, $text ) = repl("$cmd\n", 'My::SmallREPL');
  my ( $prompt ) = @{ $app->calls };
  like($prompt, qr/^H{50}\n\[\.\.\. 180 characters omitted \.\.\.\]\nT{50}$/m, 'head, marker, tail');
  unlike($prompt, qr/MIDDLE/, 'the middle is gone');
  like($text, qr/MIDDLE/, 'but was shown');
};

subtest 'a bare ! or ? is a prompt' => sub {
  my ( $app, $text, $fd1 ) = repl("?\n!\n?   \n");
  is($app->calls, [ '?', '!', '?' ], 'sent as they are');
  is($fd1, '', 'no command ran');
};

subtest '!CMD stays out of the session journal, ?CMD is a turn in it' => sub {
  my $root = tempdir(CLEANUP => 1);
  my ( $out, $read_out ) = buffer();
  my ( $err, $read_err ) = buffer();
  @Test::Raider::SeqEngine::REQUESTS = ();
  local $ENV{ANSI_COLORS_DISABLED};
  my $fd1 = fd1(sub {
    My::Main->new(
      output => Langertha::Raider::CLI::Output->new(out => $out, color => 0),
      err    => $err,
      in     => input("!echo only\n"),
    )->run('-r', $root, '-e', 'openai', '-k', 'test', '-m', 'seq-model', '--no-trace', '-i');
  });
  is($fd1, "only\n", '!echo ran');
  is(scalar @Test::Raider::SeqEngine::REQUESTS, 0, 'no model request');
  my $store = Langertha::Raider::SessionStore->new(root => $root);
  is([ $store->ids ], [], 'no session started');

  fd1(sub {
    My::Main->new(
      output => Langertha::Raider::CLI::Output->new(out => $out, color => 0),
      err    => $err,
      in     => input("!echo only\n?echo sent\n"),
    )->run('-r', $root, '-e', 'openai', '-k', 'test', '-m', 'seq-model', '--no-trace', '-i');
  });
  my ( $id ) = $store->ids;
  ok($id, 'the ?CMD started the session');
  my $json = JSON::MaybeXS->new(utf8 => 1);
  my @events = map { $json->decode($_) } $store->path_of($id)->lines_raw({ chomp => 1 });
  my @user = map { $_->{content} } grep { $_->{type} eq 'message' && $_->{role} eq 'user' } @events;
  is(scalar @user, 1, 'one user turn');
  like($user[0], qr/^\$ echo sent\n.*^sent$/ms, 'the ?CMD with its output');
  unlike($user[0], qr/only/, 'the !CMD is not in it');
  is(scalar(grep { $_->{type} eq 'run.finished' && $_->{status} eq 'completed' } @events), 1, 'one completed run');
};

# Ctrl-C at a terminal reaches the whole foreground process group: raider
# and the command. The REPL runs in a process group of its own here, the
# test sends SIGINT to that group.
sub ctrl_c {
  my ( $prefix ) = @_;
  my $root    = tempdir(CLEANUP => 1);
  my $pidfile = path($root)->child('cmd.pid');
  my $outfile = path($root)->child('out');
  my $lines = $prefix.'echo $$ > '.$pidfile.'; sleep 60; echo not reached'."\nafter\n";
  my $pid = fork // die 'fork: '.$!;
  unless ($pid) {
    setpgrp(0, 0);
    open STDOUT, '>', "$outfile" or die $!;
    my $app = My::App->new(root => $root, engine => 'openai', api_key => 'test', trace => 0, mission => 'M');
    open my $fh, '>:encoding(UTF-8)', "$outfile.repl" or die $!;
    $fh->autoflush(1);
    Langertha::Raider::CLI::REPL->new(
      app    => $app,
      output => Langertha::Raider::CLI::Output->new(out => $fh, color => 0),
      in     => input($lines),
    )->run;
    path("$outfile.calls")->spew_utf8(join "\0", @{ $app->calls });
    POSIX::_exit(0);
  }
  my $started;
  for (1 .. 100) { last if $started = ( eval { $pidfile->slurp } // '' ) =~ /\d+\n/; select undef, undef, undef, 0.1 }
  kill INT => -$pid if $started;
  local $SIG{ALRM} = sub { kill KILL => -$pid };
  alarm 30;
  waitpid $pid, 0;
  my $status = $?;
  alarm 0;
  return ( $started, $status, path("$outfile.repl")->slurp_utf8, eval { path("$outfile.calls")->slurp_utf8 } // 'none',
    $outfile->slurp_utf8 );
}

subtest 'Ctrl-C during a !CMD ends the command, not raider' => sub {
  my ( $started, $status, $text, $calls, $fd1 ) = ctrl_c('!');
  ok($started, 'the command ran');
  is($status, 0, 'the REPL ended with its input');
  like($text, qr/^interrupted \(SIGINT\)$/m, 'the interruption is reported');
  unlike($fd1, qr/not reached/, 'the command ended');
  is($calls, 'after', 'the next line went to the model');
};

subtest 'Ctrl-C during a ?CMD ends the command and sends nothing' => sub {
  my ( $started, $status, $text, $calls ) = ctrl_c('?');
  ok($started, 'the command ran');
  is($status, 0, 'the REPL ended with its input');
  like($text, qr/^command interrupted \(SIGINT\), nothing sent to the model$/m, 'said so');
  unlike($text, qr/not reached/, 'the command ended');
  is($calls, 'after', 'only the next line went to the model');
};

done_testing;
