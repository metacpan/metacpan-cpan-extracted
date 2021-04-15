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
	eval { $obj = Hades::Macro::YAML->new( { macro => 'limos' } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro::YAML->new({ macro => 'limos' })}
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
	eval { $obj->macro('penthos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->macro('penthos')} );
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
	eval { $obj->yaml_load_string( 'hypnos', 'phobos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_string('hypnos', 'phobos', undef, undef)}
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
	eval { $obj->_yaml_load_string_YAML( [], 'algea', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML([], 'algea', undef, undef)}
	);
	eval { $obj->_yaml_load_string_YAML( 'algea', 'algea', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML('algea', 'algea', undef, undef)}
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
			'algea', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), 'algea', [], undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML( bless( {}, 'Test' ),
			'algea', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), 'algea', \1, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML( bless( {}, 'Test' ),
			'algea', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), 'algea', undef, [])}
	);
	eval {
		$obj->_yaml_load_string_YAML( bless( {}, 'Test' ),
			'algea', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML(bless({}, 'Test'), 'algea', undef, {})}
	);
};
subtest '_yaml_load_string_YAML_XS' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_load_string_YAML_XS' );
	eval { $obj->_yaml_load_string_YAML_XS( [], 'limos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS([], 'limos', undef, undef)}
	);
	eval { $obj->_yaml_load_string_YAML_XS( 'nosoi', 'limos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS('nosoi', 'limos', undef, undef)}
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
			'limos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS(bless({}, 'Test'), 'limos', [], undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_XS( bless( {}, 'Test' ),
			'limos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS(bless({}, 'Test'), 'limos', \1, undef)}
	);
	eval {
		$obj->_yaml_load_string_YAML_XS( bless( {}, 'Test' ),
			'limos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS(bless({}, 'Test'), 'limos', undef, [])}
	);
	eval {
		$obj->_yaml_load_string_YAML_XS( bless( {}, 'Test' ),
			'limos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_XS(bless({}, 'Test'), 'limos', undef, {})}
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
		$obj->_yaml_load_string_YAML_PP( 'hypnos', 'hypnos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_string_YAML_PP('hypnos', 'hypnos', undef, undef)}
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
	eval { $obj->yaml_load_file( [], 'thanatos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file([], 'thanatos', undef, undef)}
	);
	eval { $obj->yaml_load_file( 'hypnos', 'thanatos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file('hypnos', 'thanatos', undef, undef)}
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
	eval {
		$obj->yaml_load_file( bless( {}, 'Test' ), 'thanatos', [], undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), 'thanatos', [], undef)}
	);
	eval {
		$obj->yaml_load_file( bless( {}, 'Test' ), 'thanatos', \1, undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), 'thanatos', \1, undef)}
	);
	eval {
		$obj->yaml_load_file( bless( {}, 'Test' ), 'thanatos', undef, [] );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), 'thanatos', undef, [])}
	);
	eval {
		$obj->yaml_load_file( bless( {}, 'Test' ), 'thanatos', undef, {} );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_load_file(bless({}, 'Test'), 'thanatos', undef, {})}
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
	eval { $obj->_yaml_load_file_YAML( 'phobos', 'phobos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML('phobos', 'phobos', undef, undef)}
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
	eval { $obj->_yaml_load_file_YAML_XS( [], 'hypnos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS([], 'hypnos', undef, undef)}
	);
	eval { $obj->_yaml_load_file_YAML_XS( 'aporia', 'hypnos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS('aporia', 'hypnos', undef, undef)}
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
			'hypnos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), 'hypnos', [], undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_XS( bless( {}, 'Test' ),
			'hypnos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), 'hypnos', \1, undef)}
	);
	eval {
		$obj->_yaml_load_file_YAML_XS( bless( {}, 'Test' ),
			'hypnos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), 'hypnos', undef, [])}
	);
	eval {
		$obj->_yaml_load_file_YAML_XS( bless( {}, 'Test' ),
			'hypnos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_XS(bless({}, 'Test'), 'hypnos', undef, {})}
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
	eval {
		$obj->_yaml_load_file_YAML_PP( 'thanatos', 'nosoi', undef, undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_load_file_YAML_PP('thanatos', 'nosoi', undef, undef)}
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
	eval { $obj->yaml_write_string( [], 'thanatos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string([], 'thanatos', undef, undef)}
	);
	eval { $obj->yaml_write_string( 'penthos', 'thanatos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string('penthos', 'thanatos', undef, undef)}
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
		$obj->yaml_write_string( bless( {}, 'Test' ), 'thanatos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string(bless({}, 'Test'), 'thanatos', [], undef)}
	);
	eval {
		$obj->yaml_write_string( bless( {}, 'Test' ), 'thanatos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string(bless({}, 'Test'), 'thanatos', \1, undef)}
	);
	eval {
		$obj->yaml_write_string( bless( {}, 'Test' ), 'thanatos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string(bless({}, 'Test'), 'thanatos', undef, [])}
	);
	eval {
		$obj->yaml_write_string( bless( {}, 'Test' ), 'thanatos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_string(bless({}, 'Test'), 'thanatos', undef, {})}
	);
};
subtest '_yaml_write_string_YAML' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_string_YAML' );
	eval { $obj->_yaml_write_string_YAML( [], 'limos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML([], 'limos', undef, undef)}
	);
	eval { $obj->_yaml_write_string_YAML( 'hypnos', 'limos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML('hypnos', 'limos', undef, undef)}
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
			'limos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), 'limos', [], undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML( bless( {}, 'Test' ),
			'limos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), 'limos', \1, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML( bless( {}, 'Test' ),
			'limos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), 'limos', undef, [])}
	);
	eval {
		$obj->_yaml_write_string_YAML( bless( {}, 'Test' ),
			'limos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML(bless({}, 'Test'), 'limos', undef, {})}
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
		$obj->_yaml_write_string_YAML_XS( 'penthos', 'hypnos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_XS('penthos', 'hypnos', undef, undef)}
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
	eval { $obj->_yaml_write_string_YAML_PP( [], 'aporia', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP([], 'aporia', undef, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( 'thanatos', 'aporia', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP('thanatos', 'aporia', undef, undef)}
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
			'aporia', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), 'aporia', [], undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( bless( {}, 'Test' ),
			'aporia', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), 'aporia', \1, undef)}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( bless( {}, 'Test' ),
			'aporia', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), 'aporia', undef, [])}
	);
	eval {
		$obj->_yaml_write_string_YAML_PP( bless( {}, 'Test' ),
			'aporia', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_string_YAML_PP(bless({}, 'Test'), 'aporia', undef, {})}
	);
};
subtest 'yaml_write_file' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, 'yaml_write_file' );
	eval { $obj->yaml_write_file( [], 'geras', 'limos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file([], 'geras', 'limos', undef, undef)}
	);
	eval { $obj->yaml_write_file( 'geras', 'geras', 'limos', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file('geras', 'geras', 'limos', undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			[], 'limos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), [], 'limos', undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			\1, 'limos', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), \1, 'limos', undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'geras', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'geras', [], undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'geras', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'geras', \1, undef, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'geras', 'limos', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'geras', 'limos', [], undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'geras', 'limos', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'geras', 'limos', \1, undef)}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'geras', 'limos', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'geras', 'limos', undef, [])}
	);
	eval {
		$obj->yaml_write_file( bless( {}, 'Test' ),
			'geras', 'limos', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->yaml_write_file(bless({}, 'Test'), 'geras', 'limos', undef, {})}
	);
};
subtest '_yaml_write_file_YAML' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_file_YAML' );
	eval {
		$obj->_yaml_write_file_YAML( [], 'thanatos', 'nosoi', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML([], 'thanatos', 'nosoi', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( 'phobos', 'thanatos', 'nosoi', undef,
			undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML('phobos', 'thanatos', 'nosoi', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			[], 'nosoi', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), [], 'nosoi', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			\1, 'nosoi', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), \1, 'nosoi', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'thanatos', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'thanatos', [], undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'thanatos', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'thanatos', \1, undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'thanatos', 'nosoi', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'thanatos', 'nosoi', [], undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'thanatos', 'nosoi', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'thanatos', 'nosoi', \1, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'thanatos', 'nosoi', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'thanatos', 'nosoi', undef, [])}
	);
	eval {
		$obj->_yaml_write_file_YAML( bless( {}, 'Test' ),
			'thanatos', 'nosoi', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML(bless({}, 'Test'), 'thanatos', 'nosoi', undef, {})}
	);
};
subtest '_yaml_write_file_YAML_XS' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_file_YAML_XS' );
	eval {
		$obj->_yaml_write_file_YAML_XS( [], 'limos', 'algea', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS([], 'limos', 'algea', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( 'thanatos', 'limos', 'algea', undef,
			undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS('thanatos', 'limos', 'algea', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			[], 'algea', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), [], 'algea', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			\1, 'algea', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), \1, 'algea', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'limos', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'limos', [], undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'limos', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'limos', \1, undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'limos', 'algea', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'limos', 'algea', [], undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'limos', 'algea', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'limos', 'algea', \1, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'limos', 'algea', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'limos', 'algea', undef, [])}
	);
	eval {
		$obj->_yaml_write_file_YAML_XS( bless( {}, 'Test' ),
			'limos', 'algea', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_XS(bless({}, 'Test'), 'limos', 'algea', undef, {})}
	);
};
subtest '_yaml_write_file_YAML_PP' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::YAML->new( {} ),
		q{my $obj = Hades::Macro::YAML->new({})}
	);
	can_ok( $obj, '_yaml_write_file_YAML_PP' );
	eval {
		$obj->_yaml_write_file_YAML_PP( [], 'hypnos', 'curae', undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP([], 'hypnos', 'curae', undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( 'hypnos', 'hypnos', 'curae', undef,
			undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP('hypnos', 'hypnos', 'curae', undef, undef)}
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
			'hypnos', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'hypnos', [], undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'hypnos', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'hypnos', \1, undef, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'hypnos', 'curae', [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'hypnos', 'curae', [], undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'hypnos', 'curae', \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'hypnos', 'curae', \1, undef)}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'hypnos', 'curae', undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'hypnos', 'curae', undef, [])}
	);
	eval {
		$obj->_yaml_write_file_YAML_PP( bless( {}, 'Test' ),
			'hypnos', 'curae', undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_yaml_write_file_YAML_PP(bless({}, 'Test'), 'hypnos', 'curae', undef, {})}
	);
};
done_testing();
