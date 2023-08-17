#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

BEGIN {
   use_ok 'MCE';
   use_ok 'MCE::Flow';
   use_ok 'MCE::Shared::Queue';
   use_ok 'MCE::Shared';
}

my $q1 = MCE::Shared::Queue->new(); # non-shared
my $q2 = MCE::Shared->queue();      # shared
my $q;

sub check_enqueue {
   my ($description) = @_;
   is( join('', @{ $q->_get_aref() }), '12345', $description );
}

sub check_dequeue_nb {
   my ($description, $value) = @_;
   is( $value, '12345', $description );
   is( join('', @{ $q->_get_aref() }), '', 'queue emptied' );
}

sub check_dequeue_timed {
   my ($description, $success) = @_;
   is( $success, 1, $description );
}

## Non-shared tests

$q = $q1;

{
   $q1->enqueue('12345');
   check_enqueue('non-shared: check enqueue');
   check_dequeue_nb('non-shared: check dequeue_nb', $q1->dequeue_timed);

   my $start = MCE::Util::_time();
   my $ret = $q1->dequeue_timed(2.0); # no timed support for the non-shared object
   my $success = (!$ret && MCE::Util::_time() - $start < 1.0) ? 1 : 0;
   check_dequeue_timed('non-shared: check dequeue_timed', $success);
}

## Shared tests

$q = $q2;

MCE::Flow->init( max_workers => 1 );

mce_flow sub {
   my ($mce) = @_;
   my $w; # effect is waiting for the check (MCE->do) to complete

   $q->enqueue('12345');
   $w = MCE->do('check_enqueue', 'shared: check enqueue');
   $w = MCE->do('check_dequeue_nb', 'shared: check dequeue_nb', $q->dequeue_timed);

   my $start = MCE::Util::_time();
   my $ret = $q->dequeue_timed(2.0);
   my $success = (!$ret && MCE::Util::_time() - $start > 1.0) ? 1 : 0;
   $w = MCE->do('check_dequeue_timed', 'shared: check dequeue_timed', $success);

   return;
};

MCE::Flow->finish;

## Parallel demo

my $s = MCE::Util::_time();
my @r;

MCE->new(
   user_tasks => [{
      # consumers
      max_workers => 8,
      chunk_size  => 1,
      sequence    => [ 1, 40 ],
      gather      => \@r,
      user_func   => sub {
         # each worker calls dequeue_timed approximately 5 times
         if (defined(my $ret = $q->dequeue_timed(1.0))) {
            MCE->printf("$ret: time %0.3f, pid $$\n", MCE::Util::_time());
            MCE->gather($ret);
         }
      }
   },{
      # provider
      max_workers => 1,
      user_func   => sub {
         $q->enqueue($_) for 'a'..'d';
         sleep 1;
         $q->enqueue('e');
         sleep 1;
         $q->enqueue('f');
         sleep 1;
         $q->enqueue('g');
      }
   }]
)->run;

my $duration = MCE::Util::_time() - $s;
printf "%0.3f seconds\n", $duration;

my $success = (abs(5.0 - $duration) < 2.0) ? 1 : 0;
is( $success, 1, 'parallel demo duration' );
is( scalar(@r), 7, 'gathered size' );
is( join('', sort @r), 'abcdefg', 'gathered data' );

done_testing;

