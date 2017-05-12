# vim: set ft=perl :

use Test::More tests => 7;
BEGIN { use_ok('Getargs::Mixed'); }

sub foo {
	my %args = parameters([ qw( x y ;z ) ], @_);

	is($args{x}, 1);
	is($args{y}, 2);
}

foo(1, 2);
foo(1, -y => 2);
foo(-x => 1, -y => 2);
