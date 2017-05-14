use Test::More tests => 7;

use_ok ( 'Eval::Logic' );

foreach ( 
  '123 && 456',
  '% || a',
  '&b',
  'abc.def',
  'TRUE or FALSE',
  'a and b'
) {
  eval {
    Eval::Logic->new ( $_ );
  };
  like ( $@, qr/[Ii]nvalid truth value/,		"value error in '$_'" );
}
