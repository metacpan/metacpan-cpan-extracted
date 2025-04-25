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
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_has([])} );
	eval { $obj->build_has('phobos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_has('phobos')} );
};
subtest 'build_accessor_predicate' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
	);
	can_ok( $obj, 'build_accessor_predicate' );
	eval { $obj->build_accessor_predicate( [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate([], 'phobos')}
	);
	eval { $obj->build_accessor_predicate( \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate(\1, 'phobos')}
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
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
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
	eval { $obj->build_accessor_clearer( 'limos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_clearer('limos', [])}
	);
	eval { $obj->build_accessor_clearer( 'limos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_clearer('limos', \1)}
	);
};
subtest 'build_accessor_builder' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
	);
	can_ok( $obj, 'build_accessor_builder' );
	eval { $obj->build_accessor_builder( [], 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder([], 'algea')}
	);
	eval { $obj->build_accessor_builder( \1, 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder(\1, 'algea')}
	);
	eval { $obj->build_accessor_builder( 'geras', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder('geras', [])}
	);
	eval { $obj->build_accessor_builder( 'geras', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder('geras', \1)}
	);
};
done_testing();
