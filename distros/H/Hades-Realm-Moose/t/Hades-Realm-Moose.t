use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Hades::Realm::Moose');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 3;
	ok( my $obj = Hades::Realm::Moose->new( {} ),
		q{my $obj = Hades::Realm::Moose->new({})}
	);
	ok( $obj = Hades::Realm::Moose->new(),
		q{$obj = Hades::Realm::Moose->new()}
	);
	isa_ok( $obj, 'Hades::Realm::Moose' );
};
subtest 'build_as_role' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Moose->new( {} ),
		q{my $obj = Hades::Realm::Moose->new({})}
	);
	can_ok( $obj, 'build_as_role' );
};
subtest 'build_as_class' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Moose->new( {} ),
		q{my $obj = Hades::Realm::Moose->new({})}
	);
	can_ok( $obj, 'build_as_class' );
};
subtest 'build_has' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::Moose->new( {} ),
		q{my $obj = Hades::Realm::Moose->new({})}
	);
	can_ok( $obj, 'build_has' );
	eval { $obj->build_has( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_has([])} );
	eval { $obj->build_has('aporia') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_has('aporia')} );
};
subtest 'build_accessor_predicate' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Moose->new( {} ),
		q{my $obj = Hades::Realm::Moose->new({})}
	);
	can_ok( $obj, 'build_accessor_predicate' );
	eval { $obj->build_accessor_predicate( [], 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate([], 'hypnos')}
	);
	eval { $obj->build_accessor_predicate( \1, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate(\1, 'hypnos')}
	);
	eval { $obj->build_accessor_predicate( 'hypnos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate('hypnos', [])}
	);
	eval { $obj->build_accessor_predicate( 'hypnos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate('hypnos', \1)}
	);
};
subtest 'build_accessor_clearer' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Moose->new( {} ),
		q{my $obj = Hades::Realm::Moose->new({})}
	);
	can_ok( $obj, 'build_accessor_clearer' );
	eval { $obj->build_accessor_clearer( [], 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_clearer([], 'aporia')}
	);
	eval { $obj->build_accessor_clearer( \1, 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_clearer(\1, 'aporia')}
	);
	eval { $obj->build_accessor_clearer( 'geras', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_clearer('geras', [])}
	);
	eval { $obj->build_accessor_clearer( 'geras', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_clearer('geras', \1)}
	);
};
subtest 'build_accessor_builder' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Moose->new( {} ),
		q{my $obj = Hades::Realm::Moose->new({})}
	);
	can_ok( $obj, 'build_accessor_builder' );
	eval { $obj->build_accessor_builder( [], 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder([], 'curae')}
	);
	eval { $obj->build_accessor_builder( \1, 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder(\1, 'curae')}
	);
	eval { $obj->build_accessor_builder( 'penthos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder('penthos', [])}
	);
	eval { $obj->build_accessor_builder( 'penthos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder('penthos', \1)}
	);
};
done_testing();
