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
		qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Macro::Dolos->new({ macro => {} })}
	);
	eval { $obj = Hades::Macro::Dolos->new( { macro => 'nosoi' } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Macro::Dolos->new({ macro => 'nosoi' })}
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
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->macro({})} );
	eval { $obj->macro('phobos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->macro('phobos')} );
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->autoload_cb([], 'curae')}
	);
	eval { $obj->autoload_cb( 'aporia', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->autoload_cb('aporia', 'curae')}
	);
	eval { $obj->autoload_cb( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->autoload_cb(bless({}, 'Test'), [])}
	);
	eval { $obj->autoload_cb( bless( {}, 'Test' ), \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->caller([], 'penthos')}
	);
	eval { $obj->caller( 'phobos', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->caller('phobos', 'penthos')}
	);
	eval { $obj->caller( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->caller(bless({}, 'Test'), [])}
	);
	eval { $obj->caller( bless( {}, 'Test' ), \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->caller(bless({}, 'Test'), \1)}
	);
};
subtest 'clear_unless_keys' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'clear_unless_keys' );
	eval { $obj->clear_unless_keys( [], 'algea', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->clear_unless_keys([], 'algea', 'geras')}
	);
	eval { $obj->clear_unless_keys( 'limos', 'algea', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->clear_unless_keys('limos', 'algea', 'geras')}
	);
	eval { $obj->clear_unless_keys( bless( {}, 'Test' ), [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->clear_unless_keys(bless({}, 'Test'), [], 'geras')}
	);
	eval { $obj->clear_unless_keys( bless( {}, 'Test' ), \1, 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->clear_unless_keys(bless({}, 'Test'), \1, 'geras')}
	);
	eval { $obj->clear_unless_keys( bless( {}, 'Test' ), 'algea', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->clear_unless_keys(bless({}, 'Test'), 'algea', [])}
	);
	eval { $obj->clear_unless_keys( bless( {}, 'Test' ), 'algea', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->clear_unless_keys(bless({}, 'Test'), 'algea', \1)}
	);
};
subtest 'call_sub' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'call_sub' );
	eval { $obj->call_sub( [], 'limos', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->call_sub([], 'limos', 'penthos')}
	);
	eval { $obj->call_sub( 'nosoi', 'limos', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->call_sub('nosoi', 'limos', 'penthos')}
	);
};
subtest 'call_sub_my' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'call_sub_my' );
	eval { $obj->call_sub_my( [], 'curae', 'phobos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->call_sub_my([], 'curae', 'phobos', 'aporia')}
	);
	eval { $obj->call_sub_my( 'geras', 'curae', 'phobos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->call_sub_my('geras', 'curae', 'phobos', 'aporia')}
	);
	eval { $obj->call_sub_my( bless( {}, 'Test' ), [], 'phobos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->call_sub_my(bless({}, 'Test'), [], 'phobos', 'aporia')}
	);
	eval { $obj->call_sub_my( bless( {}, 'Test' ), \1, 'phobos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->call_sub_my(bless({}, 'Test'), \1, 'phobos', 'aporia')}
	);
};
subtest 'delete' => sub {
	plan tests => 14;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'delete' );
	eval { $obj->delete( [], 'penthos', 'aporia', undef, undef, undef ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->delete([], 'penthos', 'aporia', undef, undef, undef)}
	);
	eval {
		$obj->delete( 'phobos', 'penthos', 'aporia', undef, undef, undef );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->delete('phobos', 'penthos', 'aporia', undef, undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ), [], 'aporia', undef, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->delete(bless({}, 'Test'), [], 'aporia', undef, undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ), \1, 'aporia', undef, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->delete(bless({}, 'Test'), \1, 'aporia', undef, undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'penthos', [], undef, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->delete(bless({}, 'Test'), 'penthos', [], undef, undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'penthos', \1, undef, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->delete(bless({}, 'Test'), 'penthos', \1, undef, undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'penthos', 'aporia', [], undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->delete(bless({}, 'Test'), 'penthos', 'aporia', [], undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'penthos', 'aporia', \1, undef, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->delete(bless({}, 'Test'), 'penthos', 'aporia', \1, undef, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'penthos', 'aporia', undef, [], undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->delete(bless({}, 'Test'), 'penthos', 'aporia', undef, [], undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'penthos', 'aporia', undef, \1, undef );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->delete(bless({}, 'Test'), 'penthos', 'aporia', undef, \1, undef)}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'penthos', 'aporia', undef, undef, [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->delete(bless({}, 'Test'), 'penthos', 'aporia', undef, undef, [])}
	);
	eval {
		$obj->delete( bless( {}, 'Test' ),
			'penthos', 'aporia', undef, undef, {} );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->delete(bless({}, 'Test'), 'penthos', 'aporia', undef, undef, {})}
	);
};
subtest 'die_unless_keys' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'die_unless_keys' );
	eval { $obj->die_unless_keys( [], 'thanatos', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->die_unless_keys([], 'thanatos', 'hypnos')}
	);
	eval { $obj->die_unless_keys( 'limos', 'thanatos', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->die_unless_keys('limos', 'thanatos', 'hypnos')}
	);
	eval { $obj->die_unless_keys( bless( {}, 'Test' ), [], 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->die_unless_keys(bless({}, 'Test'), [], 'hypnos')}
	);
	eval { $obj->die_unless_keys( bless( {}, 'Test' ), \1, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->die_unless_keys(bless({}, 'Test'), \1, 'hypnos')}
	);
	eval { $obj->die_unless_keys( bless( {}, 'Test' ), 'thanatos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->die_unless_keys(bless({}, 'Test'), 'thanatos', [])}
	);
	eval { $obj->die_unless_keys( bless( {}, 'Test' ), 'thanatos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->die_unless_keys(bless({}, 'Test'), 'thanatos', \1)}
	);
};
subtest 'else' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'else' );
	eval { $obj->else( [], 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->else([], 'algea')}
	);
	eval { $obj->else( 'phobos', 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->else('phobos', 'algea')}
	);
};
subtest 'elsif' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'elsif' );
	eval { $obj->elsif( [], 'phobos', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->elsif([], 'phobos', 'phobos')}
	);
	eval { $obj->elsif( 'gaudia', 'phobos', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->elsif('gaudia', 'phobos', 'phobos')}
	);
	eval { $obj->elsif( bless( {}, 'Test' ), [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->elsif(bless({}, 'Test'), [], 'phobos')}
	);
	eval { $obj->elsif( bless( {}, 'Test' ), \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->elsif(bless({}, 'Test'), \1, 'phobos')}
	);
};
subtest 'export' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'export' );
	eval { $obj->export( [], 'gaudia', 'nosoi', 10, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->export([], 'gaudia', 'nosoi', 10, 'hypnos')}
	);
	eval { $obj->export( 'geras', 'gaudia', 'nosoi', 10, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->export('geras', 'gaudia', 'nosoi', 10, 'hypnos')}
	);
	eval { $obj->export( bless( {}, 'Test' ), [], 'nosoi', 10, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->export(bless({}, 'Test'), [], 'nosoi', 10, 'hypnos')}
	);
	eval { $obj->export( bless( {}, 'Test' ), \1, 'nosoi', 10, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->export(bless({}, 'Test'), \1, 'nosoi', 10, 'hypnos')}
	);
	eval { $obj->export( bless( {}, 'Test' ), 'gaudia', [], 10, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->export(bless({}, 'Test'), 'gaudia', [], 10, 'hypnos')}
	);
	eval { $obj->export( bless( {}, 'Test' ), 'gaudia', \1, 10, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->export(bless({}, 'Test'), 'gaudia', \1, 10, 'hypnos')}
	);
	eval {
		$obj->export( bless( {}, 'Test' ), 'gaudia', 'nosoi', [], 'hypnos' );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->export(bless({}, 'Test'), 'gaudia', 'nosoi', [], 'hypnos')}
	);
	eval {
		$obj->export( bless( {}, 'Test' ),
			'gaudia', 'nosoi', 'curae', 'hypnos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->export(bless({}, 'Test'), 'gaudia', 'nosoi', 'curae', 'hypnos')}
	);
	eval { $obj->export( bless( {}, 'Test' ), 'gaudia', 'nosoi', 10, [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->export(bless({}, 'Test'), 'gaudia', 'nosoi', 10, [])}
	);
	eval { $obj->export( bless( {}, 'Test' ), 'gaudia', 'nosoi', 10, \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->export(bless({}, 'Test'), 'gaudia', 'nosoi', 10, \1)}
	);
};
subtest 'for' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'for' );
	eval { $obj->for( [], 'aporia', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for([], 'aporia', 'curae')}
	);
	eval { $obj->for( 'algea', 'aporia', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for('algea', 'aporia', 'curae')}
	);
	eval { $obj->for( bless( {}, 'Test' ), [], 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for(bless({}, 'Test'), [], 'curae')}
	);
	eval { $obj->for( bless( {}, 'Test' ), \1, 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for(bless({}, 'Test'), \1, 'curae')}
	);
};
subtest 'foreach' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'foreach' );
	eval { $obj->foreach( [], 'aporia', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->foreach([], 'aporia', 'geras')}
	);
	eval { $obj->foreach( 'penthos', 'aporia', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->foreach('penthos', 'aporia', 'geras')}
	);
	eval { $obj->foreach( bless( {}, 'Test' ), [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->foreach(bless({}, 'Test'), [], 'geras')}
	);
	eval { $obj->foreach( bless( {}, 'Test' ), \1, 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->foreach(bless({}, 'Test'), \1, 'geras')}
	);
};
subtest 'for_keys' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'for_keys' );
	eval { $obj->for_keys( [], 'hypnos', 'limos', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for_keys([], 'hypnos', 'limos', 'thanatos')}
	);
	eval { $obj->for_keys( 'algea', 'hypnos', 'limos', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for_keys('algea', 'hypnos', 'limos', 'thanatos')}
	);
	eval { $obj->for_keys( bless( {}, 'Test' ), [], 'limos', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for_keys(bless({}, 'Test'), [], 'limos', 'thanatos')}
	);
	eval { $obj->for_keys( bless( {}, 'Test' ), \1, 'limos', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for_keys(bless({}, 'Test'), \1, 'limos', 'thanatos')}
	);
	eval { $obj->for_keys( bless( {}, 'Test' ), 'hypnos', [], 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for_keys(bless({}, 'Test'), 'hypnos', [], 'thanatos')}
	);
	eval { $obj->for_keys( bless( {}, 'Test' ), 'hypnos', \1, 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for_keys(bless({}, 'Test'), 'hypnos', \1, 'thanatos')}
	);
};
subtest 'for_key_exists_and_return' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'for_key_exists_and_return' );
	eval { $obj->for_key_exists_and_return( [], 'aporia', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for_key_exists_and_return([], 'aporia', 'hypnos')}
	);
	eval { $obj->for_key_exists_and_return( 'gaudia', 'aporia', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for_key_exists_and_return('gaudia', 'aporia', 'hypnos')}
	);
	eval {
		$obj->for_key_exists_and_return( bless( {}, 'Test' ), [], 'hypnos' );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for_key_exists_and_return(bless({}, 'Test'), [], 'hypnos')}
	);
	eval {
		$obj->for_key_exists_and_return( bless( {}, 'Test' ), \1, 'hypnos' );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for_key_exists_and_return(bless({}, 'Test'), \1, 'hypnos')}
	);
	eval {
		$obj->for_key_exists_and_return( bless( {}, 'Test' ), 'aporia', [] );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for_key_exists_and_return(bless({}, 'Test'), 'aporia', [])}
	);
	eval {
		$obj->for_key_exists_and_return( bless( {}, 'Test' ), 'aporia', \1 );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->for_key_exists_and_return(bless({}, 'Test'), 'aporia', \1)}
	);
};
subtest 'grep' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'grep' );
	eval { $obj->grep( [], 'limos', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->grep([], 'limos', 'phobos')}
	);
	eval { $obj->grep( 'limos', 'limos', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->grep('limos', 'limos', 'phobos')}
	);
	eval { $obj->grep( bless( {}, 'Test' ), [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->grep(bless({}, 'Test'), [], 'phobos')}
	);
	eval { $obj->grep( bless( {}, 'Test' ), \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->grep(bless({}, 'Test'), \1, 'phobos')}
	);
};
subtest 'grep_map' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'grep_map' );
	eval { $obj->grep_map( [], 'phobos', 'gaudia', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->grep_map([], 'phobos', 'gaudia', 'nosoi')}
	);
	eval { $obj->grep_map( 'nosoi', 'phobos', 'gaudia', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->grep_map('nosoi', 'phobos', 'gaudia', 'nosoi')}
	);
	eval { $obj->grep_map( bless( {}, 'Test' ), [], 'gaudia', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->grep_map(bless({}, 'Test'), [], 'gaudia', 'nosoi')}
	);
	eval { $obj->grep_map( bless( {}, 'Test' ), \1, 'gaudia', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->grep_map(bless({}, 'Test'), \1, 'gaudia', 'nosoi')}
	);
	eval { $obj->grep_map( bless( {}, 'Test' ), 'phobos', [], 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->grep_map(bless({}, 'Test'), 'phobos', [], 'nosoi')}
	);
	eval { $obj->grep_map( bless( {}, 'Test' ), 'phobos', \1, 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->grep_map(bless({}, 'Test'), 'phobos', \1, 'nosoi')}
	);
};
subtest 'if' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'if' );
	eval { $obj->if( [], 'nosoi', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->if([], 'nosoi', 'phobos')}
	);
	eval { $obj->if( 'curae', 'nosoi', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->if('curae', 'nosoi', 'phobos')}
	);
	eval { $obj->if( bless( {}, 'Test' ), [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->if(bless({}, 'Test'), [], 'phobos')}
	);
	eval { $obj->if( bless( {}, 'Test' ), \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->if(bless({}, 'Test'), \1, 'phobos')}
	);
};
subtest 'map' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'map' );
	eval { $obj->map( [], 'limos', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->map([], 'limos', 'hypnos')}
	);
	eval { $obj->map( 'curae', 'limos', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->map('curae', 'limos', 'hypnos')}
	);
	eval { $obj->map( bless( {}, 'Test' ), [], 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->map(bless({}, 'Test'), [], 'hypnos')}
	);
	eval { $obj->map( bless( {}, 'Test' ), \1, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->map(bless({}, 'Test'), \1, 'hypnos')}
	);
};
subtest 'map_grep' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'map_grep' );
	eval { $obj->map_grep( [], 'curae', 'nosoi', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->map_grep([], 'curae', 'nosoi', 'geras')}
	);
	eval { $obj->map_grep( 'hypnos', 'curae', 'nosoi', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->map_grep('hypnos', 'curae', 'nosoi', 'geras')}
	);
	eval { $obj->map_grep( bless( {}, 'Test' ), [], 'nosoi', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->map_grep(bless({}, 'Test'), [], 'nosoi', 'geras')}
	);
	eval { $obj->map_grep( bless( {}, 'Test' ), \1, 'nosoi', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->map_grep(bless({}, 'Test'), \1, 'nosoi', 'geras')}
	);
	eval { $obj->map_grep( bless( {}, 'Test' ), 'curae', [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->map_grep(bless({}, 'Test'), 'curae', [], 'geras')}
	);
	eval { $obj->map_grep( bless( {}, 'Test' ), 'curae', \1, 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->map_grep(bless({}, 'Test'), 'curae', \1, 'geras')}
	);
};
subtest 'maybe' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'maybe' );
	eval { $obj->maybe( [], 'nosoi', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->maybe([], 'nosoi', 'phobos')}
	);
	eval { $obj->maybe( 'curae', 'nosoi', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->maybe('curae', 'nosoi', 'phobos')}
	);
	eval { $obj->maybe( bless( {}, 'Test' ), [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->maybe(bless({}, 'Test'), [], 'phobos')}
	);
	eval { $obj->maybe( bless( {}, 'Test' ), \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->maybe(bless({}, 'Test'), \1, 'phobos')}
	);
	eval { $obj->maybe( bless( {}, 'Test' ), 'nosoi', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->maybe(bless({}, 'Test'), 'nosoi', [])}
	);
	eval { $obj->maybe( bless( {}, 'Test' ), 'nosoi', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->maybe(bless({}, 'Test'), 'nosoi', \1)}
	);
};
subtest 'merge_hash_refs' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'merge_hash_refs' );
	eval { $obj->merge_hash_refs( [], 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->merge_hash_refs([], 'gaudia')}
	);
	eval { $obj->merge_hash_refs( 'thanatos', 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->merge_hash_refs('thanatos', 'gaudia')}
	);
};
subtest 'require' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'require' );
	eval { $obj->require( [], 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->require([], 'algea')}
	);
	eval { $obj->require( 'geras', 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->require('geras', 'algea')}
	);
	eval { $obj->require( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->require(bless({}, 'Test'), [])}
	);
	eval { $obj->require( bless( {}, 'Test' ), \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->require(bless({}, 'Test'), \1)}
	);
};
subtest 'unless' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'unless' );
	eval { $obj->unless( [], 'thanatos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->unless([], 'thanatos', 'nosoi')}
	);
	eval { $obj->unless( 'thanatos', 'thanatos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->unless('thanatos', 'thanatos', 'nosoi')}
	);
	eval { $obj->unless( bless( {}, 'Test' ), [], 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->unless(bless({}, 'Test'), [], 'nosoi')}
	);
	eval { $obj->unless( bless( {}, 'Test' ), \1, 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->unless(bless({}, 'Test'), \1, 'nosoi')}
	);
};
subtest 'while' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::Dolos->new( {} ),
		q{my $obj = Hades::Macro::Dolos->new({})}
	);
	can_ok( $obj, 'while' );
	eval { $obj->while( [], 'curae', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->while([], 'curae', 'thanatos')}
	);
	eval { $obj->while( 'curae', 'curae', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->while('curae', 'curae', 'thanatos')}
	);
	eval { $obj->while( bless( {}, 'Test' ), [], 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->while(bless({}, 'Test'), [], 'thanatos')}
	);
	eval { $obj->while( bless( {}, 'Test' ), \1, 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->while(bless({}, 'Test'), \1, 'thanatos')}
	);
};
done_testing();
