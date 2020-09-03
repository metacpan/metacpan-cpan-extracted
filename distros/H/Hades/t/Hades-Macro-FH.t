use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Hades::Macro::FH');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 9;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	ok( $obj = Hades::Macro::FH->new(), q{$obj = Hades::Macro::FH->new()} );
	isa_ok( $obj, 'Hades::Macro::FH' );
	ok( $obj = Hades::Macro::FH->new( {} ),
		q{$obj = Hades::Macro::FH->new({})}
	);
	ok( $obj = Hades::Macro::FH->new(), q{$obj = Hades::Macro::FH->new()} );
	is_deeply( $obj->macro,
		[qw/open_write open_read close_file read_file write_file/],
		q{$obj->macro} );
	ok( $obj = Hades::Macro::FH->new( { macro => ['test'] } ),
		q{$obj = Hades::Macro::FH->new({ macro => ['test'] })}
	);
	eval { $obj = Hades::Macro::FH->new( { macro => {} } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro::FH->new({ macro => {} })}
	);
	eval { $obj = Hades::Macro::FH->new( { macro => 'aporia' } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro::FH->new({ macro => 'aporia' })}
	);
};
subtest 'macro' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
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
subtest 'open_write' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'open_write' );
	eval { $obj->open_write( [], 'phobos', 'limos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write([], 'phobos', 'limos', 'aporia')}
	);
	eval { $obj->open_write( 'penthos', 'phobos', 'limos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write('penthos', 'phobos', 'limos', 'aporia')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), [], 'limos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write(bless({}, 'Test'), [], 'limos', 'aporia')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), \1, 'limos', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write(bless({}, 'Test'), \1, 'limos', 'aporia')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), 'phobos', [], 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write(bless({}, 'Test'), 'phobos', [], 'aporia')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), 'phobos', \1, 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write(bless({}, 'Test'), 'phobos', \1, 'aporia')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), 'phobos', 'limos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write(bless({}, 'Test'), 'phobos', 'limos', [])}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), 'phobos', 'limos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write(bless({}, 'Test'), 'phobos', 'limos', \1)}
	);
};
subtest 'open_read' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'open_read' );
	eval { $obj->open_read( [], 'geras', 'phobos', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read([], 'geras', 'phobos', 'penthos')}
	);
	eval { $obj->open_read( 'algea', 'geras', 'phobos', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read('algea', 'geras', 'phobos', 'penthos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), [], 'phobos', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read(bless({}, 'Test'), [], 'phobos', 'penthos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), \1, 'phobos', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read(bless({}, 'Test'), \1, 'phobos', 'penthos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), 'geras', [], 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read(bless({}, 'Test'), 'geras', [], 'penthos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), 'geras', \1, 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read(bless({}, 'Test'), 'geras', \1, 'penthos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), 'geras', 'phobos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read(bless({}, 'Test'), 'geras', 'phobos', [])}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), 'geras', 'phobos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read(bless({}, 'Test'), 'geras', 'phobos', \1)}
	);
};
subtest 'close_file' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'close_file' );
	eval { $obj->close_file( [], 'nosoi', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->close_file([], 'nosoi', 'hypnos')}
	);
	eval { $obj->close_file( 'curae', 'nosoi', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->close_file('curae', 'nosoi', 'hypnos')}
	);
	eval { $obj->close_file( bless( {}, 'Test' ), [], 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->close_file(bless({}, 'Test'), [], 'hypnos')}
	);
	eval { $obj->close_file( bless( {}, 'Test' ), \1, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->close_file(bless({}, 'Test'), \1, 'hypnos')}
	);
	eval { $obj->close_file( bless( {}, 'Test' ), 'nosoi', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->close_file(bless({}, 'Test'), 'nosoi', [])}
	);
	eval { $obj->close_file( bless( {}, 'Test' ), 'nosoi', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->close_file(bless({}, 'Test'), 'nosoi', \1)}
	);
};
subtest 'read_file' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'read_file' );
	eval { $obj->read_file( [], 'limos', 'limos', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file([], 'limos', 'limos', 'hypnos')}
	);
	eval { $obj->read_file( 'limos', 'limos', 'limos', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file('limos', 'limos', 'limos', 'hypnos')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), [], 'limos', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file(bless({}, 'Test'), [], 'limos', 'hypnos')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), \1, 'limos', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file(bless({}, 'Test'), \1, 'limos', 'hypnos')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), 'limos', [], 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file(bless({}, 'Test'), 'limos', [], 'hypnos')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), 'limos', \1, 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file(bless({}, 'Test'), 'limos', \1, 'hypnos')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), 'limos', 'limos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file(bless({}, 'Test'), 'limos', 'limos', [])}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), 'limos', 'limos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file(bless({}, 'Test'), 'limos', 'limos', \1)}
	);
};
subtest 'write_file' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'write_file' );
	eval { $obj->write_file( [], 'gaudia', 'aporia', 'phobos', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file([], 'gaudia', 'aporia', 'phobos', 'limos')}
	);
	eval {
		$obj->write_file( 'nosoi', 'gaudia', 'aporia', 'phobos', 'limos' );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file('nosoi', 'gaudia', 'aporia', 'phobos', 'limos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			[], 'aporia', 'phobos', 'limos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), [], 'aporia', 'phobos', 'limos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			\1, 'aporia', 'phobos', 'limos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), \1, 'aporia', 'phobos', 'limos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'gaudia', [], 'phobos', 'limos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), 'gaudia', [], 'phobos', 'limos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'gaudia', \1, 'phobos', 'limos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), 'gaudia', \1, 'phobos', 'limos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'gaudia', 'aporia', [], 'limos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), 'gaudia', 'aporia', [], 'limos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'gaudia', 'aporia', \1, 'limos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), 'gaudia', 'aporia', \1, 'limos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'gaudia', 'aporia', 'phobos', [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), 'gaudia', 'aporia', 'phobos', [])}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'gaudia', 'aporia', 'phobos', \1 );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), 'gaudia', 'aporia', 'phobos', \1)}
	);
};
done_testing();
