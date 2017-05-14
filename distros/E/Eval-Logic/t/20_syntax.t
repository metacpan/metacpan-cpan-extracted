use Test::More tests => 9;

use_ok ( 'Eval::Logic' );

# These should give a syntax error

foreach ( 
  '&& a',
  '|| a',
  '(a',
  'a)',
  '!!',
  '! && a',
  'a ? b',
) {
  eval {
    Eval::Logic->new ( $_ );
  };
  like ( $@, qr/syntax error/, 			"syntax error in '$_'" );
}

# These should give a 'not followed by boolean operator' error.

foreach ( 
  'a ? a(c) : b'
) {
  eval {
    Eval::Logic->new ( $_ );
  };
  like ( $@, qr/not followed by boolean operator/, "detection of illegal function call in '$_'" );
}
