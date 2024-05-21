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
	eval { $obj->build_has('aporia') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_has('aporia')} );
};
subtest 'build_accessor_predicate' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Mouse->new( {} ),
		q{my $obj = Hades::Realm::Mouse->new({})}
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
	eval { $obj->build_accessor_predicate( 'limos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate('limos', [])}
	);
	eval { $obj->build_accessor_predicate( 'limos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_predicate('limos', \1)}
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
	eval { $obj->build_accessor_builder( [], 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder([], 'thanatos')}
	);
	eval { $obj->build_accessor_builder( \1, 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder(\1, 'thanatos')}
	);
	eval { $obj->build_accessor_builder( 'gaudia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder('gaudia', [])}
	);
	eval { $obj->build_accessor_builder( 'gaudia', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder('gaudia', \1)}
	);
};
done_testing();
