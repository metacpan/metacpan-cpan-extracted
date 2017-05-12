#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Fatal;
use Test::Refcount;
use constant HAVE_TEST_MEMORYGROWTH => eval { require Test::MemoryGrowth; };

use File::Temp qw( tempdir );
use Time::HiRes qw( sleep );

use IO::Async::Function;

use IO::Async::OS;

use IO::Async::Loop;

use constant AUT => $ENV{TEST_QUICK_TIMERS} ? 0.1 : 1;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

# by future
{
   my $function = IO::Async::Function->new(
      min_workers => 1,
      max_workers => 1,
      code => sub { return $_[0] + $_[1] },
   );

   ok( defined $function, '$function defined' );
   isa_ok( $function, "IO::Async::Function", '$function isa IO::Async::Function' );

   is_oneref( $function, '$function has refcount 1' );

   $loop->add( $function );

   is_refcount( $function, 2, '$function has refcount 2 after $loop->add' );

   is( $function->workers, 1, '$function has 1 worker' );
   is( $function->workers_busy, 0, '$function has 0 workers busy' );
   is( $function->workers_idle, 1, '$function has 1 workers idle' );

   my $future = $function->call(
      args => [ 10, 20 ],
   );

   isa_ok( $future, "Future", '$future' );

   is_refcount( $function, 2, '$function has refcount 2 after ->call' );

   is( $function->workers_busy, 1, '$function has 1 worker busy after ->call' );
   is( $function->workers_idle, 0, '$function has 0 worker idle after ->call' );

   wait_for { $future->is_ready };

   my ( $result ) = $future->get;

   is( $result, 30, '$result after call returns by future' );

   is( $function->workers_busy, 0, '$function has 0 workers busy after call returns' );
   is( $function->workers_idle, 1, '$function has 1 workers idle after call returns' );

   $loop->remove( $function );
}

# by callback
{
   my $function = IO::Async::Function->new(
      min_workers => 1,
      max_workers => 1,
      code => sub { return $_[0] + $_[1] },
   );

   $loop->add( $function );

   my $result;

   $function->call(
      args => [ 10, 20 ],
      on_return => sub { $result = shift },
      on_error  => sub { die "Test failed early - @_" },
   );

   wait_for { defined $result };

   is( $result, 30, '$result after call returns by callback' );

   $loop->remove( $function );
}

# Test queueing
{
   my $function = IO::Async::Function->new(
      min_workers => 1,
      max_workers => 1,
      code => sub { return $_[0] + $_[1] },
   );

   $loop->add( $function );

   my @result;

   my $f1 = $function->call(
      args => [ 1, 2 ],
      on_return => sub { push @result, shift },
      on_error  => sub { die "Test failed early - @_" },
   );
   my $f2 = $function->call(
      args => [ 3, 4 ],
      on_return => sub { push @result, shift },
      on_error  => sub { die "Test failed early - @_" },
   );

   is( $function->workers, 1, '$function->workers is still 1 after 2 calls' );

   isa_ok( $f1, "Future", '$f1' );
   isa_ok( $f2, "Future", '$f2' );

   wait_for { @result == 2 };

   is_deeply( \@result, [ 3, 7 ], '@result after both calls return' );

   is( $function->workers, 1, '$function->workers is still 1 after 2 calls return' );

   $loop->remove( $function );
}

# References
{
   my $function = IO::Async::Function->new(
      code => sub { return ref( $_[0] ), \$_[1] },
   );

   $loop->add( $function );

   my @result;

   $function->call(
      args => [ \'a', 'b' ],
      on_return => sub { @result = @_ },
      on_error  => sub { die "Test failed early - @_" },
   );

   wait_for { scalar @result };

   is_deeply( \@result, [ 'SCALAR', \'b' ], 'Call and result preserves references' );

   $loop->remove( $function );
}

# Exception throwing
{
   my $line = __LINE__ + 2;
   my $function = IO::Async::Function->new(
      code => sub { die shift },
   );

   $loop->add( $function );

   my $err;

   my $f = $function->call(
      args => [ "exception name" ],
      on_return => sub { },
      on_error  => sub { $err = shift },
   );

   wait_for { defined $err };

   like( $err, qr/^exception name at \Q$0\E line \d+\.$/, '$err after exception' );

   is_deeply( [ $f->failure ],
              [ "exception name at $0 line $line.", error => ],
              '$f->failure after exception' );

   $loop->remove( $function );
}

# Throwing exceptions with details
{
   my $function = IO::Async::Function->new(
      code => sub { die [ "A message\n", category => 123, 456 ] },
   );

   $loop->add( $function );

   my $f = wait_for_future $function->call(
      args => [],
   );

   is_deeply( [ $f->failure ],
              [ "A message\n", category => 123, 456 ],
              '$f->failure after exception with detail' );

   $loop->remove( $function );
}

# max_workers
{
   my $count = 0;

   my $function = IO::Async::Function->new(
      max_workers => 1,
      code => sub { $count++; die "$count\n" },
      exit_on_die => 0,
   );

   $loop->add( $function );

   my @errs;
   $function->call(
      args => [],
      on_return => sub { },
      on_error  => sub { push @errs, shift },
   );
   $function->call(
      args => [],
      on_return => sub { },
      on_error  => sub { push @errs, shift },
   );

   undef @errs;
   wait_for { scalar @errs == 2 };

   is_deeply( \@errs, [ "1", "2" ], 'Closed variables preserved when exit_on_die => 0' );

   $loop->remove( $function );
}

# exit_on_die
{
   my $count = 0;

   my $function = IO::Async::Function->new(
      max_workers => 1,
      code => sub { $count++; die "$count\n" },
      exit_on_die => 1,
   );

   $loop->add( $function );

   my @errs;
   $function->call(
      args => [],
      on_return => sub { },
      on_error  => sub { push @errs, shift },
   );
   $function->call(
      args => [],
      on_return => sub { },
      on_error  => sub { push @errs, shift },
   );

   undef @errs;
   wait_for { scalar @errs == 2 };

   is_deeply( \@errs, [ "1", "1" ], 'Closed variables preserved when exit_on_die => 1' );

   $loop->remove( $function );
}

# restart after exit
SKIP: {
   skip "This Perl does not support fork()", 4
      if not IO::Async::OS->HAVE_POSIX_FORK;

   my $function = IO::Async::Function->new(
      model => "fork",
      min_workers => 0,
      max_workers => 1,
      code => sub { $_[0] ? exit shift : return 0 },
   );

   $loop->add( $function );

   my $err;

   $function->call(
      args => [ 16 ],
      on_return => sub { $err = "" },
      on_error  => sub { $err = [ @_ ] },
   );

   wait_for { defined $err };

   # Not sure what reason we might get - need to check both
   ok( $err->[0] eq "closed" || $err->[0] eq "exit", '$err->[0] after child death' )
      or diag( 'Expected "closed" or "exit", found ' . $err->[0] );

   is( scalar $function->workers, 0, '$function->workers is now 0' );

   $function->call(
      args => [ 0 ],
      on_return => sub { $err = "return" },
      on_error  => sub { $err = [ @_ ] },
   );

   is( scalar $function->workers, 1, '$function->workers is now 1 again' );

   undef $err;
   wait_for { defined $err };

   is( $err, "return", '$err is "return" after child nondeath' );

   $loop->remove( $function );
}

# init_code
{
   my $captured;
   my $function = IO::Async::Function->new(
      init_code => sub { $captured = 10 },
      code => sub { return $captured },
   );

   $loop->add( $function );

   my $f = wait_for_future $function->call(
      args => [],
   );

   is( scalar $f->get, 10, 'init_code can side-effect captured variables' );

   $loop->remove( $function );
}

## Now test that parallel runs really are parallel
{
   # touch $dir/$n in each worker, touch $dir/done to finish it
   sub touch
   {
      my ( $file ) = @_;

      open( my $fh, ">", $file ) or die "Cannot write $file - $!";
      close( $fh );
   }

   my $function = IO::Async::Function->new(
      min_workers => 3,
      code => sub {
         my ( $dir, $n ) = @_;
         my $file = "$dir/$n";

         touch( $file );

         # Wait for synchronisation
         sleep 0.1 while ! -e "$dir/done";

         unlink( $file );

         return $n;
      },
   );

   $loop->add( $function );

   is( scalar $function->workers, 3, '$function->workers is 3' );

   my $dir = tempdir( CLEANUP => 1 );

   my %ret;

   foreach my $id ( 1, 2, 3 ) {
      $function->call(
         args => [ $dir, $id ],
         on_return => sub { $ret{$id} = shift },
         on_error  => sub { die "Test failed early - @_" },
      );
   }

   wait_for { -e "$dir/1" and -e "$dir/2" and -e "$dir/3" };

   ok( 1, 'synchronise files created' );

   # Synchronize deleting them;
   touch( "$dir/done" );

   undef %ret;
   wait_for { keys %ret == 3 };

   unlink( "$dir/done" );

   is_deeply( \%ret, { 1 => 1, 2 => 2, 3 => 3 }, 'ret keys after parallel run' );

   is( scalar $function->workers, 3, '$function->workers is still 3' );

   $loop->remove( $function );
}

# Test for idle timeout
{
   my $function = IO::Async::Function->new(
      min_workers => 0,
      max_workers => 1,
      idle_timeout => 2 * AUT,
      code => sub { return $_[0] },
   );

   $loop->add( $function );

   my $result;

   $function->call(
      args => [ 1 ],
      on_result => sub { $result = $_[0] },
   );

   wait_for { defined $result };

   is( $function->workers, 1, '$function has 1 worker after call' );

   my $waited;
   $loop->watch_time( after => 1 * AUT, code => sub { $waited++ } );

   wait_for { $waited };

   is( $function->workers, 1, '$function still has 1 worker after short delay' );

   undef $result;
   $function->call(
      args => [ 1 ],
      on_result => sub { $result = $_[0] },
   );

   wait_for { defined $result };

   undef $waited;
   $loop->watch_time( after => 3 * AUT, code => sub { $waited++ } );

   wait_for { $waited };

   is( $function->workers, 0, '$function has 0 workers after longer delay' );

   $loop->remove( $function );
}

# Restart
{
   my $value = 1;

   my $function = IO::Async::Function->new(
      code => sub { return $value },
   );

   $loop->add( $function );

   my $result;
   $function->call(
      args => [],
      on_return => sub { $result = shift },
      on_error  => sub { die "Test failed early - @_" },
   );

   wait_for { defined $result };

   is( $result, 1, '$result before restart' );

   $value = 2;
   $function->restart;

   undef $result;
   $function->call(
      args => [],
      on_return => sub { $result = shift },
      on_error  => sub { die "Test failed early - @_" },
   );

   wait_for { defined $result };

   is( $result, 2, '$result after restart' );

   undef $result;
   $function->call(
      args => [],
      on_return => sub { $result = shift },
      on_error  => sub { die "Test failed early - @_" },
   );

   $function->restart;

   wait_for { defined $result };

   is( $result, 2, 'call before restart still returns result' );

   $loop->remove( $function );
}

# max_worker_calls
{
   my $counter;
   my $function = IO::Async::Function->new(
      max_workers      => 1,
      max_worker_calls => 2,
      code => sub { return ++$counter; }
   );

   $loop->add( $function );

   my $result;
   $function->call(
      args => [],
      on_return => sub { $result = shift },
      on_error  => sub { die "Test failed early - @_" },
   );
   wait_for { defined $result };
   is( $result, 1, '$result from first call' );

   undef $result;
   $function->call(
      args => [],
      on_return => sub { $result = shift },
      on_error  => sub { die "Test failed early - @_" },
   );
   wait_for { defined $result };
   is( $result, 2, '$result from second call' );

   undef $result;
   $function->call(
      args => [],
      on_return => sub { $result = shift },
      on_error  => sub { die "Test failed early - @_" },
   );
   wait_for { defined $result };
   is( $result, 1, '$result from third call' );

   $loop->remove( $function );
}

# Cancellation of sent calls
{
   my $function = IO::Async::Function->new(
      max_workers => 1,
      code => sub {
         return 123;
      },
   );

   $loop->add( $function );

   my $f1 = $function->call( args => [] );
   $f1->cancel;

   my $f2 = $function->call( args => [] );

   wait_for { $f2->is_ready };

   is( scalar $f2->get, 123, 'Result of function call after cancelled call' );

   $loop->remove( $function );
}

# Cancellation of pending calls
{
   my $function = IO::Async::Function->new(
      max_workers => 1,
      code => do { my $state; sub {
         my $oldstate = $state;
         $state = shift;
         return $oldstate;
      } },
   );

   $loop->add( $function );

   # Queue 3 calls but immediately cancel the middle one
   my ( $f1, $f2, $f3 ) = map {
      $function->call( args => [ $_ ] )
   } 1 .. 3;

   $f2->cancel;

   wait_for { $f1->is_ready and $f3->is_ready };

   is( scalar $f1->get, undef, '$f1 result is undef' );
   is( scalar $f3->get, 1, '$f3 result is 1' );

   $loop->remove( $function );
}

# Leak test (RT99552)
if( HAVE_TEST_MEMORYGROWTH ) {
   diag( "Performing memory leak test" );

   my $function = IO::Async::Function->new(
      max_workers => 8,
      code => sub {},
   );

   $loop->add( $function );

   Test::MemoryGrowth::no_growth( sub {
      $function->restart;
      $function->call( args => [] )->get;
   }, calls => 100,
      'IO::Async::Function calls do not leak memory' );

   $loop->remove( $function );
   undef $function;
}

done_testing;
