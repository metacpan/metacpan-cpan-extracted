
use Test::More;

BEGIN {
  if ( $] < 5.009004 ) {
    plan( tests => 21 );
  } else {
    plan( skip_all => "unsolved issues for 5.009004+" ); # FIXME
  }

}

# this script is not really a test of the module

# it investigates Perl semantics for the special
# code blocks - so we can use what we learn
# in writing the proper tests

use Devel::Hook (); # only for _has_support_for

my $block;

# BEGIN blocks execute in FIFO order
BEGIN {
  is( $block, undef, 'at BEGIN #1 (hook)' );
  $block = 'BEGIN #1';
}
BEGIN {
  is( $block, 'BEGIN #1', 'at BEGIN #2 (hook)' );
  $block = 'BEGIN #2';
}
BEGIN {
  is( $block, 'BEGIN #2', 'at BEGIN #3 (hook)' );
  $block = 'BEGIN #3';
}
BEGIN {
  is( $block, 'BEGIN #3', 'at BEGIN #4 (hook)' );
  $block = 'BEGIN #4';
}


BEGIN {
  SKIP : {
    unless ( Devel::Hook->_has_support_for( 'UNITCHECK' ) ) {
      $block = 'UNITCHECK #4';
      skip "UNITCHECK not supported", 4;
    }

    # happily, UNITCHECK blocks work inside eval
    # UNITCHECK blocks execute in LIFO order
    eval q[

      UNITCHECK {
        is( $block, 'UNITCHECK #3', 'at UNITCHECK #4 (hook)' );
        $block = 'UNITCHECK #4';
      }
      UNITCHECK {
        is( $block, 'UNITCHECK #2', 'at UNITCHECK #3 (hook)' );
        $block = 'UNITCHECK #3';
      }
      UNITCHECK {
        is( $block, 'UNITCHECK #1', 'at UNITCHECK #2 (hook)' );
        $block = 'UNITCHECK #2';
      }
      UNITCHECK {
        is( $block, 'BEGIN #4', 'at UNITCHECK #1 (hook)' );
        $block = 'UNITCHECK #1';
      }

    ];
  }

}

# CHECK blocks executes in LIFO order
CHECK {
  is( $block, 'CHECK #3', 'at CHECK #4 (hook)' );
  $block = 'CHECK #4';
}
CHECK {
  is( $block, 'CHECK #2', 'at CHECK #3 (hook)' );
  $block = 'CHECK #3';
}
CHECK {
  is( $block, 'CHECK #1', 'at CHECK #2 (hook)' );
  $block = 'CHECK #2';
}
CHECK {
  is( $block, 'UNITCHECK #4', 'at CHECK #1 (hook)' );
  $block = 'CHECK #1';
}


# INIT blocks executes in FIFO order
INIT {
  is( $block, 'CHECK #4', 'at INIT #1 (hook)' );
  $block = 'INIT #1';
}
INIT {
  is( $block, 'INIT #1', 'at INIT #2 (hook)' );
  $block = 'INIT #2';
}
INIT {
  is( $block, 'INIT #2', 'at INIT #3 (hook)' );
  $block = 'INIT #3';
}
INIT {
  is( $block, 'INIT #3', 'at INIT #4 (hook)' );
  $block = 'INIT #4';
}

is( $block, 'INIT #4', 'after BEGIN, UNITCHECK, CHECK, and INIT hooks, before END hooks' );
$block = 'RUNTIME';

# END blocks executes in LIFO order
END {
  is( $block, 'END #3', 'at END #4 (hook)' );
  $block = 'END #4';
}
END {
  is( $block, 'END #2', 'at END #3 (hook)' );
  $block = 'END #3';
}
END {
  is( $block, 'END #1', 'at END #2 (hook)' );
  $block = 'END #2';
}
END {
  is( $block, 'RUNTIME', 'at END #1 (hook)' );
  $block = 'END #1';
}
