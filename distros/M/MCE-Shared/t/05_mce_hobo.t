#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use Test::More;
use Time::HiRes 'sleep';

BEGIN {
   use_ok 'MCE::Hobo';
}

{
   my ( $cnt, @list, %pids, %ret ); local $_;
   my ( $come_then_i_pray ) = ( "さあ、私は祈る" . "Ǣ" );

   ok( 1, "spawning asynchronously" );

   MCE::Hobo->create( sub { sleep 1; sleep 1; "$come_then_i_pray $_" } ) for 1..3;

   %pids = map { $_ => undef } MCE::Hobo->list_pids;
   is ( scalar( keys %pids ), 3, 'check for unique pids' );

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

   is ( scalar keys %ret, 3, 'check for unique values' );

   for ( sort keys %ret ) {
      my $id = chop; s/ $//;
      is ( $_, $come_then_i_pray, "check for utf8 string $id" );
   };
}

{
   my ( $cnt, @procs ); local $_;

   for ( 1..3 ) {
      push @procs, MCE::Hobo->create( sub { sleep 1 for 1..9; return 1 } );
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

   my $cnt_start  = 0;
   my $cnt_finish = 0;

   MCE::Hobo->init(
      on_start => sub {
         my ( $pid, $id ) = @_;
         ++$cnt_start;
      },
      on_finish => sub {
         my ( $pid, $exit, $id, $sig, $err, @ret ) = @_;
         ++$cnt_finish;
      }
   );

   MCE::Hobo->create(\&task, 2);

   my $hobo = MCE::Hobo->wait_one();
   my $err  = $hobo->error // 'no error';
   my $res  = $hobo->result;
   my $pid  = $hobo->pid;

   is ( $res, "2", 'check wait_one' );

   my (@procs, @result); local $_;

   push @procs, MCE::Hobo->create(\&task, $_) for ( 1..3 );

   MCE::Hobo->wait_all();

   for my $hobo ( @procs ) {
      my $err = $hobo->error // 'no error';
      my $res = $hobo->result;
      my $pid = $hobo->pid;

      push @result, $res;
   }

   is ( "@result", "1 2 3", 'check wait_all' );
   is ( $cnt_start , 4, 'check on_start'  );
   is ( $cnt_finish, 4, 'check on_finish' );
}

is ( MCE::Hobo->finish(), undef, 'check finish' );

done_testing;

