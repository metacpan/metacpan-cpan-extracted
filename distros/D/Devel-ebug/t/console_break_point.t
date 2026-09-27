#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More;

BEGIN {
  eval { require Test::Expect; require Expect::Simple };
  plan skip_all => 'This test requires Test::Expect and Expect::Simple' if $@;
  Test::Expect->import;
}

plan tests => 7;

expect_run(
  command => "PERL_RL=\"o=0\" $^X bin/ebug --backend \"$^X bin/ebug_backend_perl\" corpus/calc_oo.pl",
  prompt  => 'ebug: ',
  quit    => 'q',
);

# a condition ending in a number must not be read as "b FILE LINE"
expect_send('b Calc::fib1 $_[1] == 3', 'set a subroutine break point with a condition');
expect_send('r', 'run to it');
expect_like(qr{\ACalc::fib1\(corpus/lib/Calc\.pm#15\):}, 'stopped at the start of the subroutine');
expect_send('s', 'step past its argument unpacking');
expect_send('e $n', 'look at its argument');
expect_like(qr/\A3(?:\n|\z)/, 'the condition held');
expect_quit();
