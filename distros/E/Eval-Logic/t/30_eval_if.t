use Test::More tests => 25;

use_ok ( 'Eval::Logic' );

my $and = Eval::Logic->new ( 'a && b' );

ok ( $and->evaluate_if_true ( 'a', 'b' ), 		'true and true' );
ok ( ! $and->evaluate_if_true ( 'a' ),			'true and false' );
ok ( ! $and->evaluate_if_true (),			'false and false' );
ok ( $and->evaluate_if_false (), 			'true and true' );
ok ( ! $and->evaluate_if_false ( 'b' ),			'true and false' );
ok ( ! $and->evaluate_if_false ( 'a', 'b' ),		'false and false' );

my $or = Eval::Logic->new ( 'a || b' );
ok ( $or->evaluate_if_true ( 'a', 'b' ),		'true or true' );
ok ( $or->evaluate_if_true ( 'a' ),			'true or false' );
ok ( ! $or->evaluate_if_true (),			'false or false' );
ok ( $or->evaluate_if_false (),				'true or true' );
ok ( $or->evaluate_if_false ( 'b' ),			'true or false' );
ok ( ! $or->evaluate_if_false ( 'a', 'b' ),		'false or false' );

my $not = Eval::Logic->new ( '!a' );
ok ( $not->evaluate_if_true (),				'not false' );
ok ( ! $not->evaluate_if_true ( 'a' ),			'not true' );
ok ( $not->evaluate_if_false ( 'a' ),			'not false' );
ok ( ! $not->evaluate_if_false (),			'not true' );

my $ternary = Eval::Logic->new ( 'a ? b : c');
ok ( $ternary->evaluate_if_true ( 'a', 'b' ),		'true then true else false' );
ok ( ! $ternary->evaluate_if_true ( 'a', 'c' ),		'true then false else true' );
ok ( ! $ternary->evaluate_if_true ( 'b' ),		'false then true else false' );
ok ( $ternary->evaluate_if_true ( 'c' ),		'false then false else true' );
ok ( $ternary->evaluate_if_false ( 'c' ),		'true then true else false' );
ok ( ! $ternary->evaluate_if_false ( 'b' ),		'true then false else true' );
ok ( ! $ternary->evaluate_if_false ( 'a', 'c' ),	'false then true else false' );
ok ( $ternary->evaluate_if_false ( 'a', 'b' ),		'false then false else true' );
