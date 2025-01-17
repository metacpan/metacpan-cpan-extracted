#!perl
use strict;
use warnings;
use Test::More;
use Linux::libperf::Simple "run";

eval {
  # needs privileges or some system config, see README.md
  Linux::libperf::Simple->new;
} or plan skip_all => "Cannot libperf: $@";

my @r0 = map { run(sub {}) } 1 .. 100;

my @r1 = map {
  run(sub { for (1 .. 100_000) { } } )
  } 1 .. 100;

@r0 = sort_inst(@r0);
@r1 = sort_inst(@r1);

cmp_ok($r0[0]{instructions}{val}, '<', $r1[0]{instructions}{val},
       "doing something takes more instructions than nothing");

note "r0[$_] = $r0[$_]{instructions}{val}" for 0 .. $#r0;
note "r1[$_] = $r1[$_]{instructions}{val}" for 0 .. $#r1;

done_testing();

sub sort_inst {
  sort { $a->{instructions}{val} <=> $b->{instructions}{val} } @_;
}
