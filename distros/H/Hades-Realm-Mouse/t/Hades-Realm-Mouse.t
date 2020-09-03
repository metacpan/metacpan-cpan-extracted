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
	eval { $obj->build_has('aporia') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has('aporia')} );
};
subtest 'build_accessor_predicate' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
	);
	can_ok( $obj, 'build_accessor_predicate' );
	eval { $obj->build_accessor_predicate( [], 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_predicate([], 'thanatos')}
	);
	eval { $obj->build_accessor_predicate( \1, 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_predicate(\1, 'thanatos')}
	);
	eval { $obj->build_accessor_predicate( 'algea', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_predicate('algea', [])}
	);
	eval { $obj->build_accessor_predicate( 'algea', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_predicate('algea', \1)}
	);
};
subtest 'build_accessor_clearer' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
	);
	can_ok( $obj, 'build_accessor_clearer' );
	eval { $obj->build_accessor_clearer( [], 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_clearer([], 'hypnos')}
	);
	eval { $obj->build_accessor_clearer( \1, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_clearer(\1, 'hypnos')}
	);
	eval { $obj->build_accessor_clearer( 'thanatos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_clearer('thanatos', [])}
	);
	eval { $obj->build_accessor_clearer( 'thanatos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_clearer('thanatos', \1)}
	);
};
subtest 'build_accessor_builder' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
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
	eval { $obj->build_accessor_builder( 'thanatos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder('thanatos', [])}
	);
	eval { $obj->build_accessor_builder( 'thanatos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder('thanatos', \1)}
	);
};
done_testing();
