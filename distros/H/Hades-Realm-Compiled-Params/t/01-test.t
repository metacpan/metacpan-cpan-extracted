use Test::More;
use strict;
use warnings;
BEGIN { use_ok('Hades::Realm::Compiled::Params'); }
subtest 'new' => sub {
	plan tests => 9;
	ok( my $obj = Hades::Realm::Compiled::Params->new( { cpo => ['test'] } ),
		q{my $obj = Hades::Realm::Compiled::Params->new({cpo => ['test']})}
	);
	ok( $obj = Hades::Realm::Compiled::Params->new( cpo => ['test'] ),
		q{$obj = Hades::Realm::Compiled::Params->new(cpo => ['test'])}
	);
	isa_ok( $obj, 'Hades::Realm::Compiled::Params' );
	ok( $obj = Hades::Realm::Compiled::Params->new( {} ),
		q{$obj = Hades::Realm::Compiled::Params->new({})}
	);
	ok( $obj = Hades::Realm::Compiled::Params->new(),
		q{$obj = Hades::Realm::Compiled::Params->new()}
	);
	is_deeply( $obj->cpo, [], q{$obj->cpo} );
	ok( $obj = Hades::Realm::Compiled::Params->new( { cpo => ['test'] } ),
		q{$obj = Hades::Realm::Compiled::Params->new({ cpo => ['test'] })}
	);
	eval { $obj = Hades::Realm::Compiled::Params->new( { cpo => {} } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::Compiled::Params->new({ cpo => {} })}
	);
	eval { $obj = Hades::Realm::Compiled::Params->new( { cpo => 'penthos' } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::Compiled::Params->new({ cpo => 'penthos' })}
	);
};
subtest 'cpo' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Compiled::Params->new( { cpo => ['test'] } ),
		q{my $obj = Hades::Realm::Compiled::Params->new({cpo => ['test']})}
	);
	can_ok( $obj, 'cpo' );
	is_deeply( $obj->cpo( ['test'] ), ['test'], q{$obj->cpo(['test'])} );
	eval { $obj->cpo( {} ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->cpo({})} );
	eval { $obj->cpo('phobos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->cpo('phobos')} );
	is_deeply( $obj->cpo, ['test'], q{$obj->cpo} );
};
subtest 'after_class' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::Compiled::Params->new( { cpo => ['test'] } ),
		q{my $obj = Hades::Realm::Compiled::Params->new({cpo => ['test']})}
	);
	can_ok( $obj, 'after_class' );
	eval { $obj->after_class( [] ) };
	like( $@, qr/invalid value|greater|atleast/, q{$obj->after_class([])} );
	eval { $obj->after_class('nosoi') };
	like( $@, qr/invalid value|greater|atleast/,
		q{$obj->after_class('nosoi')} );
};
subtest 'build_accessor' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Compiled::Params->new( { cpo => ['test'] } ),
		q{my $obj = Hades::Realm::Compiled::Params->new({cpo => ['test']})}
	);
	can_ok( $obj, 'build_accessor' );
};
subtest 'build_type' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::Compiled::Params->new( { cpo => ['test'] } ),
		q{my $obj = Hades::Realm::Compiled::Params->new({cpo => ['test']})}
	);
	can_ok( $obj, 'build_type' );
	eval { $obj->build_type( [], undef, undef ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->build_type([], undef, undef)}
	);
	eval { $obj->build_type( \1, undef, undef ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->build_type(\1, undef, undef)}
	);
	eval { $obj->build_type( 'phobos', [], undef ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->build_type('phobos', [], undef)}
	);
	eval { $obj->build_type( 'phobos', \1, undef ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->build_type('phobos', \1, undef)}
	);
	eval { $obj->build_type( 'phobos', undef, [] ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->build_type('phobos', undef, [])}
	);
	eval { $obj->build_type( 'phobos', undef, \1 ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->build_type('phobos', undef, \1)}
	);
};
subtest 'push_cpo' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Compiled::Params->new( { cpo => ['test'] } ),
		q{my $obj = Hades::Realm::Compiled::Params->new({cpo => ['test']})}
	);
	can_ok( $obj, 'push_cpo' );
	eval { $obj->push_cpo( [], 'hypnos' ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->push_cpo([], 'hypnos')}
	);
	eval { $obj->push_cpo( \1, 'hypnos' ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->push_cpo(\1, 'hypnos')}
	);
	eval { $obj->push_cpo( 'nosoi', [] ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->push_cpo('nosoi', [])}
	);
	eval { $obj->push_cpo( 'nosoi', \1 ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->push_cpo('nosoi', \1)}
	);
};
subtest 'build_sub' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::Compiled::Params->new( { cpo => ['test'] } ),
		q{my $obj = Hades::Realm::Compiled::Params->new({cpo => ['test']})}
	);
	can_ok( $obj, 'build_sub' );
	eval { $obj->build_sub( 'gaudia', 'algea', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->build_sub('gaudia', 'algea', { 'test' => 'test' })}
	);
	eval { $obj->build_sub( 1, 'algea', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->build_sub(1, 'algea', { 'test' => 'test' })}
	);
	eval { $obj->build_sub( { test => 'test' }, [], { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->build_sub({ test => 'test' }, [], { 'test' => 'test' })}
	);
	eval { $obj->build_sub( { test => 'test' }, \1, { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->build_sub({ test => 'test' }, \1, { 'test' => 'test' })}
	);
	eval { $obj->build_sub( { test => 'test' }, 'algea', [] ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->build_sub({ test => 'test' }, 'algea', [])}
	);
	eval { $obj->build_sub( { test => 'test' }, 'algea', 'aporia' ) };
	like(
		$@,
		qr/invalid value|greater|atleast/,
		q{$obj->build_sub({ test => 'test' }, 'algea', 'aporia')}
	);
};
done_testing();
