# vim: set ft=perl :

use Test::More tests => 31;
BEGIN { use_ok('Getargs::Mixed') };

sub foo {
	my %args = parameters([ qw(x y z ) ], @_);

	is($args{x}, 1);
	is($args{y}, 2);
	is($args{z}, 3);
}

foo(1, 2, 3);
foo(1, 2, -z => 3);
foo(1, -y => 2, -z => 3);
foo(1, -z => 3, -y => 2);
foo(-x => 1, -y => 2, -z => 3);
foo(-x => 1, -z => 3, -y => 2);
foo(-y => 2, -x => 1, -z => 3);
foo(-z => 3, -x => 1, -y => 2);
foo(-z => 3, -y => 2, -x => 1);
foo(-y => 2, -z => 3, -x => 1);
