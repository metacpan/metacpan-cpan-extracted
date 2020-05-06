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

plan tests => 4;

expect_run(
  command => "PERL_RL=\"o=0\" $^X bin/ebug --backend \"$^X bin/ebug_backend_perl\" corpus/shebang_minus_l.pl",
  prompt  => 'ebug: ',
  quit    => 'q',
);

my $version = $Devel::ebug::VERSION;

# see https://rt.cpan.org/Public/Bug/Display.html?id=29956
# The -l option in the shebang of the program we are debugging should not cause
# 'uninitialized' warnings in the debugger.

# The tests here are only need to make sure there is some output.
# If there are warnings in the progam, they will show up instead of the
# empty output of the 'run to end' test, and it will fail.

expect_like(do{ no warnings 'uninitialized'; qr/Welcome to Devel::ebug $version/ }, 'Got welcome');
expect("r", qq{}, 'run to end');
expect_quit();
exit;
