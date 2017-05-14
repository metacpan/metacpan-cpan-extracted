use Test::More tests => 6;

use_ok ( 'Eval::Logic' );

my $false = Eval::Logic->new ( '(FALSE)' );
ok ( ! $false->evaluate, 	'FALSE in list context' );

my $false_list = Eval::Logic->new ( 'TRUE', 'FALSE' );
my $exp = $false_list->expression;
like ( $exp, qr/\(TRUE\)\s*&&\s*\(FALSE\)/,		'implicit and list' );
ok ( ! $false_list->evaluate, 			'implicit and between true and false' );

my $list = Eval::Logic->new ( 'a', 'b || c' );
ok ( $list->evaluate_if_true ( 'a', 'b' ),	'implicit and between expressions evaluating as true' );
ok ( ! $list->evaluate_if_true ( 'b', 'c' ),	'implicit and between expressions evaluating as false' );

