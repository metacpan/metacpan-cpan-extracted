use Test::More tests => 6;

use_ok ( 'Eval::Logic' );

my $and = Eval::Logic->new ( 'first_long_name && _second_long_name' );

ok ( $and->evaluate_if_true ( 'first_long_name', '_second_long_name' ),	'true and true' );
ok ( ! $and->evaluate_if_true ( 'first_long_name' ),	'true and false' );
ok ( ! $and->evaluate_if_true (),			'false and false' );
ok ( $and->evaluate_if_false (), 			'true and true' );
ok ( ! $and->evaluate_if_false ( '_second_long_name' ),	'true and false' );
