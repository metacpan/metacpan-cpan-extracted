#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
   use_ok 'MCE::Hobo';
   use_ok 'MCE::Shared';
   use_ok 'MCE::Shared::Condvar';
}

my $cv = MCE::Shared->condvar();

## One must explicitly start the shared-server for condvars and queues.
## Not necessary otherwise when IO::FDPass is available.

MCE::Shared->start() unless $INC{'IO/FDPass.pm'};

## timedwait, wait, broadcast - --- --- --- --- --- --- --- --- --- --- --- ---

{
   my @procs;
   my $start = MCE::Util::_time();

   push @procs, MCE::Hobo->new( sub { $cv->timedwait(10); 1 } );
   push @procs, MCE::Hobo->new( sub { $cv->timedwait(20); 1 } );
   push @procs, MCE::Hobo->new( sub { $cv->wait; 1 } );

   sleep(1) for 1..2;
   $cv->broadcast;

   ok( $procs[0]->join, 'shared condvar, check broadcast to process1' );
   ok( $procs[1]->join, 'shared condvar, check broadcast to process2' );
   ok( $procs[2]->join, 'shared condvar, check broadcast to process3' );

   cmp_ok(
      MCE::Util::_time() - $start, '<', 9,
      'shared condvar, check processes exited timely'
   );
}

done_testing;

