use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Hades::Realm::Mouse');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 3;
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
	);
	ok( $obj = Hades::Realm::Mouse->new(),
		q{$obj = Hades::Realm::Mouse->new()}
	);
	isa_ok( $obj, 'Hades::Realm::Mouse' );
};
subtest 'build_as_role' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
	);
	can_ok( $obj, 'build_as_role' );
};
subtest 'build_as_class' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
	);
	can_ok( $obj, 'build_as_class' );
};
subtest 'build_has' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
	);
	can_ok( $obj, 'build_has' );
	eval { $obj->build_has( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has([])} );
	eval { $obj->build_has('curae') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has('curae')} );
};
subtest 'build_accessor_predicate' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
	);
	can_ok( $obj, 'build_accessor_predicate' );
	eval { $obj->build_accessor_predicate( [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_predicate([], 'geras')}
	);
	eval { $obj->build_accessor_predicate( \1, 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_predicate(\1, 'geras')}
	);
	eval { $obj->build_accessor_predicate( 'aporia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_predicate('aporia', [])}
	);
	eval { $obj->build_accessor_predicate( 'aporia', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_predicate('aporia', \1)}
	);
};
subtest 'build_accessor_clearer' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
	);
	can_ok( $obj, 'build_accessor_clearer' );
	eval { $obj->build_accessor_clearer( [], 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_clearer([], 'penthos')}
	);
	eval { $obj->build_accessor_clearer( \1, 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_clearer(\1, 'penthos')}
	);
	eval { $obj->build_accessor_clearer( 'nosoi', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_clearer('nosoi', [])}
	);
	eval { $obj->build_accessor_clearer( 'nosoi', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_clearer('nosoi', \1)}
	);
};
subtest 'build_accessor_builder' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
	);
	can_ok( $obj, 'build_accessor_builder' );
	eval { $obj->build_accessor_builder( [], 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder([], 'gaudia')}
	);
	eval { $obj->build_accessor_builder( \1, 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder(\1, 'gaudia')}
	);
	eval { $obj->build_accessor_builder( 'aporia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder('aporia', [])}
	);
	eval { $obj->build_accessor_builder( 'aporia', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder('aporia', \1)}
	);
};
done_testing();
