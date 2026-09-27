#!perl
use strict;
use warnings;
use lib 'lib';
use Devel::ebug;
use IO::Select;
use Proc::Background;
use String::Koremutake;
use Test::More;

plan skip_all => 'interrupt is not supported on Windows' if $^O eq 'MSWin32';
plan tests => 24;

# true if the program is still running after a moment: the answer to the
# queued basic request only arrives once it stops
sub still_running {
  my($ebug) = @_;
  return !IO::Select->new($ebug->socket)->can_read(0.5);
}

sub loop {
  my($program) = @_;
  my $ebug = Devel::ebug->new;
  $ebug->program($program || 'corpus/infinite_loop.pl');
  $ebug->load;
  return $ebug;
}

# --- run_nowait, interrupt, wait_for_stop ---------------------------------

{
  my $ebug = loop();
  ok(!$ebug->running, 'not running once loaded');
  is($ebug->interrupt, 0, 'interrupt does nothing when the program is not running');

  $ebug->run_nowait;
  ok($ebug->running, 'running after run_nowait');
  ok(still_running($ebug), 'and run_nowait returned while the program runs');

  ok(!eval { $ebug->eval('$i'); 1 }, 'other commands are refused while running');
  like($@, qr/the program is running; call wait_for_stop\(\) before 'eval'/, 'and say why');

  is($ebug->interrupt, 1, 'interrupt signals the running program');
  $ebug->wait_for_stop;
  ok(!$ebug->running, 'not running after wait_for_stop');
  ok(!$ebug->finished, 'the program was stopped, not finished');
  is($ebug->filename, 'corpus/infinite_loop.pl', 'in the program');
  like($ebug->line, qr/^[45]$/, 'inside its loop');
  ok($ebug->eval('$i') > 0, 'and commands work again');

  # a SIGINT that lands while the program is stopped must not stop the
  # next run straight away
  kill INT => $ebug->pid;
  $ebug->run_nowait;
  ok(still_running($ebug), 'a stale SIGINT does not stop the next run');
  $ebug->interrupt;
  $ebug->wait_for_stop;
  is($ebug->filename, 'corpus/infinite_loop.pl', 'and it can be interrupted again');
}

# --- a blocking run can be interrupted from a signal handler ---------------

{
  my $ebug = loop();
  local $SIG{ALRM} = sub { $ebug->interrupt };
  alarm 1;
  $ebug->run;
  alarm 0;
  ok(!$ebug->running, 'run returns once interrupted from a signal handler');
  is($ebug->filename, 'corpus/infinite_loop.pl', 'stopped in the program');
}

# --- the program's own pid is signalled, not a shell around it ------------

{
  my $ebug = loop('corpus/infinite_loop.pl "two words"');
  isnt($ebug->pid, $ebug->proc->pid, 'a program run through the shell has a different pid to proc');
  is($ebug->pid, $ebug->eval('$$'), 'pid is the program itself');
  $ebug->run_nowait;
  ok(still_running($ebug), 'running');
  $ebug->interrupt;
  $ebug->wait_for_stop;
  is($ebug->filename, 'corpus/infinite_loop.pl', 'interrupt reaches it through the shell');
}

# --- a program that finishes on its own -----------------------------------

{
  my $ebug = loop('corpus/calc.pl');
  $ebug->run_nowait;
  $ebug->wait_for_stop;
  ok($ebug->finished, 'wait_for_stop returns when the program finishes');
  is($ebug->interrupt, 0, 'and there is then nothing to interrupt');
}

# --- attach() has no process of its own to signal --------------------------

{
  my $k    = String::Koremutake->new;
  my $rand = int(rand(100_000));
  my $key  = $k->integer_to_koremutake($rand);
  my $proc = do {
    local $ENV{SECRET} = $key;
    Proc::Background->new({ die_upon_destroy => 1 },
      $^X, '-d:ebug::Backend', 'corpus/infinite_loop.pl');
  };
  my $ebug = Devel::ebug->new;
  $ebug->attach(3141 + ($rand % 1024), $key);
  $ebug->run_nowait;
  ok(!eval { $ebug->interrupt; 1 }, 'interrupt refuses a program it did not start');
  like($@, qr/only supported for programs started with load\(\)/, 'and says why');
  $proc->die;
}
