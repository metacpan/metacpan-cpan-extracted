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
	eval { $obj = Hades::Macro::Dolos->new( { macro => 'limos' } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro::Dolos->new({ macro => 'limos' })}
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
	eval { $obj->macro('thanatos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->macro('thanatos')} );
	is_deeply( $obj->macro, ['test'], q{$obj->macro} );
};
subtest 'autoload_cb' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'autoload_cb' );
	eval { $obj->autoload_cb( [], 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->autoload_cb([], 'curae')}
	);
	eval { $obj->autoload_cb( 'nosoi', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->autoload_cb('nosoi', 'curae')}
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
	eval { $obj->caller( [], 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->caller([], 'penthos')}
	);
	eval { $obj->caller( 'curae', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->caller('curae', 'penthos')}
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
	eval { $obj->clear_unless_keys( [], 'algea', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->clear_unless_keys([], 'algea', 'penthos')}
	);
	eval { $obj->clear_unless_keys( 'nosoi', 'algea', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->clear_unless_keys('nosoi', 'algea', 'penthos')}
	);
	eval { $obj->clear_unless_keys( bless( {}, 'Test' ), [], 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->clear_unless_keys(bless({}, 'Test'), [], 'penthos')}
	);
	eval { $obj->clear_unless_keys( bless( {}, 'Test' ), \1, 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->clear_unless_keys(bless({}, 'Test'), \1, 'penthos')}
	);
	eval { $obj->clear_unless_keys( bless( {}, 'Test' ), 'algea', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->clear_unless_keys(bless({}, 'Test'), 'algea', [])}
	);
	eval { $obj->clear_unless_keys( bless( {}, 'Test' ), 'algea', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->clear_unless_keys(bless({}, 'Test'), 'algea', \1)}
	);
};
subtest 'call_sub' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'call_sub' );
	eval { $obj->call_sub( [], 'curae', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->call_sub([], 'curae', 'curae')}
	);
	eval { $obj->call_sub( 'algea', 'curae', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->call_sub('algea', 'curae', 'curae')}
	);
};
subtest 'call_sub_my' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'call_sub_my' );
	eval { $obj->call_sub_my( [], 'limos', 'geras', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->call_sub_my([], 'limos', 'geras', 'aporia')}
	);
	eval { $obj->call_sub_my( 'hypnos', 'limos', 'geras', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->call_sub_my('hypnos', 'limos', 'geras', 'aporia')}
	);
	eval { $obj->call_sub_my( bless( {}, 'Test' ), [], 'geras', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->call_sub_my(bless({}, 'Test'), [], 'geras', 'aporia')}
	);
	eval { $obj->call_sub_my( bless( {}, 'Test' ), \1, 'geras', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->call_sub_my(bless({}, 'Test'), \1, 'geras', 'aporia')}
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
		$obj->delete( 'penthos', 'thanatos', 'gaudia', undef, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->delete('penthos', 'thanatos', 'gaudia', undef, undef, undef)}
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
	eval { $obj->die_unless_keys( [], 'aporia', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->die_unless_keys([], 'aporia', 'thanatos')}
	);
	eval { $obj->die_unless_keys( 'gaudia', 'aporia', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->die_unless_keys('gaudia', 'aporia', 'thanatos')}
	);
	eval { $obj->die_unless_keys( bless( {}, 'Test' ), [], 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->die_unless_keys(bless({}, 'Test'), [], 'thanatos')}
	);
	eval { $obj->die_unless_keys( bless( {}, 'Test' ), \1, 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->die_unless_keys(bless({}, 'Test'), \1, 'thanatos')}
	);
	eval { $obj->die_unless_keys( bless( {}, 'Test' ), 'aporia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->die_unless_keys(bless({}, 'Test'), 'aporia', [])}
	);
	eval { $obj->die_unless_keys( bless( {}, 'Test' ), 'aporia', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->die_unless_keys(bless({}, 'Test'), 'aporia', \1)}
	);
};
subtest 'else' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'else' );
	eval { $obj->else( [], 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->else([], 'aporia')}
	);
	eval { $obj->else( 'curae', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->else('curae', 'aporia')}
	);
};
subtest 'elsif' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'elsif' );
	eval { $obj->elsif( [], 'limos', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->elsif([], 'limos', 'curae')}
	);
	eval { $obj->elsif( 'thanatos', 'limos', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->elsif('thanatos', 'limos', 'curae')}
	);
	eval { $obj->elsif( bless( {}, 'Test' ), [], 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->elsif(bless({}, 'Test'), [], 'curae')}
	);
	eval { $obj->elsif( bless( {}, 'Test' ), \1, 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->elsif(bless({}, 'Test'), \1, 'curae')}
	);
};
subtest 'export' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'export' );
	eval { $obj->export( [], 'geras', 'hypnos', 10, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export([], 'geras', 'hypnos', 10, 'phobos')}
	);
	eval { $obj->export( 'curae', 'geras', 'hypnos', 10, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export('curae', 'geras', 'hypnos', 10, 'phobos')}
	);
	eval { $obj->export( bless( {}, 'Test' ), [], 'hypnos', 10, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), [], 'hypnos', 10, 'phobos')}
	);
	eval { $obj->export( bless( {}, 'Test' ), \1, 'hypnos', 10, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), \1, 'hypnos', 10, 'phobos')}
	);
	eval { $obj->export( bless( {}, 'Test' ), 'geras', [], 10, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), 'geras', [], 10, 'phobos')}
	);
	eval { $obj->export( bless( {}, 'Test' ), 'geras', \1, 10, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), 'geras', \1, 10, 'phobos')}
	);
	eval {
		$obj->export( bless( {}, 'Test' ), 'geras', 'hypnos', [], 'phobos' );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), 'geras', 'hypnos', [], 'phobos')}
	);
	eval {
		$obj->export( bless( {}, 'Test' ),
			'geras', 'hypnos', 'thanatos', 'phobos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), 'geras', 'hypnos', 'thanatos', 'phobos')}
	);
	eval { $obj->export( bless( {}, 'Test' ), 'geras', 'hypnos', 10, [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), 'geras', 'hypnos', 10, [])}
	);
	eval { $obj->export( bless( {}, 'Test' ), 'geras', 'hypnos', 10, \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->export(bless({}, 'Test'), 'geras', 'hypnos', 10, \1)}
	);
};
subtest 'for' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'for' );
	eval { $obj->for( [], 'thanatos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for([], 'thanatos', 'nosoi')}
	);
	eval { $obj->for( 'geras', 'thanatos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for('geras', 'thanatos', 'nosoi')}
	);
	eval { $obj->for( bless( {}, 'Test' ), [], 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for(bless({}, 'Test'), [], 'nosoi')}
	);
	eval { $obj->for( bless( {}, 'Test' ), \1, 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for(bless({}, 'Test'), \1, 'nosoi')}
	);
};
subtest 'foreach' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'foreach' );
	eval { $obj->foreach( [], 'geras', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->foreach([], 'geras', 'nosoi')}
	);
	eval { $obj->foreach( 'algea', 'geras', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->foreach('algea', 'geras', 'nosoi')}
	);
	eval { $obj->foreach( bless( {}, 'Test' ), [], 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->foreach(bless({}, 'Test'), [], 'nosoi')}
	);
	eval { $obj->foreach( bless( {}, 'Test' ), \1, 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->foreach(bless({}, 'Test'), \1, 'nosoi')}
	);
};
subtest 'for_keys' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'for_keys' );
	eval { $obj->for_keys( [], 'phobos', 'algea', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_keys([], 'phobos', 'algea', 'limos')}
	);
	eval { $obj->for_keys( 'limos', 'phobos', 'algea', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_keys('limos', 'phobos', 'algea', 'limos')}
	);
	eval { $obj->for_keys( bless( {}, 'Test' ), [], 'algea', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_keys(bless({}, 'Test'), [], 'algea', 'limos')}
	);
	eval { $obj->for_keys( bless( {}, 'Test' ), \1, 'algea', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_keys(bless({}, 'Test'), \1, 'algea', 'limos')}
	);
	eval { $obj->for_keys( bless( {}, 'Test' ), 'phobos', [], 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_keys(bless({}, 'Test'), 'phobos', [], 'limos')}
	);
	eval { $obj->for_keys( bless( {}, 'Test' ), 'phobos', \1, 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_keys(bless({}, 'Test'), 'phobos', \1, 'limos')}
	);
};
subtest 'for_key_exists_and_return' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'for_key_exists_and_return' );
	eval { $obj->for_key_exists_and_return( [], 'penthos', 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_key_exists_and_return([], 'penthos', 'algea')}
	);
	eval { $obj->for_key_exists_and_return( 'aporia', 'penthos', 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_key_exists_and_return('aporia', 'penthos', 'algea')}
	);
	eval {
		$obj->for_key_exists_and_return( bless( {}, 'Test' ), [], 'algea' );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_key_exists_and_return(bless({}, 'Test'), [], 'algea')}
	);
	eval {
		$obj->for_key_exists_and_return( bless( {}, 'Test' ), \1, 'algea' );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_key_exists_and_return(bless({}, 'Test'), \1, 'algea')}
	);
	eval {
		$obj->for_key_exists_and_return( bless( {}, 'Test' ), 'penthos', [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_key_exists_and_return(bless({}, 'Test'), 'penthos', [])}
	);
	eval {
		$obj->for_key_exists_and_return( bless( {}, 'Test' ), 'penthos', \1 );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->for_key_exists_and_return(bless({}, 'Test'), 'penthos', \1)}
	);
};
subtest 'grep' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'grep' );
	eval { $obj->grep( [], 'limos', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep([], 'limos', 'geras')}
	);
	eval { $obj->grep( 'penthos', 'limos', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep('penthos', 'limos', 'geras')}
	);
	eval { $obj->grep( bless( {}, 'Test' ), [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep(bless({}, 'Test'), [], 'geras')}
	);
	eval { $obj->grep( bless( {}, 'Test' ), \1, 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep(bless({}, 'Test'), \1, 'geras')}
	);
};
subtest 'grep_map' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'grep_map' );
	eval { $obj->grep_map( [], 'geras', 'thanatos', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep_map([], 'geras', 'thanatos', 'hypnos')}
	);
	eval { $obj->grep_map( 'limos', 'geras', 'thanatos', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep_map('limos', 'geras', 'thanatos', 'hypnos')}
	);
	eval { $obj->grep_map( bless( {}, 'Test' ), [], 'thanatos', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep_map(bless({}, 'Test'), [], 'thanatos', 'hypnos')}
	);
	eval { $obj->grep_map( bless( {}, 'Test' ), \1, 'thanatos', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep_map(bless({}, 'Test'), \1, 'thanatos', 'hypnos')}
	);
	eval { $obj->grep_map( bless( {}, 'Test' ), 'geras', [], 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep_map(bless({}, 'Test'), 'geras', [], 'hypnos')}
	);
	eval { $obj->grep_map( bless( {}, 'Test' ), 'geras', \1, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->grep_map(bless({}, 'Test'), 'geras', \1, 'hypnos')}
	);
};
subtest 'if' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'if' );
	eval { $obj->if( [], 'gaudia', 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->if([], 'gaudia', 'gaudia')}
	);
	eval { $obj->if( 'nosoi', 'gaudia', 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->if('nosoi', 'gaudia', 'gaudia')}
	);
	eval { $obj->if( bless( {}, 'Test' ), [], 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->if(bless({}, 'Test'), [], 'gaudia')}
	);
	eval { $obj->if( bless( {}, 'Test' ), \1, 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->if(bless({}, 'Test'), \1, 'gaudia')}
	);
};
subtest 'map' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'map' );
	eval { $obj->map( [], 'phobos', 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map([], 'phobos', 'algea')}
	);
	eval { $obj->map( 'limos', 'phobos', 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map('limos', 'phobos', 'algea')}
	);
	eval { $obj->map( bless( {}, 'Test' ), [], 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map(bless({}, 'Test'), [], 'algea')}
	);
	eval { $obj->map( bless( {}, 'Test' ), \1, 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map(bless({}, 'Test'), \1, 'algea')}
	);
};
subtest 'map_grep' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'map_grep' );
	eval { $obj->map_grep( [], 'curae', 'nosoi', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map_grep([], 'curae', 'nosoi', 'phobos')}
	);
	eval { $obj->map_grep( 'limos', 'curae', 'nosoi', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map_grep('limos', 'curae', 'nosoi', 'phobos')}
	);
	eval { $obj->map_grep( bless( {}, 'Test' ), [], 'nosoi', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map_grep(bless({}, 'Test'), [], 'nosoi', 'phobos')}
	);
	eval { $obj->map_grep( bless( {}, 'Test' ), \1, 'nosoi', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map_grep(bless({}, 'Test'), \1, 'nosoi', 'phobos')}
	);
	eval { $obj->map_grep( bless( {}, 'Test' ), 'curae', [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map_grep(bless({}, 'Test'), 'curae', [], 'phobos')}
	);
	eval { $obj->map_grep( bless( {}, 'Test' ), 'curae', \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->map_grep(bless({}, 'Test'), 'curae', \1, 'phobos')}
	);
};
subtest 'maybe' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'maybe' );
	eval { $obj->maybe( [], 'limos', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->maybe([], 'limos', 'phobos')}
	);
	eval { $obj->maybe( 'phobos', 'limos', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->maybe('phobos', 'limos', 'phobos')}
	);
	eval { $obj->maybe( bless( {}, 'Test' ), [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->maybe(bless({}, 'Test'), [], 'phobos')}
	);
	eval { $obj->maybe( bless( {}, 'Test' ), \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->maybe(bless({}, 'Test'), \1, 'phobos')}
	);
	eval { $obj->maybe( bless( {}, 'Test' ), 'limos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->maybe(bless({}, 'Test'), 'limos', [])}
	);
	eval { $obj->maybe( bless( {}, 'Test' ), 'limos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->maybe(bless({}, 'Test'), 'limos', \1)}
	);
};
subtest 'merge_hash_refs' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'merge_hash_refs' );
	eval { $obj->merge_hash_refs( [], 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->merge_hash_refs([], 'limos')}
	);
	eval { $obj->merge_hash_refs( 'phobos', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->merge_hash_refs('phobos', 'limos')}
	);
};
subtest 'require' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'require' );
	eval { $obj->require( [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->require([], 'geras')}
	);
	eval { $obj->require( 'geras', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->require('geras', 'geras')}
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
	eval { $obj->unless( [], 'algea', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unless([], 'algea', 'thanatos')}
	);
	eval { $obj->unless( 'curae', 'algea', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unless('curae', 'algea', 'thanatos')}
	);
	eval { $obj->unless( bless( {}, 'Test' ), [], 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unless(bless({}, 'Test'), [], 'thanatos')}
	);
	eval { $obj->unless( bless( {}, 'Test' ), \1, 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unless(bless({}, 'Test'), \1, 'thanatos')}
	);
};
subtest 'while' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'while' );
	eval { $obj->while( [], 'algea', 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->while([], 'algea', 'algea')}
	);
	eval { $obj->while( 'limos', 'algea', 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->while('limos', 'algea', 'algea')}
	);
	eval { $obj->while( bless( {}, 'Test' ), [], 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->while(bless({}, 'Test'), [], 'algea')}
	);
	eval { $obj->while( bless( {}, 'Test' ), \1, 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->while(bless({}, 'Test'), \1, 'algea')}
	);
};
done_testing();
