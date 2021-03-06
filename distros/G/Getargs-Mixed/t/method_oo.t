# vim: set ft=perl :

use Test::More tests => 41;
BEGIN { use_ok('Getargs::Mixed') };

sub foo {
	my ($self, %args) = Getargs::Mixed->new->parameters('self', [ qw(x y z ) ], @_);

	is($self, 'main');
	is($args{x}, 1);
	is($args{y}, 2);
	is($args{z}, 3);
}

main->foo(1, 2, 3);
main->foo(1, 2, -z => 3);
main->foo(1, -y => 2, -z => 3);
main->foo(1, -z => 3, -y => 2);
main->foo(-x => 1, -y => 2, -z => 3);
main->foo(-x => 1, -z => 3, -y => 2);
main->foo(-y => 2, -x => 1, -z => 3);
main->foo(-z => 3, -x => 1, -y => 2);
main->foo(-z => 3, -y => 2, -x => 1);
main->foo(-y => 2, -z => 3, -x => 1);
