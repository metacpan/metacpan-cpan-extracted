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
	eval { $obj = Hades::Realm::Exporter->new( { export => 'phobos' } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::Exporter->new({ export => 'phobos' })}
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
	eval { $obj->export('penthos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export('penthos')} );
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
			'curae',
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->default_export_hash('curae', { 'test' => 'test' }, { 'test' => 'test' })}
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
			'limos', { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->default_export_hash(bless({}, 'Test'), 'limos', { 'test' => 'test' })}
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
			{ 'test' => 'test' }, 'aporia' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->default_export_hash(bless({}, 'Test'), { 'test' => 'test' }, 'aporia')}
	);
};
subtest 'build_new' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_new' );
	eval { $obj->build_new( [], { 'test' => 'test' }, 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new([], { 'test' => 'test' }, 'limos')}
	);
	eval { $obj->build_new( 'algea', { 'test' => 'test' }, 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new('algea', { 'test' => 'test' }, 'limos')}
	);
	eval { $obj->build_new( bless( {}, 'Test' ), [], 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new(bless({}, 'Test'), [], 'limos')}
	);
	eval { $obj->build_new( bless( {}, 'Test' ), 'algea', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new(bless({}, 'Test'), 'algea', 'limos')}
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
			'gaudia', [],
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter('gaudia', [], { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter(
			'gaudia', 'curae',
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter('gaudia', 'curae', { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter( 'gaudia', bless( {}, 'Test' ),
			[], { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter('gaudia', bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter( 'gaudia', bless( {}, 'Test' ),
			'curae', { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter('gaudia', bless({}, 'Test'), 'curae', { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter(
			'gaudia',
			bless( {}, 'Test' ),
			{ 'test' => 'test' }, []
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter('gaudia', bless({}, 'Test'), { 'test' => 'test' }, [])}
	);
	eval {
		$obj->build_exporter(
			'gaudia',
			bless( {}, 'Test' ),
			{ 'test' => 'test' }, 'phobos'
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_exporter('gaudia', bless({}, 'Test'), { 'test' => 'test' }, 'phobos')}
	);
};
subtest 'build_export_tags' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_export_tags' );
	eval {
		$obj->build_export_tags( [], 'hypnos', { 'test' => 'test' },
			undef, ['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags([], 'hypnos', { 'test' => 'test' }, undef, ['test'])}
	);
	eval {
		$obj->build_export_tags( \1, 'hypnos', { 'test' => 'test' },
			undef, ['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags(\1, 'hypnos', { 'test' => 'test' }, undef, ['test'])}
	);
	eval {
		$obj->build_export_tags( 'gaudia', [], { 'test' => 'test' },
			undef, ['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('gaudia', [], { 'test' => 'test' }, undef, ['test'])}
	);
	eval {
		$obj->build_export_tags( 'gaudia', \1, { 'test' => 'test' },
			undef, ['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('gaudia', \1, { 'test' => 'test' }, undef, ['test'])}
	);
	eval {
		$obj->build_export_tags( 'gaudia', 'hypnos', [], undef, ['test'] );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('gaudia', 'hypnos', [], undef, ['test'])}
	);
	eval {
		$obj->build_export_tags( 'gaudia', 'hypnos', 'geras', undef,
			['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('gaudia', 'hypnos', 'geras', undef, ['test'])}
	);
	eval {
		$obj->build_export_tags( 'gaudia', 'hypnos', { 'test' => 'test' },
			[], ['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('gaudia', 'hypnos', { 'test' => 'test' }, [], ['test'])}
	);
	eval {
		$obj->build_export_tags( 'gaudia', 'hypnos', { 'test' => 'test' },
			'thanatos', ['test'] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('gaudia', 'hypnos', { 'test' => 'test' }, 'thanatos', ['test'])}
	);
	eval {
		$obj->build_export_tags( 'gaudia', 'hypnos', { 'test' => 'test' },
			undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('gaudia', 'hypnos', { 'test' => 'test' }, undef, {})}
	);
	eval {
		$obj->build_export_tags( 'gaudia', 'hypnos', { 'test' => 'test' },
			undef, 'nosoi' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_export_tags('gaudia', 'hypnos', { 'test' => 'test' }, undef, 'nosoi')}
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
	eval { $obj->after_class('curae') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->after_class('curae')} );
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
	eval { $obj->build_accessor_code( [], 'thanatos', 'hypnos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code([], 'thanatos', 'hypnos', 'aporia')}
	);
	eval { $obj->build_accessor_code( \1, 'thanatos', 'hypnos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code(\1, 'thanatos', 'hypnos', 'aporia')}
	);
	eval { $obj->build_accessor_code( 'phobos', [], 'hypnos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code('phobos', [], 'hypnos', 'aporia')}
	);
	eval { $obj->build_accessor_code( 'phobos', \1, 'hypnos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code('phobos', \1, 'hypnos', 'aporia')}
	);
	eval { $obj->build_accessor_code( 'phobos', 'thanatos', [], 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code('phobos', 'thanatos', [], 'aporia')}
	);
	eval { $obj->build_accessor_code( 'phobos', 'thanatos', \1, 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code('phobos', 'thanatos', \1, 'aporia')}
	);
	eval { $obj->build_accessor_code( 'phobos', 'thanatos', 'hypnos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code('phobos', 'thanatos', 'hypnos', [])}
	);
	eval { $obj->build_accessor_code( 'phobos', 'thanatos', 'hypnos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_code('phobos', 'thanatos', 'hypnos', \1)}
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
	eval { $obj->build_sub_code( [], 'limos', 'geras', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code([], 'limos', 'geras', 'aporia')}
	);
	eval { $obj->build_sub_code( \1, 'limos', 'geras', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code(\1, 'limos', 'geras', 'aporia')}
	);
	eval { $obj->build_sub_code( 'aporia', [], 'geras', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code('aporia', [], 'geras', 'aporia')}
	);
	eval { $obj->build_sub_code( 'aporia', \1, 'geras', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code('aporia', \1, 'geras', 'aporia')}
	);
	eval { $obj->build_sub_code( 'aporia', 'limos', [], 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code('aporia', 'limos', [], 'aporia')}
	);
	eval { $obj->build_sub_code( 'aporia', 'limos', \1, 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code('aporia', 'limos', \1, 'aporia')}
	);
	eval { $obj->build_sub_code( 'aporia', 'limos', 'geras', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code('aporia', 'limos', 'geras', [])}
	);
	eval { $obj->build_sub_code( 'aporia', 'limos', 'geras', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_sub_code('aporia', 'limos', 'geras', \1)}
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
	eval { $obj->build_clearer( [], 'penthos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_clearer([], 'penthos', { 'test' => 'test' })}
	);
	eval { $obj->build_clearer( 'algea', 'penthos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_clearer('algea', 'penthos', { 'test' => 'test' })}
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
	eval { $obj->build_clearer( bless( {}, 'Test' ), 'penthos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_clearer(bless({}, 'Test'), 'penthos', [])}
	);
	eval { $obj->build_clearer( bless( {}, 'Test' ), 'penthos', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_clearer(bless({}, 'Test'), 'penthos', 'thanatos')}
	);
};
subtest 'build_predicate' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_predicate' );
	eval { $obj->build_predicate( [], 'limos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_predicate([], 'limos', { 'test' => 'test' })}
	);
	eval { $obj->build_predicate( 'phobos', 'limos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_predicate('phobos', 'limos', { 'test' => 'test' })}
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
	eval { $obj->build_predicate( bless( {}, 'Test' ), 'limos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_predicate(bless({}, 'Test'), 'limos', [])}
	);
	eval { $obj->build_predicate( bless( {}, 'Test' ), 'limos', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_predicate(bless({}, 'Test'), 'limos', 'geras')}
	);
};
subtest 'build_coerce' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_coerce' );
	eval { $obj->build_coerce( [], 'phobos', undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_coerce([], 'phobos', undef)}
	);
	eval { $obj->build_coerce( \1, 'phobos', undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_coerce(\1, 'phobos', undef)}
	);
	eval { $obj->build_coerce( 'curae', [], undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_coerce('curae', [], undef)}
	);
	eval { $obj->build_coerce( 'curae', \1, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_coerce('curae', \1, undef)}
	);
	eval { $obj->build_coerce( 'curae', 'phobos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_coerce('curae', 'phobos', [])}
	);
	eval { $obj->build_coerce( 'curae', 'phobos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_coerce('curae', 'phobos', \1)}
	);
};
subtest 'build_trigger' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::Exporter->new( {} ),
		q{my $obj = Hades::Realm::Exporter->new({})}
	);
	can_ok( $obj, 'build_trigger' );
	eval { $obj->build_trigger( [], 'hypnos', undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_trigger([], 'hypnos', undef)}
	);
	eval { $obj->build_trigger( \1, 'hypnos', undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_trigger(\1, 'hypnos', undef)}
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
	eval { $obj->build_trigger( 'limos', 'hypnos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_trigger('limos', 'hypnos', [])}
	);
	eval { $obj->build_trigger( 'limos', 'hypnos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_trigger('limos', 'hypnos', \1)}
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
	eval { $obj->build_tests( 'hypnos', [], undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests('hypnos', [], undef, undef)}
	);
	eval { $obj->build_tests( 'hypnos', 'geras', undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests('hypnos', 'geras', undef, undef)}
	);
	eval { $obj->build_tests( 'hypnos', { 'test' => 'test' }, [], undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests('hypnos', { 'test' => 'test' }, [], undef)}
	);
	eval { $obj->build_tests( 'hypnos', { 'test' => 'test' }, \1, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests('hypnos', { 'test' => 'test' }, \1, undef)}
	);
	eval { $obj->build_tests( 'hypnos', { 'test' => 'test' }, undef, [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests('hypnos', { 'test' => 'test' }, undef, [])}
	);
	eval {
		$obj->build_tests( 'hypnos', { 'test' => 'test' }, undef, 'gaudia' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_tests('hypnos', { 'test' => 'test' }, undef, 'gaudia')}
	);
};
done_testing();
