use Test::More;
BEGIN {
  if (eval "use PPI;1") {
    plan tests => 20;
  } else {
    plan skip_all => "PPI not available\n";
  }
}
use strict;
use warnings;
use Devel::DumpTrace::PPI;

# test settings for $Devel::DumpTrace::TRACE

for my $lev (qw(1 2 3 4 5 6 7 11 12 13 314159 102 106 999)) {
  $Devel::DumpTrace::TRACE = $lev;
  ok($Devel::DumpTrace::TRACE == $lev, "trace level $lev");
}

$Devel::DumpTrace::TRACE = 'default';
ok($Devel::DumpTrace::TRACE == 3, "trace level default");

$Devel::DumpTrace::TRACE = 'normal';
ok($Devel::DumpTrace::TRACE == 3, "trace level normal");

$Devel::DumpTrace::TRACE = 'quiet';
ok($Devel::DumpTrace::TRACE == 1, "trace level quiet");

$Devel::DumpTrace::TRACE = 'verbose';
ok($Devel::DumpTrace::TRACE == 5, "trace level verbose");

$Devel::DumpTrace::TRACE = 'verbose,package';
ok($Devel::DumpTrace::TRACE == 105, "trace level package-verbose");

$Devel::DumpTrace::TRACE = 'quiet,package';
ok($Devel::DumpTrace::TRACE == 101, "trace level package-quiet");
