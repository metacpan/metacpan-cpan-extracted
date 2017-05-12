#!perl
use strict;
use warnings;

use Test::More;

use Log::Dispatchouli;

{
  package Xyzzy::Logger;
  use base 'Log::Dispatchouli';

  sub env_prefix { 'XYZZY' }
}

{
  local $ENV{DISPATCHOULI_DEBUG} = 1;
  local $ENV{XYZZY_DEBUG} = 0;
  my $d_logger = Log::Dispatchouli->new_tester;
  my $x_logger = Xyzzy::Logger->new_tester;

  ok(   $d_logger->is_debug, "DISPATCHOULI_ affects L::D logger");
  ok( ! $x_logger->is_debug, "...but XYZZY_ overrides for X::L");
}

{
  local $ENV{DISPATCHOULI_DEBUG} = 1;
  my $d_logger = Log::Dispatchouli->new_tester;
  my $x_logger = Xyzzy::Logger->new_tester;

  ok(   $d_logger->is_debug, "DISPATCHOULI_ affects L::D logger");
  ok(   $x_logger->is_debug, "...and X::L will use it with no XYZZY_");
}

{
  local $ENV{XYZZY_DEBUG} = 1;
  my $d_logger = Log::Dispatchouli->new_tester;
  my $x_logger = Xyzzy::Logger->new_tester;

  ok(   $x_logger->is_debug, "XYZZY_ affects X::L");
  ok( ! $d_logger->is_debug, "...but not L::D");
}

done_testing;
