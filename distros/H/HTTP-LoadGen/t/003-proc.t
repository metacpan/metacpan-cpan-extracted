#!perl

use strict;
use warnings;

use Test::More tests=>7;
#use Test::More 'no_plan';
use HTTP::LoadGen;

use IPC::ScoreBoard;
use Coro;
use Coro::Timer ();

my $sb=SB::anon 3, 3;

my $proc=HTTP::LoadGen::create_proc 3, sub {
  my ($slot)=@_;
  SB::incr $sb, $slot, 0, 10+$slot;
  async {SB::incr $sb, $slot, 1, $slot+10};
}, sub {
  my ($slot)=@_;
  SB::incr $sb, $slot, 0, 10+$slot;
}, sub {
  my ($slot)=@_;
  SB::incr $sb, $slot, 2, 10+$slot;
  kill 11, $$ if $slot==2;
  return $slot+7;
};

Coro::Timer::sleep 0.1;

is_deeply [SB::get_all $sb, 0], [10, 10, 0], 'slot 0';
is_deeply [SB::get_all $sb, 1], [11, 11, 0], 'slot 1';
is_deeply [SB::get_all $sb, 2], [12, 12, 0], 'slot 2';

my $status=HTTP::LoadGen::start_proc $proc;

is_deeply [SB::get_all $sb, 0], [20, 10, 10], 'slot 0';
is_deeply [SB::get_all $sb, 1], [22, 11, 11], 'slot 1';
is_deeply [SB::get_all $sb, 2], [24, 12, 12], 'slot 2';

is_deeply [map {$#{$_}=1; $_} sort {$a->[0]<=>$b->[0]} values %$status],
  [[0,11], [7,0], [8,0]],
  "HTTP::LoadGen::start_proc result";
