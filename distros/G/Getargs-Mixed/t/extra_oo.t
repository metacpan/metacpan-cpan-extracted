# vim: set ft=perl :

use Test::More tests => 45;
BEGIN { use_ok('Getargs::Mixed') };

sub foo {
	my %args = Getargs::Mixed->new->parameters([ qw( x y z * ) ], @_);

	is($args{x}, 1);
	is($args{y}, 2);
	is($args{z}, 3);
	ok($args{a} == 4 || $args{'*'}[0] == 4);
}

foo(1, 2, 3, 4);
foo(1, 2, 3, -a => 4);
foo(1, 2, -z => 3, -a => 4);
foo(1, -y => 2, -z => 3, -a => 4);
foo(1, -z => 3, -y => 2, -a => 4);
foo(-x => 1, -y => 2, -z => 3, -a => 4);
foo(-x => 1, -z => 3, -y => 2, -a => 4);
foo(-y => 2, -x => 1, -z => 3, -a => 4);
foo(-z => 3, -x => 1, -y => 2, -a => 4);
foo(-z => 3, -y => 2, -x => 1, -a => 4);
foo(-y => 2, -z => 3, -x => 1, -a => 4);
