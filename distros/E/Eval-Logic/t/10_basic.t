use Test::More tests => 17;

use_ok ( 'Eval::Logic' );

my $and = Eval::Logic->new ( 'a && b' );

is_deeply ( [ sort $and->truth_values ], ['a', 'b'],		'truth values returned' );
is ( $and->expression, 'a && b',			'expression returned' );
ok ( $and->evaluate ( a => 1, b => 1 ), 		'true and true' );
ok ( ! $and->evaluate ( a => 1, b => 0 ), 		'true and false' );
ok ( ! $and->evaluate ( a => 0, b => 0 ),		'false and false' );

my $or = Eval::Logic->new ( 'a || b' );
ok ( $or->evaluate ( a => 1, b => 1 ),			'true or true' );
ok ( $or->evaluate ( a => 1, b => 0 ),			'true or false' );
ok ( ! $or->evaluate ( a => 0, b => 0 ),		'false or false' );

my $not = Eval::Logic->new ( '!a' );
ok ( $not->evaluate ( a => 0 ),				'not false' );
ok ( ! $not->evaluate ( a => 1 ),			'not true' );

my $ternary = Eval::Logic->new ( 'a ? b : c');
is_deeply ( [ sort $ternary->truth_values ], ['a', 'b', 'c'],	'truth values returned' );
is ( $ternary->expression, 'a ? b : c',			'expression returned' );
ok ( $ternary->evaluate ( a => 1, b => 1, c => 0 ),	'true then true else false' );
ok ( ! $ternary->evaluate ( a => 1, b => 0, c => 1 ),	'true then false else true' );
ok ( ! $ternary->evaluate ( a => 0, b => 1, c => 0 ),	'false then true else false' );
ok ( $ternary->evaluate ( a => 0, b => 0, c => 1 ),	'false then false else true' );

