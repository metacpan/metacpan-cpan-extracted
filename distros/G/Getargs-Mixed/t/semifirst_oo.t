# vim: set ft=perl :

use Test::More tests => 19;
BEGIN { use_ok('Getargs::Mixed'); }

sub foo {
	my %args = Getargs::Mixed->new->parameters([ qw( ; x y z ) ], @_);

	is($args{x}, 1);
	is($args{y}, 2);
	is($args{z}, 3);
}

sub bar {
	my %args = Getargs::Mixed->new->parameters([ qw( ;x y z ) ], @_);

	is($args{x}, 1);
	is($args{y}, 2);
	is($args{z}, 3);
}

foo(1, 2, 3);
foo(1, -y => 2, -z => 3);
foo(-x => 1, -z => 3, -y => 2);

bar(1, 2, 3);
bar(1, -y => 2, -z => 3);
bar(-x => 1, -z => 3, -y => 2);
