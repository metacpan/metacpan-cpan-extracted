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
	eval { $obj->macro('limos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->macro('limos')} );
	is_deeply( $obj->macro, ['test'], q{$obj->macro} );
};
subtest 'yaml_load_string' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, 'yaml_load_string' );
	eval { $obj->yaml_load_string( [], 'phobos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string([], 'phobos', undef, undef)}
	);
	eval { $obj->yaml_load_string( 'curae', 'phobos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string('curae', 'phobos', undef, undef)}
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
		$obj->yaml_load_string( bless( {}, 'Test' ), 'phobos', [], undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string(bless({}, 'Test'), 'phobos', [], undef)}
	);
	eval {
		$obj->yaml_load_string( bless( {}, 'Test' ), 'phobos', \1, undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string(bless({}, 'Test'), 'phobos', \1, undef)}
	);
	eval {
		$obj->yaml_load_string( bless( {}, 'Test' ), 'phobos', undef, [] );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string(bless({}, 'Test'), 'phobos', undef, [])}
	);
	eval {
		$obj->yaml_load_string( bless( {}, 'Test' ), 'phobos', undef, {} );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string(bless({}, 'Test'), 'phobos', undef, {})}
	);
};
subtest '_yaml_load_string_YAML' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_load_string_YAML' );
	eval { $obj->_yaml_load_string_YAML( [], 'nosoi', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML([], 'nosoi', undef, undef)}
	);
	eval { $obj->_yaml_load_string_YAML( 'curae', 'nosoi', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML('curae', 'nosoi', undef, undef)}
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
			'nosoi', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), 'nosoi', [], undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML( bless( {}, 'Test' ),
			'nosoi', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), 'nosoi', \1, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML( bless( {}, 'Test' ),
			'nosoi', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), 'nosoi', undef, [])}
	);
	eval {
		$obj->_yaml_load_string_YAML( bless( {}, 'Test' ),
			'nosoi', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), 'nosoi', undef, {})}
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
		$obj->_yaml_load_string_YAML_XS( 'thanatos', 'gaudia', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS('thanatos', 'gaudia', undef, undef)}
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
	eval { $obj->_yaml_load_string_YAML_PP( [], 'nosoi', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP([], 'nosoi', undef, undef)}
	);
	eval { $obj->_yaml_load_string_YAML_PP( 'nosoi', 'nosoi', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP('nosoi', 'nosoi', undef, undef)}
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
			'nosoi', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP(bless({}, 'Test'), 'nosoi', [], undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_PP( bless( {}, 'Test' ),
			'nosoi', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP(bless({}, 'Test'), 'nosoi', \1, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_PP( bless( {}, 'Test' ),
			'nosoi', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP(bless({}, 'Test'), 'nosoi', undef, [])}
	);
	eval {
		$obj->_yaml_load_string_YAML_PP( bless( {}, 'Test' ),
			'nosoi', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP(bless({}, 'Test'), 'nosoi', undef, {})}
	);
};
subtest 'yaml_load_file' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, 'yaml_load_file' );
	eval { $obj->yaml_load_file( [], 'phobos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file([], 'phobos', undef, undef)}
	);
	eval { $obj->yaml_load_file( 'aporia', 'phobos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file('aporia', 'phobos', undef, undef)}
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
	eval { $obj->yaml_load_file( bless( {}, 'Test' ), 'phobos', [], undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), 'phobos', [], undef)}
	);
	eval { $obj->yaml_load_file( bless( {}, 'Test' ), 'phobos', \1, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), 'phobos', \1, undef)}
	);
	eval { $obj->yaml_load_file( bless( {}, 'Test' ), 'phobos', undef, [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), 'phobos', undef, [])}
	);
	eval { $obj->yaml_load_file( bless( {}, 'Test' ), 'phobos', undef, {} ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), 'phobos', undef, {})}
	);
};
subtest '_yaml_load_file_YAML' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_load_file_YAML' );
	eval { $obj->_yaml_load_file_YAML( [], 'gaudia', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML([], 'gaudia', undef, undef)}
	);
	eval { $obj->_yaml_load_file_YAML( 'gaudia', 'gaudia', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML('gaudia', 'gaudia', undef, undef)}
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
		$obj->_yaml_load_file_YAML( bless( {}, 'Test' ), 'gaudia', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML(bless({}, 'Test'), 'gaudia', [], undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML( bless( {}, 'Test' ), 'gaudia', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML(bless({}, 'Test'), 'gaudia', \1, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML( bless( {}, 'Test' ), 'gaudia', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML(bless({}, 'Test'), 'gaudia', undef, [])}
	);
	eval {
		$obj->_yaml_load_file_YAML( bless( {}, 'Test' ), 'gaudia', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML(bless({}, 'Test'), 'gaudia', undef, {})}
	);
};
subtest '_yaml_load_file_YAML_XS' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_load_file_YAML_XS' );
	eval { $obj->_yaml_load_file_YAML_XS( [], 'phobos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS([], 'phobos', undef, undef)}
	);
	eval { $obj->_yaml_load_file_YAML_XS( 'geras', 'phobos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS('geras', 'phobos', undef, undef)}
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
			'phobos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), 'phobos', [], undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_XS( bless( {}, 'Test' ),
			'phobos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), 'phobos', \1, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_XS( bless( {}, 'Test' ),
			'phobos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), 'phobos', undef, [])}
	);
	eval {
		$obj->_yaml_load_file_YAML_XS( bless( {}, 'Test' ),
			'phobos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), 'phobos', undef, {})}
	);
};
subtest '_yaml_load_file_YAML_PP' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_load_file_YAML_PP' );
	eval { $obj->_yaml_load_file_YAML_PP( [], 'gaudia', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP([], 'gaudia', undef, undef)}
	);
	eval { $obj->_yaml_load_file_YAML_PP( 'limos', 'gaudia', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP('limos', 'gaudia', undef, undef)}
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
			'gaudia', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP(bless({}, 'Test'), 'gaudia', [], undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_PP( bless( {}, 'Test' ),
			'gaudia', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP(bless({}, 'Test'), 'gaudia', \1, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_PP( bless( {}, 'Test' ),
			'gaudia', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP(bless({}, 'Test'), 'gaudia', undef, [])}
	);
	eval {
		$obj->_yaml_load_file_YAML_PP( bless( {}, 'Test' ),
			'gaudia', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP(bless({}, 'Test'), 'gaudia', undef, {})}
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
	eval { $obj->yaml_write_string( 'thanatos', 'algea', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string('thanatos', 'algea', undef, undef)}
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
	eval { $obj->_yaml_write_string_YAML( [], 'algea', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML([], 'algea', undef, undef)}
	);
	eval { $obj->_yaml_write_string_YAML( 'geras', 'algea', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML('geras', 'algea', undef, undef)}
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
			'algea', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), 'algea', [], undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML( bless( {}, 'Test' ),
			'algea', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), 'algea', \1, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML( bless( {}, 'Test' ),
			'algea', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), 'algea', undef, [])}
	);
	eval {
		$obj->_yaml_write_string_YAML( bless( {}, 'Test' ),
			'algea', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), 'algea', undef, {})}
	);
};
subtest '_yaml_write_string_YAML_XS' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_string_YAML_XS' );
	eval { $obj->_yaml_write_string_YAML_XS( [], 'hypnos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS([], 'hypnos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_XS( 'geras', 'hypnos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS('geras', 'hypnos', undef, undef)}
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
			'hypnos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS(bless({}, 'Test'), 'hypnos', [], undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_XS( bless( {}, 'Test' ),
			'hypnos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS(bless({}, 'Test'), 'hypnos', \1, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_XS( bless( {}, 'Test' ),
			'hypnos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS(bless({}, 'Test'), 'hypnos', undef, [])}
	);
	eval {
		$obj->_yaml_write_string_YAML_XS( bless( {}, 'Test' ),
			'hypnos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS(bless({}, 'Test'), 'hypnos', undef, {})}
	);
};
subtest '_yaml_write_string_YAML_PP' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_string_YAML_PP' );
	eval { $obj->_yaml_write_string_YAML_PP( [], 'limos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP([], 'limos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( 'limos', 'limos', undef, undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP('limos', 'limos', undef, undef)}
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
			'limos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), 'limos', [], undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( bless( {}, 'Test' ),
			'limos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), 'limos', \1, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( bless( {}, 'Test' ),
			'limos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), 'limos', undef, [])}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( bless( {}, 'Test' ),
			'limos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), 'limos', undef, {})}
	);
};
subtest 'yaml_write_file' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, 'yaml_write_file' );
	eval { $obj->yaml_write_file( [], 'nosoi', 'penthos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file([], 'nosoi', 'penthos', undef, undef)}
	);
	eval {
		$obj->yaml_write_file( 'limos', 'nosoi', 'penthos', undef, undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file('limos', 'nosoi', 'penthos', undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			[], 'penthos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), [], 'penthos', undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			\1, 'penthos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), \1, 'penthos', undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'nosoi', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'nosoi', [], undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'nosoi', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'nosoi', \1, undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'nosoi', 'penthos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'nosoi', 'penthos', [], undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'nosoi', 'penthos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'nosoi', 'penthos', \1, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'nosoi', 'penthos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'nosoi', 'penthos', undef, [])}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'nosoi', 'penthos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'nosoi', 'penthos', undef, {})}
	);
};
subtest '_yaml_write_file_YAML' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_file_YAML' );
	eval {
		$obj->_yaml_write_file_YAML( [], 'hypnos', 'algea', undef, undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML([], 'hypnos', 'algea', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( 'curae', 'hypnos', 'algea', undef,
			undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML('curae', 'hypnos', 'algea', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			[], 'algea', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), [], 'algea', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			\1, 'algea', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), \1, 'algea', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'hypnos', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'hypnos', [], undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'hypnos', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'hypnos', \1, undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'hypnos', 'algea', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'hypnos', 'algea', [], undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'hypnos', 'algea', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'hypnos', 'algea', \1, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'hypnos', 'algea', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'hypnos', 'algea', undef, [])}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'hypnos', 'algea', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'hypnos', 'algea', undef, {})}
	);
};
subtest '_yaml_write_file_YAML_XS' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_file_YAML_XS' );
	eval {
		$obj->_yaml_write_file_YAML_XS( [], 'phobos', 'phobos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS([], 'phobos', 'phobos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( 'algea', 'phobos', 'phobos', undef,
			undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS('algea', 'phobos', 'phobos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			[], 'phobos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), [], 'phobos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			\1, 'phobos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), \1, 'phobos', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'phobos', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'phobos', [], undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'phobos', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'phobos', \1, undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'phobos', 'phobos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'phobos', 'phobos', [], undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'phobos', 'phobos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'phobos', 'phobos', \1, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'phobos', 'phobos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'phobos', 'phobos', undef, [])}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'phobos', 'phobos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'phobos', 'phobos', undef, {})}
	);
};
subtest '_yaml_write_file_YAML_PP' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_file_YAML_PP' );
	eval {
		$obj->_yaml_write_file_YAML_PP( [], 'thanatos', 'curae', undef,
			undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP([], 'thanatos', 'curae', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( 'hypnos', 'thanatos', 'curae', undef,
			undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP('hypnos', 'thanatos', 'curae', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			[], 'curae', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), [], 'curae', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			\1, 'curae', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), \1, 'curae', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'thanatos', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'thanatos', [], undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'thanatos', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'thanatos', \1, undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'thanatos', 'curae', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'thanatos', 'curae', [], undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'thanatos', 'curae', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'thanatos', 'curae', \1, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'thanatos', 'curae', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'thanatos', 'curae', undef, [])}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'thanatos', 'curae', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'thanatos', 'curae', undef, {})}
	);
};
done_testing();
