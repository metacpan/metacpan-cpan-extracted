use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Hades::Macro::Dolos');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 9;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	ok( $obj = Hades::Macro::Dolos->new(),
		q{$obj = Hades::Macro::Dolos->new()}
	);
	isa_ok( $obj, 'Hades::Macro::Dolos' );
	ok( $obj = Hades::Macro::Dolos->new( {} ),
		q{$obj = Hades::Macro::Dolos->new({})}
	);
	ok( $obj = Hades::Macro::Dolos->new(),
		q{$obj = Hades::Macro::Dolos->new()}
	);
	is_deeply(
		$obj->macro,
		[   qw/
			    autoload_cb
			    caller
			    clear_unless_keys
			    call_sub
			    call_sub_my
			    delete
			    die_unless_keys
			    else
			    elsif
			    export
			    for
			    foreach
			    for_keys
			    for_key_exists_and_return
			    grep
			    grep_map
			    if
			    map
			    map_grep
			    maybe
			    merge_hash_refs
			    require
			    unless
			    while
			    /
		],
		q{$obj->macro}
	);
	ok( $obj = Hades::Macro::Dolos->new( { macro => ['test'] } ),
		q{$obj = Hades::Macro::Dolos->new({ macro => ['test'] })}
	);
	eval { $obj = Hades::Macro::Dolos->new( { macro => {} } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro::Dolos->new({ macro => {} })}
	);
	eval { $obj = Hades::Macro::Dolos->new( { macro => 'thanatos' } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro::Dolos->new({ macro => 'thanatos' })}
	);
};
subtest 'macro' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'macro' );
	is_deeply( $obj->macro( ['test'] ), ['test'], q{$obj->macro(['test'])} );
	eval { $obj->macro( {} ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->macro({})} );
	eval { $obj->macro('aporia') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->macro('aporia')} );
	is_deeply( $obj->macro, ['test'], q{$obj->macro} );
};
subtest 'autoload_cb' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'autoload_cb' );
	eval { $obj->autoload_cb( [], 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->autoload_cb([], 'gaudia')}
	);
	eval { $obj->autoload_cb( 'hypnos', 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->autoload_cb('hypnos', 'gaudia')}
	);
	eval { $obj->autoload_cb( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->autoload_cb(bless({}, 'Test'), [])}
	);
	eval { $obj->autoload_cb( bless( {}, 'Test' ), \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->autoload_cb(bless({}, 'Test'), \1)}
	);
};
subtest 'caller' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'caller' );
	eval { $obj->caller( [], 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->caller([], 'aporia')}
	);
	eval { $obj->caller( 'aporia', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->caller('aporia', 'aporia')}
	);
	eval { $obj->caller( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->caller(bless({}, 'Test'), [])}
	);
	eval { $obj->caller( bless( {}, 'Test' ), \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->caller(bless({}, 'Test'), \1)}
	);
};
subtest 'clear_unless_keys' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'clear_unless_keys' );
	eval { $obj->clear_unless_keys( [], 'gaudia', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->clear_unless_keys([], 'gaudia', 'hypnos')}
	);
	eval { $obj->clear_unless_keys( 'penthos', 'gaudia', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->clear_unless_keys('penthos', 'gaudia', 'hypnos')}
	);
	eval { $obj->clear_unless_keys( bless( {}, 'Test' ), [], 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->clear_unless_keys(bless({}, 'Test'), [], 'hypnos')}
	);
	eval { $obj->clear_unless_keys( bless( {}, 'Test' ), \1, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->clear_unless_keys(bless({}, 'Test'), \1, 'hypnos')}
	);
	eval { $obj->clear_unless_keys( bless( {}, 'Test' ), 'gaudia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->clear_unless_keys(bless({}, 'Test'), 'gaudia', [])}
	);
	eval { $obj->clear_unless_keys( bless( {}, 'Test' ), 'gaudia', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->clear_unless_keys(bless({}, 'Test'), 'gaudia', \1)}
	);
};
subtest 'call_sub' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'call_sub' );
	eval { $obj->call_sub( [], 'hypnos', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->call_sub([], 'hypnos', 'geras')}
	);
	eval { $obj->call_sub( 'limos', 'hypnos', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->call_sub('limos', 'hypnos', 'geras')}
	);
};
subtest 'call_sub_my' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'call_sub_my' );
	eval { $obj->call_sub_my( [], 'curae', 'limos', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->call_sub_my([], 'curae', 'limos', 'curae')}
	);
	eval { $obj->call_sub_my( 'penthos', 'curae', 'limos', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->call_sub_my('penthos', 'curae', 'limos', 'curae')}
	);
	eval { $obj->call_sub_my( bless( {}, 'Test' ), [], 'limos', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->call_sub_my(bless({}, 'Test'), [], 'limos', 'curae')}
	);
	eval { $obj->call_sub_my( bless( {}, 'Test' ), \1, 'limos', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->call_sub_my(bless({}, 'Test'), \1, 'limos', 'curae')}
	);
};
subtest 'delete' => sub {
	plan tests => 14;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'delete' );
	eval { $obj->delete( [], 'thanatos', 'gaudia', undef, undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->delete([], 'thanatos', 'gaudia', undef, undef, undef)}
	);
	eval {
		$obj->delete( 'gaudia', 'thanatos', 'gaudia', undef, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->delete('gaudia', 'thanatos', 'gaudia', undef, undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ), [], 'gaudia', undef, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->delete(bless({}, 'Test'), [], 'gaudia', undef, undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ), \1, 'gaudia', undef, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->delete(bless({}, 'Test'), \1, 'gaudia', undef, undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'thanatos', [], undef, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->delete(bless({}, 'Test'), 'thanatos', [], undef, undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'thanatos', \1, undef, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->delete(bless({}, 'Test'), 'thanatos', \1, undef, undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'thanatos', 'gaudia', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->delete(bless({}, 'Test'), 'thanatos', 'gaudia', [], undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'thanatos', 'gaudia', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->delete(bless({}, 'Test'), 'thanatos', 'gaudia', \1, undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'thanatos', 'gaudia', undef, [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->delete(bless({}, 'Test'), 'thanatos', 'gaudia', undef, [], undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'thanatos', 'gaudia', undef, \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->delete(bless({}, 'Test'), 'thanatos', 'gaudia', undef, \1, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'thanatos', 'gaudia', undef, undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->delete(bless({}, 'Test'), 'thanatos', 'gaudia', undef, undef, [])}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'thanatos', 'gaudia', undef, undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->delete(bless({}, 'Test'), 'thanatos', 'gaudia', undef, undef, {})}
	);
};
subtest 'die_unless_keys' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'die_unless_keys' );
	eval { $obj->die_unless_keys( [], 'nosoi', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->die_unless_keys([], 'nosoi', 'hypnos')}
	);
	eval { $obj->die_unless_keys( 'geras', 'nosoi', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->die_unless_keys('geras', 'nosoi', 'hypnos')}
	);
	eval { $obj->die_unless_keys( bless( {}, 'Test' ), [], 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->die_unless_keys(bless({}, 'Test'), [], 'hypnos')}
	);
	eval { $obj->die_unless_keys( bless( {}, 'Test' ), \1, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->die_unless_keys(bless({}, 'Test'), \1, 'hypnos')}
	);
	eval { $obj->die_unless_keys( bless( {}, 'Test' ), 'nosoi', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->die_unless_keys(bless({}, 'Test'), 'nosoi', [])}
	);
	eval { $obj->die_unless_keys( bless( {}, 'Test' ), 'nosoi', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->die_unless_keys(bless({}, 'Test'), 'nosoi', \1)}
	);
};
subtest 'else' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'else' );
	eval { $obj->else( [], 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->else([], 'limos')}
	);
	eval { $obj->else( 'aporia', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->else('aporia', 'limos')}
	);
};
subtest 'elsif' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'elsif' );
	eval { $obj->elsif( [], 'algea', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->elsif([], 'algea', 'thanatos')}
	);
	eval { $obj->elsif( 'curae', 'algea', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->elsif('curae', 'algea', 'thanatos')}
	);
	eval { $obj->elsif( bless( {}, 'Test' ), [], 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->elsif(bless({}, 'Test'), [], 'thanatos')}
	);
	eval { $obj->elsif( bless( {}, 'Test' ), \1, 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->elsif(bless({}, 'Test'), \1, 'thanatos')}
	);
};
subtest 'export' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'export' );
	eval { $obj->export( [], 'aporia', 'algea', 10, 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export([], 'aporia', 'algea', 10, 'algea')}
	);
	eval { $obj->export( 'algea', 'aporia', 'algea', 10, 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export('algea', 'aporia', 'algea', 10, 'algea')}
	);
	eval { $obj->export( bless( {}, 'Test' ), [], 'algea', 10, 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), [], 'algea', 10, 'algea')}
	);
	eval { $obj->export( bless( {}, 'Test' ), \1, 'algea', 10, 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), \1, 'algea', 10, 'algea')}
	);
	eval { $obj->export( bless( {}, 'Test' ), 'aporia', [], 10, 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), 'aporia', [], 10, 'algea')}
	);
	eval { $obj->export( bless( {}, 'Test' ), 'aporia', \1, 10, 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), 'aporia', \1, 10, 'algea')}
	);
	eval {
		$obj->export( bless( {}, 'Test' ), 'aporia', 'algea', [], 'algea' );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), 'aporia', 'algea', [], 'algea')}
	);
	eval {
		$obj->export( bless( {}, 'Test' ),
			'aporia', 'algea', 'gaudia', 'algea' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), 'aporia', 'algea', 'gaudia', 'algea')}
	);
	eval { $obj->export( bless( {}, 'Test' ), 'aporia', 'algea', 10, [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), 'aporia', 'algea', 10, [])}
	);
	eval { $obj->export( bless( {}, 'Test' ), 'aporia', 'algea', 10, \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), 'aporia', 'algea', 10, \1)}
	);
};
subtest 'for' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'for' );
	eval { $obj->for( [], 'algea', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for([], 'algea', 'phobos')}
	);
	eval { $obj->for( 'geras', 'algea', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for('geras', 'algea', 'phobos')}
	);
	eval { $obj->for( bless( {}, 'Test' ), [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for(bless({}, 'Test'), [], 'phobos')}
	);
	eval { $obj->for( bless( {}, 'Test' ), \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for(bless({}, 'Test'), \1, 'phobos')}
	);
};
subtest 'foreach' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'foreach' );
	eval { $obj->foreach( [], 'penthos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->foreach([], 'penthos', 'aporia')}
	);
	eval { $obj->foreach( 'hypnos', 'penthos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->foreach('hypnos', 'penthos', 'aporia')}
	);
	eval { $obj->foreach( bless( {}, 'Test' ), [], 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->foreach(bless({}, 'Test'), [], 'aporia')}
	);
	eval { $obj->foreach( bless( {}, 'Test' ), \1, 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->foreach(bless({}, 'Test'), \1, 'aporia')}
	);
};
subtest 'for_keys' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'for_keys' );
	eval { $obj->for_keys( [], 'algea', 'thanatos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_keys([], 'algea', 'thanatos', 'aporia')}
	);
	eval { $obj->for_keys( 'gaudia', 'algea', 'thanatos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_keys('gaudia', 'algea', 'thanatos', 'aporia')}
	);
	eval { $obj->for_keys( bless( {}, 'Test' ), [], 'thanatos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_keys(bless({}, 'Test'), [], 'thanatos', 'aporia')}
	);
	eval { $obj->for_keys( bless( {}, 'Test' ), \1, 'thanatos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_keys(bless({}, 'Test'), \1, 'thanatos', 'aporia')}
	);
	eval { $obj->for_keys( bless( {}, 'Test' ), 'algea', [], 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_keys(bless({}, 'Test'), 'algea', [], 'aporia')}
	);
	eval { $obj->for_keys( bless( {}, 'Test' ), 'algea', \1, 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_keys(bless({}, 'Test'), 'algea', \1, 'aporia')}
	);
};
subtest 'for_key_exists_and_return' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'for_key_exists_and_return' );
	eval { $obj->for_key_exists_and_return( [], 'nosoi', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_key_exists_and_return([], 'nosoi', 'phobos')}
	);
	eval { $obj->for_key_exists_and_return( 'geras', 'nosoi', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_key_exists_and_return('geras', 'nosoi', 'phobos')}
	);
	eval {
		$obj->for_key_exists_and_return( bless( {}, 'Test' ), [], 'phobos' );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_key_exists_and_return(bless({}, 'Test'), [], 'phobos')}
	);
	eval {
		$obj->for_key_exists_and_return( bless( {}, 'Test' ), \1, 'phobos' );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_key_exists_and_return(bless({}, 'Test'), \1, 'phobos')}
	);
	eval {
		$obj->for_key_exists_and_return( bless( {}, 'Test' ), 'nosoi', [] );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_key_exists_and_return(bless({}, 'Test'), 'nosoi', [])}
	);
	eval {
		$obj->for_key_exists_and_return( bless( {}, 'Test' ), 'nosoi', \1 );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_key_exists_and_return(bless({}, 'Test'), 'nosoi', \1)}
	);
};
subtest 'grep' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'grep' );
	eval { $obj->grep( [], 'aporia', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep([], 'aporia', 'phobos')}
	);
	eval { $obj->grep( 'curae', 'aporia', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep('curae', 'aporia', 'phobos')}
	);
	eval { $obj->grep( bless( {}, 'Test' ), [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep(bless({}, 'Test'), [], 'phobos')}
	);
	eval { $obj->grep( bless( {}, 'Test' ), \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep(bless({}, 'Test'), \1, 'phobos')}
	);
};
subtest 'grep_map' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'grep_map' );
	eval { $obj->grep_map( [], 'thanatos', 'thanatos', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep_map([], 'thanatos', 'thanatos', 'curae')}
	);
	eval { $obj->grep_map( 'curae', 'thanatos', 'thanatos', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep_map('curae', 'thanatos', 'thanatos', 'curae')}
	);
	eval { $obj->grep_map( bless( {}, 'Test' ), [], 'thanatos', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep_map(bless({}, 'Test'), [], 'thanatos', 'curae')}
	);
	eval { $obj->grep_map( bless( {}, 'Test' ), \1, 'thanatos', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep_map(bless({}, 'Test'), \1, 'thanatos', 'curae')}
	);
	eval { $obj->grep_map( bless( {}, 'Test' ), 'thanatos', [], 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep_map(bless({}, 'Test'), 'thanatos', [], 'curae')}
	);
	eval { $obj->grep_map( bless( {}, 'Test' ), 'thanatos', \1, 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep_map(bless({}, 'Test'), 'thanatos', \1, 'curae')}
	);
};
subtest 'if' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'if' );
	eval { $obj->if( [], 'penthos', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->if([], 'penthos', 'phobos')}
	);
	eval { $obj->if( 'gaudia', 'penthos', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->if('gaudia', 'penthos', 'phobos')}
	);
	eval { $obj->if( bless( {}, 'Test' ), [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->if(bless({}, 'Test'), [], 'phobos')}
	);
	eval { $obj->if( bless( {}, 'Test' ), \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->if(bless({}, 'Test'), \1, 'phobos')}
	);
};
subtest 'map' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'map' );
	eval { $obj->map( [], 'hypnos', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map([], 'hypnos', 'limos')}
	);
	eval { $obj->map( 'nosoi', 'hypnos', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map('nosoi', 'hypnos', 'limos')}
	);
	eval { $obj->map( bless( {}, 'Test' ), [], 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map(bless({}, 'Test'), [], 'limos')}
	);
	eval { $obj->map( bless( {}, 'Test' ), \1, 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map(bless({}, 'Test'), \1, 'limos')}
	);
};
subtest 'map_grep' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'map_grep' );
	eval { $obj->map_grep( [], 'hypnos', 'gaudia', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map_grep([], 'hypnos', 'gaudia', 'geras')}
	);
	eval { $obj->map_grep( 'aporia', 'hypnos', 'gaudia', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map_grep('aporia', 'hypnos', 'gaudia', 'geras')}
	);
	eval { $obj->map_grep( bless( {}, 'Test' ), [], 'gaudia', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map_grep(bless({}, 'Test'), [], 'gaudia', 'geras')}
	);
	eval { $obj->map_grep( bless( {}, 'Test' ), \1, 'gaudia', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map_grep(bless({}, 'Test'), \1, 'gaudia', 'geras')}
	);
	eval { $obj->map_grep( bless( {}, 'Test' ), 'hypnos', [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map_grep(bless({}, 'Test'), 'hypnos', [], 'geras')}
	);
	eval { $obj->map_grep( bless( {}, 'Test' ), 'hypnos', \1, 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map_grep(bless({}, 'Test'), 'hypnos', \1, 'geras')}
	);
};
subtest 'maybe' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'maybe' );
	eval { $obj->maybe( [], 'penthos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->maybe([], 'penthos', 'nosoi')}
	);
	eval { $obj->maybe( 'limos', 'penthos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->maybe('limos', 'penthos', 'nosoi')}
	);
	eval { $obj->maybe( bless( {}, 'Test' ), [], 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->maybe(bless({}, 'Test'), [], 'nosoi')}
	);
	eval { $obj->maybe( bless( {}, 'Test' ), \1, 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->maybe(bless({}, 'Test'), \1, 'nosoi')}
	);
	eval { $obj->maybe( bless( {}, 'Test' ), 'penthos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->maybe(bless({}, 'Test'), 'penthos', [])}
	);
	eval { $obj->maybe( bless( {}, 'Test' ), 'penthos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->maybe(bless({}, 'Test'), 'penthos', \1)}
	);
};
subtest 'merge_hash_refs' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'merge_hash_refs' );
	eval { $obj->merge_hash_refs( [], 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->merge_hash_refs([], 'curae')}
	);
	eval { $obj->merge_hash_refs( 'gaudia', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->merge_hash_refs('gaudia', 'curae')}
	);
};
subtest 'require' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'require' );
	eval { $obj->require( [], 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->require([], 'hypnos')}
	);
	eval { $obj->require( 'nosoi', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->require('nosoi', 'hypnos')}
	);
	eval { $obj->require( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->require(bless({}, 'Test'), [])}
	);
	eval { $obj->require( bless( {}, 'Test' ), \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->require(bless({}, 'Test'), \1)}
	);
};
subtest 'unless' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'unless' );
	eval { $obj->unless( [], 'algea', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unless([], 'algea', 'nosoi')}
	);
	eval { $obj->unless( 'gaudia', 'algea', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unless('gaudia', 'algea', 'nosoi')}
	);
	eval { $obj->unless( bless( {}, 'Test' ), [], 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unless(bless({}, 'Test'), [], 'nosoi')}
	);
	eval { $obj->unless( bless( {}, 'Test' ), \1, 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unless(bless({}, 'Test'), \1, 'nosoi')}
	);
};
subtest 'while' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'while' );
	eval { $obj->while( [], 'aporia', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->while([], 'aporia', 'phobos')}
	);
	eval { $obj->while( 'thanatos', 'aporia', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->while('thanatos', 'aporia', 'phobos')}
	);
	eval { $obj->while( bless( {}, 'Test' ), [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->while(bless({}, 'Test'), [], 'phobos')}
	);
	eval { $obj->while( bless( {}, 'Test' ), \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->while(bless({}, 'Test'), \1, 'phobos')}
	);
};
done_testing();
