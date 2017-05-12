#!perl

use strict;
use warnings;

use Test::More tests=>23;
#use Test::More 'no_plan';
use HTTP::LoadGen;
use Coro::Timer;
use IPC::ScoreBoard;
use AnyEvent;

#warn "\n\n";

my $sb;
my $starttime;

my $dur=$ENV{DURATION}||5;

for(
    [3, 5, 5, 3, [1], [1], [1], [1], [1]],
    [3, 2, 7, 27, [1], [1], [3], [5], [7], [9], [11]],
    [3, 4, 6, 18, [1], [1], [1], [1], [6], [11]],
    [1, 1, 1, 1, [1]],
   ) {
  my ($nproc, $start, $max, $totaltime, @slots)=@$_;

  $sb=SB::anon $max, 1, 1;

  HTTP::LoadGen::start_proc
      HTTP::LoadGen::create_proc $nproc, sub {
	my ($slot)=@_;
	$starttime=AE::now;
      }, sub {
	my ($procnr)=@_;
	HTTP::LoadGen::ramp_up
	    ($procnr, $nproc, $start, $max, $dur, sub {
	       my ($threadnr)=@_;
	       Coro::Timer::sleep 0.1*$dur;
	       SB::incr $sb, $threadnr, 0,
		   0+sprintf("%.0f", 10*(AE::now-$starttime)/$dur);
	     })->down;
      }, sub {
	my ($slot)=@_;
	#warn "$$: ProcExit($slot)--".sprintf("%.0f", 100*(AE::now-$starttime));
	SB::incr_extra $sb, 0,
	    0+sprintf("%.0f", 10*(AE::now-$starttime)/$dur);
      };
  for( my $i=0; $i<$max; $i++ ) {
    is_deeply [SB::get_all $sb, $i], $slots[$i],
      "test($nproc, $start, $max): slots[$i]";
  }
  is SB::get_extra($sb, 0), $totaltime, "test($nproc, $start, $max): totaltime";
}
