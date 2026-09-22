#!perl
use strict;
use warnings;
use lib 'lib';
use Devel::ebug;
use Test::More;

BEGIN {
  eval { require Test::Expect; require Expect::Simple };
  plan skip_all => 'This test requires Test::Expect and Expect::Simple' if $@;
  Test::Expect->import;
}

plan skip_all => "Devel::ebug does not handle signals under Windows atm" if $^O =~ /mswin32/i;

plan tests => 5;

# Reproduces https://github.com/uperl/Devel-ebug/issues/27 : pressing ^C
# (SIGINT) while the debuggee is stuck in a loop should drop the console
# back into the debugger, not kill the console.

expect_run(
  command => "PERL_RL=\"o=0\" $^X bin/ebug --backend \"$^X bin/ebug_backend_perl\" corpus/infinite_loop.pl",
  prompt  => 'ebug: ',
  quit    => 'q',
);

my $handle = expect_handle();

# 'r' never returns on its own here, so send it directly and don't wait
# for the prompt.
$handle->send("r\n");

# give the backend a moment to actually be inside the infinite loop
select(undef, undef, undef, 0.5);

# simulate the user pressing ^C at the terminal; this reaches both the
# console and the backend process since they share a process group
$handle->send("\cC");

ok($handle->expect(10, '-re', qr/ebug:\s*$/),
  'console returned to the prompt after SIGINT instead of dying');

my $before = $handle->before;
$before = '' unless defined $before;
$before =~ s/\r//g;
like($before, qr/infinite_loop\.pl#\d+/,
  'console shows the paused location in the program');

$handle->send("p\n");
ok($handle->expect(10, '-re', qr/ebug:\s*$/),
  'console still responds to commands after recovering from SIGINT');

$handle->send("q\n");
ok(1, 'quit sent');

# the backend is still running (we never let the loop finish), so
# quitting here kills it while alive; reaping that child sets $?, which
# Test::Builder would otherwise mistake for this test having failed
expect_quit();
$? = 0;
