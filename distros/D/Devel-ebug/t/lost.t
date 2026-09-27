#!perl
use strict;
use warnings;
use lib 'lib';
use Devel::ebug;
use Test::More;

plan skip_all => 'needs kill() on a real process' if $^O eq 'MSWin32';
plan tests => 9;

sub loaded {
  my $ebug = Devel::ebug->new;
  $ebug->program(shift);
  $ebug->load;
  return $ebug;
}

my $lost = qr/^Devel::ebug: lost the connection to the debugger; the program \(pid \d+\) /;

# --- the program is killed while stopped ---------------------------------

{
  my $ebug = loaded('corpus/calc.pl');
  kill KILL => $ebug->pid;

  # without handling, the write to the dead socket raised SIGPIPE and the
  # frontend died on the spot, so just getting past this is the test
  ok(!eval { $ebug->step; 1 }, 'a command fails once the program has been killed');
  like($@, qr/${lost}was killed by signal 9/, 'saying how it ended');
  ok(!eval { $ebug->eval('1'); 1 }, 'and so does the next one');
  like($@, $lost, 'with the same error');
}

# --- the program exits without the debugger's cleanup running -------------

{
  my $ebug = loaded('corpus/calc.pl');
  ok(!eval { $ebug->eval('require POSIX; POSIX::_exit(3)'); 1 }, 'a command that ends the program fails');
  like($@, qr/${lost}exited with status 3/, 'with its exit status');
}

# --- the program is killed while running ----------------------------------

{
  my $ebug = loaded('corpus/infinite_loop.pl');
  $ebug->run_nowait;
  kill KILL => $ebug->pid;
  ok(!eval { $ebug->wait_for_stop; 1 }, 'wait_for_stop fails if the program is killed while running');
  like($@, $lost, 'saying so');
  ok(!$ebug->running, 'and the program is no longer considered running');
}
