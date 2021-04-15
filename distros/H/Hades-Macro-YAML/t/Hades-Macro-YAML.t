use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Hades::Macro::YAML');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 9;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	ok( $obj = Hades::Macro::YAML->new(),
		q{$obj = Hades::Macro::YAML->new()}
	);
	isa_ok( $obj, 'Hades::Macro::YAML' );
	ok( $obj = Hades::Macro::YAML->new( {} ),
		q{$obj = Hades::Macro::YAML->new({})}
	);
	ok( $obj = Hades::Macro::YAML->new(),
		q{$obj = Hades::Macro::YAML->new()}
	);
	is_deeply(
		$obj->macro,
		[   qw/
			    yaml_load_string
			    yaml_load_file
			    yaml_write_string
			    yaml_write_file
			    /
		],
		q{$obj->macro}
	);
	ok( $obj = Hades::Macro::YAML->new( { macro => ['test'] } ),
		q{$obj = Hades::Macro::YAML->new({ macro => ['test'] })}
	);
	eval { $obj = Hades::Macro::YAML->new( { macro => {} } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro::YAML->new({ macro => {} })}
	);
	eval { $obj = Hades::Macro::YAML->new( { macro => 'hypnos' } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro::YAML->new({ macro => 'hypnos' })}
	);
};
subtest 'macro' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, 'macro' );
	is_deeply( $obj->macro( ['test'] ), ['test'], q{$obj->macro(['test'])} );
	eval { $obj->macro( {} ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->macro({})} );
	eval { $obj->macro('curae') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->macro('curae')} );
	is_deeply( $obj->macro, ['test'], q{$obj->macro} );
};
subtest 'yaml_load_string' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, 'yaml_load_string' );
	eval { $obj->yaml_load_string( [], 'aporia', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string([], 'aporia', undef, undef)}
	);
	eval { $obj->yaml_load_string( 'geras', 'aporia', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string('geras', 'aporia', undef, undef)}
	);
	eval { $obj->yaml_load_string( bless( {}, 'Test' ), [], undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string(bless({}, 'Test'), [], undef, undef)}
	);
	eval { $obj->yaml_load_string( bless( {}, 'Test' ), \1, undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string(bless({}, 'Test'), \1, undef, undef)}
	);
	eval {
		$obj->yaml_load_string( bless( {}, 'Test' ), 'aporia', [], undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string(bless({}, 'Test'), 'aporia', [], undef)}
	);
	eval {
		$obj->yaml_load_string( bless( {}, 'Test' ), 'aporia', \1, undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string(bless({}, 'Test'), 'aporia', \1, undef)}
	);
	eval {
		$obj->yaml_load_string( bless( {}, 'Test' ), 'aporia', undef, [] );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string(bless({}, 'Test'), 'aporia', undef, [])}
	);
	eval {
		$obj->yaml_load_string( bless( {}, 'Test' ), 'aporia', undef, {} );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string(bless({}, 'Test'), 'aporia', undef, {})}
	);
};
subtest '_yaml_load_string_YAML' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_load_string_YAML' );
	eval { $obj->_yaml_load_string_YAML( [], 'hypnos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML([], 'hypnos', undef, undef)}
	);
	eval { $obj->_yaml_load_string_YAML( 'aporia', 'hypnos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML('aporia', 'hypnos', undef, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML( bless( {}, 'Test' ), [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), [], undef, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML( bless( {}, 'Test' ), \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), \1, undef, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML( bless( {}, 'Test' ),
			'hypnos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), 'hypnos', [], undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML( bless( {}, 'Test' ),
			'hypnos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), 'hypnos', \1, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML( bless( {}, 'Test' ),
			'hypnos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), 'hypnos', undef, [])}
	);
	eval {
		$obj->_yaml_load_string_YAML( bless( {}, 'Test' ),
			'hypnos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), 'hypnos', undef, {})}
	);
};
subtest '_yaml_load_string_YAML_XS' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_load_string_YAML_XS' );
	eval { $obj->_yaml_load_string_YAML_XS( [], 'gaudia', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS([], 'gaudia', undef, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_XS( 'penthos', 'gaudia', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS('penthos', 'gaudia', undef, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_XS( bless( {}, 'Test' ),
			[], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS(bless({}, 'Test'), [], undef, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_XS( bless( {}, 'Test' ),
			\1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS(bless({}, 'Test'), \1, undef, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_XS( bless( {}, 'Test' ),
			'gaudia', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS(bless({}, 'Test'), 'gaudia', [], undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_XS( bless( {}, 'Test' ),
			'gaudia', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS(bless({}, 'Test'), 'gaudia', \1, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_XS( bless( {}, 'Test' ),
			'gaudia', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS(bless({}, 'Test'), 'gaudia', undef, [])}
	);
	eval {
		$obj->_yaml_load_string_YAML_XS( bless( {}, 'Test' ),
			'gaudia', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS(bless({}, 'Test'), 'gaudia', undef, {})}
	);
};
subtest '_yaml_load_string_YAML_PP' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_load_string_YAML_PP' );
	eval { $obj->_yaml_load_string_YAML_PP( [], 'hypnos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP([], 'hypnos', undef, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_PP( 'limos', 'hypnos', undef, undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP('limos', 'hypnos', undef, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_PP( bless( {}, 'Test' ),
			[], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP(bless({}, 'Test'), [], undef, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_PP( bless( {}, 'Test' ),
			\1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP(bless({}, 'Test'), \1, undef, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_PP( bless( {}, 'Test' ),
			'hypnos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP(bless({}, 'Test'), 'hypnos', [], undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_PP( bless( {}, 'Test' ),
			'hypnos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP(bless({}, 'Test'), 'hypnos', \1, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_PP( bless( {}, 'Test' ),
			'hypnos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP(bless({}, 'Test'), 'hypnos', undef, [])}
	);
	eval {
		$obj->_yaml_load_string_YAML_PP( bless( {}, 'Test' ),
			'hypnos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP(bless({}, 'Test'), 'hypnos', undef, {})}
	);
};
subtest 'yaml_load_file' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, 'yaml_load_file' );
	eval { $obj->yaml_load_file( [], 'limos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file([], 'limos', undef, undef)}
	);
	eval { $obj->yaml_load_file( 'gaudia', 'limos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file('gaudia', 'limos', undef, undef)}
	);
	eval { $obj->yaml_load_file( bless( {}, 'Test' ), [], undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), [], undef, undef)}
	);
	eval { $obj->yaml_load_file( bless( {}, 'Test' ), \1, undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), \1, undef, undef)}
	);
	eval { $obj->yaml_load_file( bless( {}, 'Test' ), 'limos', [], undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), 'limos', [], undef)}
	);
	eval { $obj->yaml_load_file( bless( {}, 'Test' ), 'limos', \1, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), 'limos', \1, undef)}
	);
	eval { $obj->yaml_load_file( bless( {}, 'Test' ), 'limos', undef, [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), 'limos', undef, [])}
	);
	eval { $obj->yaml_load_file( bless( {}, 'Test' ), 'limos', undef, {} ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), 'limos', undef, {})}
	);
};
subtest '_yaml_load_file_YAML' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_load_file_YAML' );
	eval { $obj->_yaml_load_file_YAML( [], 'phobos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML([], 'phobos', undef, undef)}
	);
	eval { $obj->_yaml_load_file_YAML( 'geras', 'phobos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML('geras', 'phobos', undef, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML( bless( {}, 'Test' ), [], undef, undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML(bless({}, 'Test'), [], undef, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML( bless( {}, 'Test' ), \1, undef, undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML(bless({}, 'Test'), \1, undef, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML( bless( {}, 'Test' ), 'phobos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML(bless({}, 'Test'), 'phobos', [], undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML( bless( {}, 'Test' ), 'phobos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML(bless({}, 'Test'), 'phobos', \1, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML( bless( {}, 'Test' ), 'phobos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML(bless({}, 'Test'), 'phobos', undef, [])}
	);
	eval {
		$obj->_yaml_load_file_YAML( bless( {}, 'Test' ), 'phobos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML(bless({}, 'Test'), 'phobos', undef, {})}
	);
};
subtest '_yaml_load_file_YAML_XS' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_load_file_YAML_XS' );
	eval { $obj->_yaml_load_file_YAML_XS( [], 'geras', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS([], 'geras', undef, undef)}
	);
	eval { $obj->_yaml_load_file_YAML_XS( 'gaudia', 'geras', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS('gaudia', 'geras', undef, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_XS( bless( {}, 'Test' ), [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), [], undef, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_XS( bless( {}, 'Test' ), \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), \1, undef, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_XS( bless( {}, 'Test' ),
			'geras', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), 'geras', [], undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_XS( bless( {}, 'Test' ),
			'geras', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), 'geras', \1, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_XS( bless( {}, 'Test' ),
			'geras', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), 'geras', undef, [])}
	);
	eval {
		$obj->_yaml_load_file_YAML_XS( bless( {}, 'Test' ),
			'geras', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), 'geras', undef, {})}
	);
};
subtest '_yaml_load_file_YAML_PP' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_load_file_YAML_PP' );
	eval { $obj->_yaml_load_file_YAML_PP( [], 'nosoi', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP([], 'nosoi', undef, undef)}
	);
	eval { $obj->_yaml_load_file_YAML_PP( 'curae', 'nosoi', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP('curae', 'nosoi', undef, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_PP( bless( {}, 'Test' ), [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP(bless({}, 'Test'), [], undef, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_PP( bless( {}, 'Test' ), \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP(bless({}, 'Test'), \1, undef, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_PP( bless( {}, 'Test' ),
			'nosoi', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP(bless({}, 'Test'), 'nosoi', [], undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_PP( bless( {}, 'Test' ),
			'nosoi', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP(bless({}, 'Test'), 'nosoi', \1, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_PP( bless( {}, 'Test' ),
			'nosoi', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP(bless({}, 'Test'), 'nosoi', undef, [])}
	);
	eval {
		$obj->_yaml_load_file_YAML_PP( bless( {}, 'Test' ),
			'nosoi', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP(bless({}, 'Test'), 'nosoi', undef, {})}
	);
};
subtest 'yaml_write_string' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, 'yaml_write_string' );
	eval { $obj->yaml_write_string( [], 'algea', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string([], 'algea', undef, undef)}
	);
	eval { $obj->yaml_write_string( 'geras', 'algea', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string('geras', 'algea', undef, undef)}
	);
	eval { $obj->yaml_write_string( bless( {}, 'Test' ), [], undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string(bless({}, 'Test'), [], undef, undef)}
	);
	eval { $obj->yaml_write_string( bless( {}, 'Test' ), \1, undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string(bless({}, 'Test'), \1, undef, undef)}
	);
	eval {
		$obj->yaml_write_string( bless( {}, 'Test' ), 'algea', [], undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string(bless({}, 'Test'), 'algea', [], undef)}
	);
	eval {
		$obj->yaml_write_string( bless( {}, 'Test' ), 'algea', \1, undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string(bless({}, 'Test'), 'algea', \1, undef)}
	);
	eval {
		$obj->yaml_write_string( bless( {}, 'Test' ), 'algea', undef, [] );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string(bless({}, 'Test'), 'algea', undef, [])}
	);
	eval {
		$obj->yaml_write_string( bless( {}, 'Test' ), 'algea', undef, {} );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string(bless({}, 'Test'), 'algea', undef, {})}
	);
};
subtest '_yaml_write_string_YAML' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_string_YAML' );
	eval { $obj->_yaml_write_string_YAML( [], 'phobos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML([], 'phobos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML( 'penthos', 'phobos', undef, undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML('penthos', 'phobos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML( bless( {}, 'Test' ), [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), [], undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML( bless( {}, 'Test' ), \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), \1, undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML( bless( {}, 'Test' ),
			'phobos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), 'phobos', [], undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML( bless( {}, 'Test' ),
			'phobos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), 'phobos', \1, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML( bless( {}, 'Test' ),
			'phobos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), 'phobos', undef, [])}
	);
	eval {
		$obj->_yaml_write_string_YAML( bless( {}, 'Test' ),
			'phobos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), 'phobos', undef, {})}
	);
};
subtest '_yaml_write_string_YAML_XS' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_string_YAML_XS' );
	eval { $obj->_yaml_write_string_YAML_XS( [], 'geras', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS([], 'geras', undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_XS( 'penthos', 'geras', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS('penthos', 'geras', undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_XS( bless( {}, 'Test' ),
			[], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS(bless({}, 'Test'), [], undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_XS( bless( {}, 'Test' ),
			\1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS(bless({}, 'Test'), \1, undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_XS( bless( {}, 'Test' ),
			'geras', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS(bless({}, 'Test'), 'geras', [], undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_XS( bless( {}, 'Test' ),
			'geras', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS(bless({}, 'Test'), 'geras', \1, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_XS( bless( {}, 'Test' ),
			'geras', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS(bless({}, 'Test'), 'geras', undef, [])}
	);
	eval {
		$obj->_yaml_write_string_YAML_XS( bless( {}, 'Test' ),
			'geras', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS(bless({}, 'Test'), 'geras', undef, {})}
	);
};
subtest '_yaml_write_string_YAML_PP' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_string_YAML_PP' );
	eval { $obj->_yaml_write_string_YAML_PP( [], 'phobos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP([], 'phobos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( 'nosoi', 'phobos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP('nosoi', 'phobos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( bless( {}, 'Test' ),
			[], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), [], undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( bless( {}, 'Test' ),
			\1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), \1, undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( bless( {}, 'Test' ),
			'phobos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), 'phobos', [], undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( bless( {}, 'Test' ),
			'phobos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), 'phobos', \1, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( bless( {}, 'Test' ),
			'phobos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), 'phobos', undef, [])}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( bless( {}, 'Test' ),
			'phobos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), 'phobos', undef, {})}
	);
};
subtest 'yaml_write_file' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, 'yaml_write_file' );
	eval { $obj->yaml_write_file( [], 'aporia', 'geras', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file([], 'aporia', 'geras', undef, undef)}
	);
	eval { $obj->yaml_write_file( 'nosoi', 'aporia', 'geras', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file('nosoi', 'aporia', 'geras', undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			[], 'geras', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), [], 'geras', undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			\1, 'geras', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), \1, 'geras', undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'aporia', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'aporia', [], undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'aporia', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'aporia', \1, undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'aporia', 'geras', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'aporia', 'geras', [], undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'aporia', 'geras', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'aporia', 'geras', \1, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'aporia', 'geras', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'aporia', 'geras', undef, [])}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'aporia', 'geras', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'aporia', 'geras', undef, {})}
	);
};
subtest '_yaml_write_file_YAML' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_file_YAML' );
	eval {
		$obj->_yaml_write_file_YAML( [], 'aporia', 'penthos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML([], 'aporia', 'penthos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( 'algea', 'aporia', 'penthos', undef,
			undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML('algea', 'aporia', 'penthos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			[], 'penthos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), [], 'penthos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			\1, 'penthos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), \1, 'penthos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'aporia', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'aporia', [], undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'aporia', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'aporia', \1, undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'aporia', 'penthos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'aporia', 'penthos', [], undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'aporia', 'penthos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'aporia', 'penthos', \1, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'aporia', 'penthos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'aporia', 'penthos', undef, [])}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'aporia', 'penthos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'aporia', 'penthos', undef, {})}
	);
};
subtest '_yaml_write_file_YAML_XS' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_file_YAML_XS' );
	eval {
		$obj->_yaml_write_file_YAML_XS( [], 'curae', 'nosoi', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS([], 'curae', 'nosoi', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( 'phobos', 'curae', 'nosoi', undef,
			undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS('phobos', 'curae', 'nosoi', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			[], 'nosoi', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), [], 'nosoi', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			\1, 'nosoi', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), \1, 'nosoi', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'curae', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'curae', [], undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'curae', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'curae', \1, undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'curae', 'nosoi', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'curae', 'nosoi', [], undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'curae', 'nosoi', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'curae', 'nosoi', \1, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'curae', 'nosoi', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'curae', 'nosoi', undef, [])}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'curae', 'nosoi', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'curae', 'nosoi', undef, {})}
	);
};
subtest '_yaml_write_file_YAML_PP' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_file_YAML_PP' );
	eval {
		$obj->_yaml_write_file_YAML_PP( [], 'penthos', 'algea', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP([], 'penthos', 'algea', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( 'aporia', 'penthos', 'algea', undef,
			undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP('aporia', 'penthos', 'algea', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			[], 'algea', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), [], 'algea', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			\1, 'algea', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), \1, 'algea', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'penthos', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'penthos', [], undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'penthos', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'penthos', \1, undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'penthos', 'algea', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'penthos', 'algea', [], undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'penthos', 'algea', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'penthos', 'algea', \1, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'penthos', 'algea', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'penthos', 'algea', undef, [])}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'penthos', 'algea', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'penthos', 'algea', undef, {})}
	);
};
done_testing();
