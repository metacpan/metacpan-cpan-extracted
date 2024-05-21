use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Hades::Realm::Rope');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 3;
	ok( my $obj = Hades::Realm::Rope->new( {} ),
		q{my $obj = Hades::Realm::Rope->new({})}
	);
	ok( $obj = Hades::Realm::Rope->new(),
		q{$obj = Hades::Realm::Rope->new()}
	);
	isa_ok( $obj, 'Hades::Realm::Rope' );
};
subtest 'build_as_role' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Rope->new( {} ),
		q{my $obj = Hades::Realm::Rope->new({})}
	);
	can_ok( $obj, 'build_as_role' );
};
subtest 'build_as_class' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Rope->new( {} ),
		q{my $obj = Hades::Realm::Rope->new({})}
	);
	can_ok( $obj, 'build_as_class' );
};
subtest 'build_has' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::Rope->new( {} ),
		q{my $obj = Hades::Realm::Rope->new({})}
	);
	can_ok( $obj, 'build_has' );
	eval { $obj->build_has( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_has([])} );
	eval { $obj->build_has('nosoi') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_has('nosoi')} );
};
subtest 'build_accessor_predicate' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Rope->new( {} ),
		q{my $obj = Hades::Realm::Rope->new({})}
	);
	can_ok( $obj, 'build_accessor_predicate' );
	eval { $obj->build_accessor_predicate( [], 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate([], 'gaudia')}
	);
	eval { $obj->build_accessor_predicate( \1, 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate(\1, 'gaudia')}
	);
	eval { $obj->build_accessor_predicate( 'nosoi', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate('nosoi', [])}
	);
	eval { $obj->build_accessor_predicate( 'nosoi', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate('nosoi', \1)}
	);
};
subtest 'build_accessor_clearer' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Rope->new( {} ),
		q{my $obj = Hades::Realm::Rope->new({})}
	);
	can_ok( $obj, 'build_accessor_clearer' );
	eval { $obj->build_accessor_clearer( [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_clearer([], 'geras')}
	);
	eval { $obj->build_accessor_clearer( \1, 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_clearer(\1, 'geras')}
	);
	eval { $obj->build_accessor_clearer( 'aporia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_clearer('aporia', [])}
	);
	eval { $obj->build_accessor_clearer( 'aporia', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_clearer('aporia', \1)}
	);
};
subtest 'build_accessor_builder' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Rope->new( {} ),
		q{my $obj = Hades::Realm::Rope->new({})}
	);
	can_ok( $obj, 'build_accessor_builder' );
	eval { $obj->build_accessor_builder( [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder([], 'phobos')}
	);
	eval { $obj->build_accessor_builder( \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder(\1, 'phobos')}
	);
	eval { $obj->build_accessor_builder( 'algea', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder('algea', [])}
	);
	eval { $obj->build_accessor_builder( 'algea', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder('algea', \1)}
	);
};
subtest 'build_accessor_default' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Rope->new( {} ),
		q{my $obj = Hades::Realm::Rope->new({})}
	);
	can_ok( $obj, 'build_accessor_default' );
	eval { $obj->build_accessor_default( [], 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_default([], 'limos')}
	);
	eval { $obj->build_accessor_default( \1, 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_default(\1, 'limos')}
	);
	eval { $obj->build_accessor_default( 'aporia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_default('aporia', [])}
	);
	eval { $obj->build_accessor_default( 'aporia', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_default('aporia', \1)}
	);
};
subtest 'has_function_keyword' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Rope->new( {} ),
		q{my $obj = Hades::Realm::Rope->new({})}
	);
	can_ok( $obj, 'has_function_keyword' );
};
done_testing();
