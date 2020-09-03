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
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has([])} );
	eval { $obj->build_has('limos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has('limos')} );
};
subtest 'build_accessor_predicate' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Moose->new( {} ),
		q{my $obj = Hades::Realm::Moose->new({})}
	);
	can_ok( $obj, 'build_accessor_predicate' );
	eval { $obj->build_accessor_predicate( [], 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_predicate([], 'limos')}
	);
	eval { $obj->build_accessor_predicate( \1, 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_predicate(\1, 'limos')}
	);
	eval { $obj->build_accessor_predicate( 'thanatos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_predicate('thanatos', [])}
	);
	eval { $obj->build_accessor_predicate( 'thanatos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_predicate('thanatos', \1)}
	);
};
subtest 'build_accessor_clearer' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Moose->new( {} ),
		q{my $obj = Hades::Realm::Moose->new({})}
	);
	can_ok( $obj, 'build_accessor_clearer' );
	eval { $obj->build_accessor_clearer( [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_clearer([], 'geras')}
	);
	eval { $obj->build_accessor_clearer( \1, 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_clearer(\1, 'geras')}
	);
	eval { $obj->build_accessor_clearer( 'penthos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_clearer('penthos', [])}
	);
	eval { $obj->build_accessor_clearer( 'penthos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_clearer('penthos', \1)}
	);
};
subtest 'build_accessor_builder' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Moose->new( {} ),
		q{my $obj = Hades::Realm::Moose->new({})}
	);
	can_ok( $obj, 'build_accessor_builder' );
	eval { $obj->build_accessor_builder( [], 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder([], 'hypnos')}
	);
	eval { $obj->build_accessor_builder( \1, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder(\1, 'hypnos')}
	);
	eval { $obj->build_accessor_builder( 'nosoi', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder('nosoi', [])}
	);
	eval { $obj->build_accessor_builder( 'nosoi', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder('nosoi', \1)}
	);
};
done_testing();
