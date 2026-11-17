use strict;
use warnings;
use Test::More;
{
  package Capture;
  sub capture { return {owner=>scalar(caller), args=>[@_]} }
  package NormalShim;
  sub step { return Capture::capture(@_) }
  package TailShim;
  sub step { goto &Capture::capture }
  package Consumer;
  sub direct { return Capture::capture(@_) }
  sub normal { return NormalShim::step(@_) }
  sub tail { return TailShim::step(@_) }
}
is(Consumer::direct('x')->{owner}, 'Consumer', 'direct call has consumer owner');
is(Consumer::normal('x')->{owner}, 'NormalShim', 'ordinary wrapper changes caller');
is(Consumer::tail('x')->{owner}, 'Consumer', 'tail-call shim preserves consumer owner');
is_deeply(Consumer::tail('x', 4)->{args}, ['x', 4], 'tail-call forwards arguments');
done_testing;
