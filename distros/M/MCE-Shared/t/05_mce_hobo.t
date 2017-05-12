#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Time::HiRes qw(sleep);

BEGIN {
   use_ok 'MCE::Hobo';
}

{
   my ( $cnt, @procs, @list, %ret ); local $_;

   ok( 1, "spawning asynchronously" );

   @procs = MCE::Hobo->new( sub { sleep 2; $_ } ) for ( 1 .. 3 );

   @list = MCE::Hobo->list_running;
   is ( scalar @list, 3, 'check list_running' );

   @list = MCE::Hobo->list_joinable;
   is ( scalar @list, 0, 'check list_joinable' );

   @list = MCE::Hobo->list;
   is ( scalar @list, 3, 'check list' );

   is ( MCE::Hobo->pending, 3, 'check pending' );

   $cnt = 0;

   for ( @list ) {
      ++$cnt;
      is ( $_->is_running, 1, 'check is_running hobo'.$cnt );
      is ( $_->is_joinable, '', 'check is_joinable hobo'.$cnt );
   }

   $cnt = 0;

   for ( @list ) {
      ++$cnt; $ret{ $_->join } = 1;
      is ( $_->error, undef, 'check error hobo'.$cnt );
   }

   is ( scalar keys %ret, 3, 'check unique tid value' );
}

{
   my ( $cnt, @procs ); local $_;

   for ( 1 .. 3 ) {
      push @procs, MCE::Hobo->new( sub { sleep 1 for 1 .. 9; return 1 } );
   }

   $procs[0]->exit();
   $procs[1]->exit();
   $procs[2]->kill('QUIT');

   $cnt = 0;

   for ( @procs ) {
      ++$cnt;
      is ( $_->join, undef, 'check exit hobo'.$cnt );
   }
}

{
   sub task {
      my ( $id ) = @_;

      return $id;
   }

   MCE::Hobo->create(\&task, 2);

   my $hobo = MCE::Hobo->waitone;
   my $err = $hobo->error // 'no error';
   my $res = $hobo->result;
   my $pid = $hobo->pid;

   is ( $res, "2", 'check waitone' );

   my @result; local $_;

   MCE::Hobo->create(\&task, $_) for ( 1 .. 3 );

   my @hobos = MCE::Hobo->waitall;

   for my $hobo ( @hobos ) {
      my $err = $hobo->error // 'no error';
      my $res = $hobo->result;
      my $pid = $hobo->pid;

      push @result, $res;
   }

   is ( "@result", "1 2 3", 'check waitall' );
}

is ( MCE::Hobo->finish(), undef, 'check finish' );

done_testing;

