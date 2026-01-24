use Test::More;

use Keyword::Anonymous::Object qw/object/;

object my $basic => {
	a => 1,
	b => 2,
	c => 3,
};

is($basic->a, 1);
is($basic->b, 2);
is($basic->c, 3);

ok($basic->set_a(2));
is($basic->a, 2);

object my $other => [
	{ a => 1 }, { b => 2 }, { c => 3 }
];

is($other->[0]->a, 1);
is($other->[1]->b, 2);
is($other->[2]->c, 3);

done_testing();
