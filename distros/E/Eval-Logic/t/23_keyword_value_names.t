use Test::More tests => 6;

use_ok ( 'Eval::Logic' );

my $and = Eval::Logic->new ( 'push && shift' );

ok ( $and->evaluate_if_true ( 'push', 'shift' ),	'true and true' );
ok ( ! $and->evaluate_if_true ( 'push' ),		'true and false' );
ok ( ! $and->evaluate_if_true (),			'false and false' );
ok ( $and->evaluate_if_false (), 			'true and true' );
ok ( ! $and->evaluate_if_false ( 'shift' ),		'true and false' );
