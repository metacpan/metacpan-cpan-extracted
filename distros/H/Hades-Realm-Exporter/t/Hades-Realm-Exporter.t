use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Hades::Realm::Exporter');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 9;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	ok( $obj = Hades::Realm::Exporter->new(),
		q{$obj = Hades::Realm::Exporter->new()}
	);
	isa_ok( $obj, 'Hades::Realm::Exporter' );
	ok( $obj = Hades::Realm::Exporter->new( {} ),
		q{$obj = Hades::Realm::Exporter->new({})}
	);
	ok( $obj = Hades::Realm::Exporter->new(),
		q{$obj = Hades::Realm::Exporter->new()}
	);
	is_deeply( $obj->export, {}, q{$obj->export} );
	ok( $obj
		    = Hades::Realm::Exporter->new(
			{ export => { 'test' => 'test' } } ),
		q{$obj = Hades::Realm::Exporter->new({ export => { 'test' => 'test' } })}
	);
	eval { $obj = Hades::Realm::Exporter->new( { export => [] } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::Exporter->new({ export => [] })}
	);
	eval { $obj = Hades::Realm::Exporter->new( { export => 'algea' } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::Exporter->new({ export => 'algea' })}
	);
};
subtest 'export' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'export' );
	is_deeply(
		$obj->export( { 'test' => 'test' } ),
		{ 'test' => 'test' },
		q{$obj->export({ 'test' => 'test' })}
	);
	eval { $obj->export( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export([])} );
	eval { $obj->export('phobos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export('phobos')} );
	is_deeply( $obj->export, { 'test' => 'test' }, q{$obj->export} );
};
subtest 'build_self' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_self' );
	eval { $obj->build_self( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_self([])} );
	eval { $obj->build_self( \1 ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_self(\1)} );
};
subtest 'default_export_hash' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'default_export_hash' );
	eval {
		$obj->default_export_hash(
			[],
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->default_export_hash([], { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval {
		$obj->default_export_hash(
			'penthos',
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->default_export_hash('penthos', { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval {
		$obj->default_export_hash( bless( {}, 'Test' ),
			[], { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->default_export_hash(bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval {
		$obj->default_export_hash( bless( {}, 'Test' ),
			'curae', { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->default_export_hash(bless({}, 'Test'), 'curae', { 'test' => 'test' })}
	);
	eval {
		$obj->default_export_hash( bless( {}, 'Test' ),
			{ 'test' => 'test' }, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->default_export_hash(bless({}, 'Test'), { 'test' => 'test' }, [])}
	);
	eval {
		$obj->default_export_hash( bless( {}, 'Test' ),
			{ 'test' => 'test' }, 'phobos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->default_export_hash(bless({}, 'Test'), { 'test' => 'test' }, 'phobos')}
	);
};
subtest 'build_new' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_new' );
	eval { $obj->build_new( [], { 'test' => 'test' }, 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new([], { 'test' => 'test' }, 'gaudia')}
	);
	eval { $obj->build_new( 'aporia', { 'test' => 'test' }, 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new('aporia', { 'test' => 'test' }, 'gaudia')}
	);
	eval { $obj->build_new( bless( {}, 'Test' ), [], 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new(bless({}, 'Test'), [], 'gaudia')}
	);
	eval { $obj->build_new( bless( {}, 'Test' ), 'hypnos', 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new(bless({}, 'Test'), 'hypnos', 'gaudia')}
	);
};
subtest 'build_exporter' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_exporter' );
	eval {
		$obj->build_exporter(
			[],
			bless( {}, 'Test' ),
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter([], bless({}, 'Test'), { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter(
			\1,
			bless( {}, 'Test' ),
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter(\1, bless({}, 'Test'), { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter(
			'thanatos', [],
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter('thanatos', [], { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter(
			'thanatos', 'penthos',
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter('thanatos', 'penthos', { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter( 'thanatos', bless( {}, 'Test' ),
			[], { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter('thanatos', bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter(
			'thanatos', bless( {}, 'Test' ),
			'penthos', { 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter('thanatos', bless({}, 'Test'), 'penthos', { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter(
			'thanatos',
			bless( {}, 'Test' ),
			{ 'test' => 'test' }, []
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter('thanatos', bless({}, 'Test'), { 'test' => 'test' }, [])}
	);
	eval {
		$obj->build_exporter(
			'thanatos',
			bless( {}, 'Test' ),
			{ 'test' => 'test' }, 'limos'
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter('thanatos', bless({}, 'Test'), { 'test' => 'test' }, 'limos')}
	);
};
subtest 'build_export_tags' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_export_tags' );
	eval {
		$obj->build_export_tags( [], 'curae', { 'test' => 'test' },
			undef, ['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags([], 'curae', { 'test' => 'test' }, undef, ['test'])}
	);
	eval {
		$obj->build_export_tags( \1, 'curae', { 'test' => 'test' },
			undef, ['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags(\1, 'curae', { 'test' => 'test' }, undef, ['test'])}
	);
	eval {
		$obj->build_export_tags( 'limos', [], { 'test' => 'test' },
			undef, ['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('limos', [], { 'test' => 'test' }, undef, ['test'])}
	);
	eval {
		$obj->build_export_tags( 'limos', \1, { 'test' => 'test' },
			undef, ['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('limos', \1, { 'test' => 'test' }, undef, ['test'])}
	);
	eval { $obj->build_export_tags( 'limos', 'curae', [], undef, ['test'] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('limos', 'curae', [], undef, ['test'])}
	);
	eval {
		$obj->build_export_tags( 'limos', 'curae', 'nosoi', undef, ['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('limos', 'curae', 'nosoi', undef, ['test'])}
	);
	eval {
		$obj->build_export_tags( 'limos', 'curae', { 'test' => 'test' },
			[], ['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('limos', 'curae', { 'test' => 'test' }, [], ['test'])}
	);
	eval {
		$obj->build_export_tags( 'limos', 'curae', { 'test' => 'test' },
			'hypnos', ['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('limos', 'curae', { 'test' => 'test' }, 'hypnos', ['test'])}
	);
	eval {
		$obj->build_export_tags( 'limos', 'curae', { 'test' => 'test' },
			undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('limos', 'curae', { 'test' => 'test' }, undef, {})}
	);
	eval {
		$obj->build_export_tags( 'limos', 'curae', { 'test' => 'test' },
			undef, 'curae' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('limos', 'curae', { 'test' => 'test' }, undef, 'curae')}
	);
};
subtest 'after_class' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'after_class' );
	eval { $obj->after_class( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->after_class([])} );
	eval { $obj->after_class('nosoi') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->after_class('nosoi')} );
};
subtest 'build_sub_or_accessor_attributes' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_sub_or_accessor_attributes' );
};
subtest 'build_accessor_no_arguments' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_accessor_no_arguments' );
};
subtest 'build_accessor_code' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_accessor_code' );
	eval { $obj->build_accessor_code( [], 'geras', 'thanatos', 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code([], 'geras', 'thanatos', 'gaudia')}
	);
	eval { $obj->build_accessor_code( \1, 'geras', 'thanatos', 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code(\1, 'geras', 'thanatos', 'gaudia')}
	);
	eval { $obj->build_accessor_code( 'phobos', [], 'thanatos', 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code('phobos', [], 'thanatos', 'gaudia')}
	);
	eval { $obj->build_accessor_code( 'phobos', \1, 'thanatos', 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code('phobos', \1, 'thanatos', 'gaudia')}
	);
	eval { $obj->build_accessor_code( 'phobos', 'geras', [], 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code('phobos', 'geras', [], 'gaudia')}
	);
	eval { $obj->build_accessor_code( 'phobos', 'geras', \1, 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code('phobos', 'geras', \1, 'gaudia')}
	);
	eval { $obj->build_accessor_code( 'phobos', 'geras', 'thanatos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code('phobos', 'geras', 'thanatos', [])}
	);
	eval { $obj->build_accessor_code( 'phobos', 'geras', 'thanatos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code('phobos', 'geras', 'thanatos', \1)}
	);
};
subtest 'build_accessor' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_accessor' );
};
subtest 'build_modify' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_modify' );
};
subtest 'build_sub_no_arguments' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_sub_no_arguments' );
};
subtest 'build_sub_code' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_sub_code' );
	eval { $obj->build_sub_code( [], 'nosoi', 'gaudia', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code([], 'nosoi', 'gaudia', 'aporia')}
	);
	eval { $obj->build_sub_code( \1, 'nosoi', 'gaudia', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code(\1, 'nosoi', 'gaudia', 'aporia')}
	);
	eval { $obj->build_sub_code( 'nosoi', [], 'gaudia', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code('nosoi', [], 'gaudia', 'aporia')}
	);
	eval { $obj->build_sub_code( 'nosoi', \1, 'gaudia', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code('nosoi', \1, 'gaudia', 'aporia')}
	);
	eval { $obj->build_sub_code( 'nosoi', 'nosoi', [], 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code('nosoi', 'nosoi', [], 'aporia')}
	);
	eval { $obj->build_sub_code( 'nosoi', 'nosoi', \1, 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code('nosoi', 'nosoi', \1, 'aporia')}
	);
	eval { $obj->build_sub_code( 'nosoi', 'nosoi', 'gaudia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code('nosoi', 'nosoi', 'gaudia', [])}
	);
	eval { $obj->build_sub_code( 'nosoi', 'nosoi', 'gaudia', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code('nosoi', 'nosoi', 'gaudia', \1)}
	);
};
subtest 'build_sub' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_sub' );
};
subtest 'build_clearer' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_clearer' );
	eval { $obj->build_clearer( [], 'phobos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_clearer([], 'phobos', { 'test' => 'test' })}
	);
	eval { $obj->build_clearer( 'penthos', 'phobos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_clearer('penthos', 'phobos', { 'test' => 'test' })}
	);
	eval {
		$obj->build_clearer( bless( {}, 'Test' ), [], { 'test' => 'test' } );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_clearer(bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval {
		$obj->build_clearer( bless( {}, 'Test' ), \1, { 'test' => 'test' } );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_clearer(bless({}, 'Test'), \1, { 'test' => 'test' })}
	);
	eval { $obj->build_clearer( bless( {}, 'Test' ), 'phobos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_clearer(bless({}, 'Test'), 'phobos', [])}
	);
	eval { $obj->build_clearer( bless( {}, 'Test' ), 'phobos', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_clearer(bless({}, 'Test'), 'phobos', 'curae')}
	);
};
subtest 'build_predicate' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_predicate' );
	eval { $obj->build_predicate( [], 'nosoi', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_predicate([], 'nosoi', { 'test' => 'test' })}
	);
	eval { $obj->build_predicate( 'algea', 'nosoi', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_predicate('algea', 'nosoi', { 'test' => 'test' })}
	);
	eval {
		$obj->build_predicate( bless( {}, 'Test' ), [], { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_predicate(bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval {
		$obj->build_predicate( bless( {}, 'Test' ), \1, { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_predicate(bless({}, 'Test'), \1, { 'test' => 'test' })}
	);
	eval { $obj->build_predicate( bless( {}, 'Test' ), 'nosoi', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_predicate(bless({}, 'Test'), 'nosoi', [])}
	);
	eval { $obj->build_predicate( bless( {}, 'Test' ), 'nosoi', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_predicate(bless({}, 'Test'), 'nosoi', 'hypnos')}
	);
};
subtest 'build_coerce' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_coerce' );
	eval { $obj->build_coerce( [], 'nosoi', undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_coerce([], 'nosoi', undef)}
	);
	eval { $obj->build_coerce( \1, 'nosoi', undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_coerce(\1, 'nosoi', undef)}
	);
	eval { $obj->build_coerce( 'hypnos', [], undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_coerce('hypnos', [], undef)}
	);
	eval { $obj->build_coerce( 'hypnos', \1, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_coerce('hypnos', \1, undef)}
	);
	eval { $obj->build_coerce( 'hypnos', 'nosoi', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_coerce('hypnos', 'nosoi', [])}
	);
	eval { $obj->build_coerce( 'hypnos', 'nosoi', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_coerce('hypnos', 'nosoi', \1)}
	);
};
subtest 'build_trigger' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_trigger' );
	eval { $obj->build_trigger( [], 'penthos', undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_trigger([], 'penthos', undef)}
	);
	eval { $obj->build_trigger( \1, 'penthos', undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_trigger(\1, 'penthos', undef)}
	);
	eval { $obj->build_trigger( 'limos', [], undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_trigger('limos', [], undef)}
	);
	eval { $obj->build_trigger( 'limos', \1, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_trigger('limos', \1, undef)}
	);
	eval { $obj->build_trigger( 'limos', 'penthos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_trigger('limos', 'penthos', [])}
	);
	eval { $obj->build_trigger( 'limos', 'penthos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_trigger('limos', 'penthos', \1)}
	);
};
subtest 'build_tests' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_tests' );
	eval { $obj->build_tests( [], { 'test' => 'test' }, undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests([], { 'test' => 'test' }, undef, undef)}
	);
	eval { $obj->build_tests( \1, { 'test' => 'test' }, undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests(\1, { 'test' => 'test' }, undef, undef)}
	);
	eval { $obj->build_tests( 'algea', [], undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests('algea', [], undef, undef)}
	);
	eval { $obj->build_tests( 'algea', 'gaudia', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests('algea', 'gaudia', undef, undef)}
	);
	eval { $obj->build_tests( 'algea', { 'test' => 'test' }, [], undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests('algea', { 'test' => 'test' }, [], undef)}
	);
	eval { $obj->build_tests( 'algea', { 'test' => 'test' }, \1, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests('algea', { 'test' => 'test' }, \1, undef)}
	);
	eval { $obj->build_tests( 'algea', { 'test' => 'test' }, undef, [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests('algea', { 'test' => 'test' }, undef, [])}
	);
	eval {
		$obj->build_tests( 'algea', { 'test' => 'test' }, undef, 'algea' );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests('algea', { 'test' => 'test' }, undef, 'algea')}
	);
};
done_testing();
