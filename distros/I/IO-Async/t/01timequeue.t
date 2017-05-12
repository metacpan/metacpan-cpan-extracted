#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use IO::Async::Internals::TimeQueue;

my $queue = IO::Async::Internals::TimeQueue->new;

ok( defined $queue, '$queue defined' );
isa_ok( $queue, "IO::Async::Internals::TimeQueue", '$queue isa IO::Async::Internals::TimeQueue' );

is( $queue->next_time, undef, '->next_time when empty is undef' );

ok( exception { $queue->enqueue( code => sub { "DUMMY" } ) },
    'enqueue no time fails' );

ok( exception { $queue->enqueue( time => 123 ) },
    'enqueue no code fails' );

ok( exception { $queue->enqueue( time => 123, code => 'HELLO' ) },
    'enqueue code not CODE ref fails' );

$queue->enqueue( time => 1000, code => sub { "DUMMY" } );
is( $queue->next_time, 1000, '->next_time after single enqueue' );

my $fired = 0;

$queue->enqueue( time => 500, code => sub { $fired = 1; } );
is( $queue->next_time, 500, '->next_time after second enqueue' );

my $count = $queue->fire( now => 700 );

is( $fired, 1, '$fired after fire at time 700' );
is( $count, 1, '$count after fire at time 700' );
is( $queue->next_time, 1000, '->next_time after fire at time 700' );

$count = $queue->fire( now => 900 );

is( $count, 0, '$count after fire at time 900' );
is( $queue->next_time, 1000, '->next_time after fire at time 900' );

$count = $queue->fire( now => 1200 );

is( $count, 1, '$count after fire at time 1200' );
is( $queue->next_time, undef, '->next_time after fire at time 1200' );

$queue->enqueue( time => 1300, code => sub{ $fired++; } );
$queue->enqueue( time => 1301, code => sub{ $fired++; } );

$count = $queue->fire( now => 1400 );

is( $fired, 3, '$fired after fire at time 1400' );
is( $count, 2, '$count after fire at time 1400' );
is( $queue->next_time, undef, '->next_time after fire at time 1400' );

my $id = $queue->enqueue( time => 1500, code => sub { $fired++ } );
$queue->enqueue( time => 1505, code => sub { $fired++ } );

is( $queue->next_time, 1500, '->next_time before cancel' );

$queue->cancel( $id );

is( $queue->next_time, 1505, '->next_time after cancel' );

$fired = 0;
$count = $queue->fire( now => 1501 );

is( $fired, 0, '$fired after fire at time 1501' );
is( $count, 0, '$count after fire at time 1501' );

$count = $queue->fire( now => 1510 );

is( $fired, 1, '$fired after fire at time 1510' );
is( $count, 1, '$count after fire at time 1510' );

# Performance for large collections
{
   foreach my $t ( 2000 .. 2100 ) {
      $queue->enqueue( time => $t, code => sub {} );
   }

   foreach my $t ( 2000 .. 2100 ) {
      $queue->next_time == $t or fail( "Failed for large collection - expected $t" ), last;
      $queue->fire( now => $t );
   }

   ok( "Large collection" );
}

done_testing;
