#!/usr/bin/perl
use Devel::ContinuousProfiler;
X::a(1) for 1 .. 100_000;

package X;
sub a { b(shift) }
sub b { c(shift) }
sub c { d(shift) }
sub d {   shift  }
