use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Hades::Realm::Moo');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 3;
	ok( my $obj = Hades::Realm::Moo->new( {} ),
		q{my $obj = Hades::Realm::Moo->new({})}
	);
	ok( $obj = Hades::Realm::Moo->new(), q{$obj = Hades::Realm::Moo->new()} );
	isa_ok( $obj, 'Hades::Realm::Moo' );
};
subtest 'build_as_class' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Moo->new( {} ),
		q{my $obj = Hades::Realm::Moo->new({})}
	);
	can_ok( $obj, 'build_as_class' );
};
subtest 'build_as_role' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Moo->new( {} ),
		q{my $obj = Hades::Realm::Moo->new({})}
	);
	can_ok( $obj, 'build_as_role' );
};
subtest 'build_has' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::Moo->new( {} ),
		q{my $obj = Hades::Realm::Moo->new({})}
	);
	can_ok( $obj, 'build_has' );
	eval { $obj->build_has( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has([])} );
	eval { $obj->build_has('phobos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has('phobos')} );
};
done_testing();
