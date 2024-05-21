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
	eval { $obj->build_has('algea') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_has('algea')} );
};
subtest 'build_accessor_predicate' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Moose->new( {} ),
		q{my $obj = Hades::Realm::Moose->new({})}
	);
	can_ok( $obj, 'build_accessor_predicate' );
	eval { $obj->build_accessor_predicate( [], 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate([], 'penthos')}
	);
	eval { $obj->build_accessor_predicate( \1, 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate(\1, 'penthos')}
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
	eval { $obj->build_accessor_clearer( 'thanatos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_clearer('thanatos', [])}
	);
	eval { $obj->build_accessor_clearer( 'thanatos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_clearer('thanatos', \1)}
	);
};
subtest 'build_accessor_builder' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Moose->new( {} ),
		q{my $obj = Hades::Realm::Moose->new({})}
	);
	can_ok( $obj, 'build_accessor_builder' );
	eval { $obj->build_accessor_builder( [], 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder([], 'aporia')}
	);
	eval { $obj->build_accessor_builder( \1, 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder(\1, 'aporia')}
	);
	eval { $obj->build_accessor_builder( 'phobos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder('phobos', [])}
	);
	eval { $obj->build_accessor_builder( 'phobos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder('phobos', \1)}
	);
};
done_testing();
