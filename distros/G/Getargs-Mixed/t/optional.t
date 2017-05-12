# vim: set ft=perl :

use Test::More tests => 3;
BEGIN { use_ok('Getargs::Mixed') };

sub foo {
	my %args = parameters([ qw( x; y z ) ], @_);

	is($args{x}, 1);
}

foo(1);
foo(-x => 1);
