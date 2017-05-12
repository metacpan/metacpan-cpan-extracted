
use Test::More tests => 20;

use Devel::Hook ();

my $counter;
BEGIN {
  $counter = 0;
}

BEGIN {
  is( $counter, 0, 'counter is zero' );
}

BEGIN {
  Devel::Hook->push_BEGIN_hook( 
    sub { 
      is( $counter, 0, 'in BEGIN hook, counter is still zero' ); 
      $counter++; # value: 1
    } );
}

BEGIN {
  is( $counter, 1, 'counter was incremented by BEGIN hook' );
  $counter++; # value: 2
}

BEGIN {
  Devel::Hook->unshift_BEGIN_hook( 
    sub { 
      is( $counter, 2, 'BEGIN block executed; in hook, counter is two' );
      $counter++; # value: 3
    } );
}

# so far, push or unshift did not make any difference.
# now let's look how it behaves wrt the BEGIN block
# where they are invoked

BEGIN {
  is( $counter, 3, 'counter incremented to 3 by BEGIN hook' );
  $counter++; # value: 4
  Devel::Hook->unshift_BEGIN_hook(
    sub {
      is( $counter, 5, 'in hook (with unshift), after the defining BEGIN block' );
      $counter++; # value: 6
    } );
  is( $counter, 4, 'BEGIN have not ended; hook did not run' );
  $counter++; # value: 5
}

BEGIN {
  is( $counter, 6, 'counter incremented to 6 by BEGIN hook' );
  $counter++; # value: 4
  Devel::Hook->push_BEGIN_hook(
    sub {
      is( $counter, 8, 'in hook (with push), after the defining BEGIN block' );
      $counter++; # value: 9
    } );
  is( $counter, 7, 'BEGIN have not ended; hook did not run' );
  $counter++;
}

# now playing with push and unshift together

BEGIN {
  is( $counter, 9, 'counter incremented to 9 by BEGIN hook' );
  $counter++; # value: 10
  Devel::Hook->push_BEGIN_hook( 
    sub { # 3
      is( $counter, 12, 'in third hook, after the defining BEGIN block' );
      $counter++; # value: 13
    },
    sub { # 4
      is( $counter, 13, 'in fourth hook, after the defining BEGIN block' );
      $counter++; # value: 14
    }, );
  Devel::Hook->unshift_BEGIN_hook( 
    sub { # 1
      is( $counter, 10, 'in first hook, after the defining BEGIN block' );
      $counter++; # value: 11
    },
    sub { # 2
      is( $counter, 11, 'in second hook, after the defining BEGIN block' );
      $counter++; # value: 12
    }, );
}

BEGIN {
  is( $counter, 14, 'after all BEGIN hooks' );
}

# now start playing with CHECK hooks (LIFO order)

BEGIN {
  # that runs after CHECK hook #2 and CHECK block #1
  Devel::Hook->unshift_CHECK_hook( #3
    sub {
      is( $counter, 17, 'in CHECK hook, counter is 17' );
      $counter++; # value: 18
    } );
}

BEGIN {
  is( $counter, 14, 'CHECK hook does not executed yet' );
  $counter++; # value: 15
}

CHECK { #1
  is( $counter, 16, 'counter was incremented by CHECK hook below' );
  $counter++; # value: 17
}

BEGIN {
  # this CHECK hook goes before the above CHECK block
  Devel::Hook->unshift_CHECK_hook( #2
    sub {
      is( $counter, 15, 'in CHECK hook, before above CHECK block and previous CHECK hook, counter is 15' );
      $counter++; # value: 16
    } );
}

