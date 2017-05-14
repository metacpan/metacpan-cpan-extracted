use Test::More tests => 5;

use_ok ( 'Eval::Logic' );

ok ( Eval::Logic->new ( 'TRUE' )->evaluate, 	'TRUE is true' );
ok ( ! Eval::Logic->new ( 'FALSE' )->evaluate, 	'FALSE is false' );

my $l = Eval::Logic->new ( 'TRUE || FALSE' );

eval { $l->evaluate ( TRUE => 1 ) };
like ( $@, qr/TRUE or FALSE specified as a variable/,	'error when specifying TRUE' );

eval { $l->evaluate ( FALSE => 0 ) };
like ( $@, qr/TRUE or FALSE specified as a variable/,	'error when specifying FALSE' );
