
use Test::More tests => 21;

use Devel::Hook ();

my $block;

# this script is to investigate the execution
# order of blocks according to the order of blocks
# in arrays

# conclusion: blocks at the start execute first 
#   and the ones at the end execute last.
#   So there is no confusion about the FIFO or LIFO
#   nature of BLOCKS as defined syntactically.

BEGIN {
  Devel::Hook->unshift_BEGIN_hook(
    sub {
      is( $block, undef, 'at BEGIN #1 (hook)' );
      $block = 'BEGIN #1';
    },
    sub {
      is( $block, 'BEGIN #1', 'at BEGIN #2 (hook)' );
      $block = 'BEGIN #2';
    },
    sub {
      is( $block, 'BEGIN #2', 'at BEGIN #3 (hook)' );
      $block = 'BEGIN #3';
    },
    sub {
      is( $block, 'BEGIN #3', 'at BEGIN #4 (hook)' );
      $block = 'BEGIN #4';
    },
  );

  if ( Devel::Hook->_has_support_for( 'UNITCHECK' ) ) {

    Devel::Hook->unshift_UNITCHECK_hook(
      sub {
        is( $block, 'BEGIN #4', 'at UNITCHECK #1 (hook)' );
        $block = 'UNITCHECK #1';
      },
      sub {
        is( $block, 'UNITCHECK #1', 'at UNITCHECK #2 (hook)' );
        $block = 'UNITCHECK #2';
      },
      sub {
        is( $block, 'UNITCHECK #2', 'at UNITCHECK #3 (hook)' );
        $block = 'UNITCHECK #3';
      },
      sub {
        is( $block, 'UNITCHECK #3', 'at UNITCHECK #4 (hook)' );
        $block = 'UNITCHECK #4';
      },
    );

  } else {
    Devel::Hook->push_BEGIN_hook(
      sub {
        SKIP: {
          $block = 'UNITCHECK #4';
          skip "UNITCHECK not supported", 4;
        } }
    );
  }

  Devel::Hook->unshift_CHECK_hook(
    sub {
      is( $block, 'UNITCHECK #4', 'at CHECK #1 (hook)' );
      $block = 'CHECK #1';
    },
    sub {
      is( $block, 'CHECK #1', 'at CHECK #2 (hook)' );
      $block = 'CHECK #2';
    },
    sub {
      is( $block, 'CHECK #2', 'at CHECK #3 (hook)' );
      $block = 'CHECK #3';
    },
    sub {
      is( $block, 'CHECK #3', 'at CHECK #4 (hook)' );
      $block = 'CHECK #4';
    },
  );

  Devel::Hook->unshift_INIT_hook(
    sub {
      is( $block, 'CHECK #4', 'at INIT #1 (hook)' );
      $block = 'INIT #1';
    },
    sub {
      is( $block, 'INIT #1', 'at INIT #2 (hook)' );
      $block = 'INIT #2';
    },
    sub {
      is( $block, 'INIT #2', 'at INIT #3 (hook)' );
      $block = 'INIT #3';
    },
    sub {
      is( $block, 'INIT #3', 'at INIT #4 (hook)' );
      $block = 'INIT #4';
    },
  );

  Devel::Hook->unshift_END_hook(
    sub {
      is( $block, 'RUNTIME', 'at END #1 (hook)' );
      $block = 'END #1';
    },
    sub {
      is( $block, 'END #1', 'at END #2 (hook)' );
      $block = 'END #2';
    },
    sub {
      is( $block, 'END #2', 'at END #3 (hook)' );
      $block = 'END #3';
    },
    sub {
      is( $block, 'END #3', 'at END #4 (hook)' );
      $block = 'END #4';
    },
  );


}

is( $block, 'INIT #4', 'after BEGIN, UNITCHECK, CHECK, and INIT hooks, before END hooks' );
$block = 'RUNTIME';

