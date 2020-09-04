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
	eval { $obj = Hades::Macro::FH->new( { macro => 'curae' } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro::FH->new({ macro => 'curae' })}
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
	eval { $obj->macro('gaudia') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->macro('gaudia')} );
	is_deeply( $obj->macro, ['test'], q{$obj->macro} );
};
subtest 'open_write' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'open_write' );
	eval { $obj->open_write( [], 'curae', 'curae', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write([], 'curae', 'curae', 'aporia')}
	);
	eval { $obj->open_write( 'phobos', 'curae', 'curae', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write('phobos', 'curae', 'curae', 'aporia')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), [], 'curae', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write(bless({}, 'Test'), [], 'curae', 'aporia')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), \1, 'curae', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write(bless({}, 'Test'), \1, 'curae', 'aporia')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), 'curae', [], 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write(bless({}, 'Test'), 'curae', [], 'aporia')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), 'curae', \1, 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write(bless({}, 'Test'), 'curae', \1, 'aporia')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), 'curae', 'curae', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write(bless({}, 'Test'), 'curae', 'curae', [])}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), 'curae', 'curae', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_write(bless({}, 'Test'), 'curae', 'curae', \1)}
	);
};
subtest 'open_read' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'open_read' );
	eval { $obj->open_read( [], 'thanatos', 'curae', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read([], 'thanatos', 'curae', 'phobos')}
	);
	eval { $obj->open_read( 'algea', 'thanatos', 'curae', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read('algea', 'thanatos', 'curae', 'phobos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), [], 'curae', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read(bless({}, 'Test'), [], 'curae', 'phobos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), \1, 'curae', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read(bless({}, 'Test'), \1, 'curae', 'phobos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), 'thanatos', [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read(bless({}, 'Test'), 'thanatos', [], 'phobos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), 'thanatos', \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read(bless({}, 'Test'), 'thanatos', \1, 'phobos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), 'thanatos', 'curae', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read(bless({}, 'Test'), 'thanatos', 'curae', [])}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), 'thanatos', 'curae', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->open_read(bless({}, 'Test'), 'thanatos', 'curae', \1)}
	);
};
subtest 'close_file' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'close_file' );
	eval { $obj->close_file( [], 'gaudia', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->close_file([], 'gaudia', 'curae')}
	);
	eval { $obj->close_file( 'geras', 'gaudia', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->close_file('geras', 'gaudia', 'curae')}
	);
	eval { $obj->close_file( bless( {}, 'Test' ), [], 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->close_file(bless({}, 'Test'), [], 'curae')}
	);
	eval { $obj->close_file( bless( {}, 'Test' ), \1, 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->close_file(bless({}, 'Test'), \1, 'curae')}
	);
	eval { $obj->close_file( bless( {}, 'Test' ), 'gaudia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->close_file(bless({}, 'Test'), 'gaudia', [])}
	);
	eval { $obj->close_file( bless( {}, 'Test' ), 'gaudia', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->close_file(bless({}, 'Test'), 'gaudia', \1)}
	);
};
subtest 'read_file' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'read_file' );
	eval { $obj->read_file( [], 'penthos', 'hypnos', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file([], 'penthos', 'hypnos', 'limos')}
	);
	eval { $obj->read_file( 'aporia', 'penthos', 'hypnos', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file('aporia', 'penthos', 'hypnos', 'limos')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), [], 'hypnos', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file(bless({}, 'Test'), [], 'hypnos', 'limos')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), \1, 'hypnos', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file(bless({}, 'Test'), \1, 'hypnos', 'limos')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), 'penthos', [], 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file(bless({}, 'Test'), 'penthos', [], 'limos')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), 'penthos', \1, 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file(bless({}, 'Test'), 'penthos', \1, 'limos')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), 'penthos', 'hypnos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file(bless({}, 'Test'), 'penthos', 'hypnos', [])}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), 'penthos', 'hypnos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->read_file(bless({}, 'Test'), 'penthos', 'hypnos', \1)}
	);
};
subtest 'write_file' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'write_file' );
	eval { $obj->write_file( [], 'algea', 'algea', 'geras', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file([], 'algea', 'algea', 'geras', 'hypnos')}
	);
	eval { $obj->write_file( 'phobos', 'algea', 'algea', 'geras', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file('phobos', 'algea', 'algea', 'geras', 'hypnos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			[], 'algea', 'geras', 'hypnos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), [], 'algea', 'geras', 'hypnos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			\1, 'algea', 'geras', 'hypnos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), \1, 'algea', 'geras', 'hypnos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'algea', [], 'geras', 'hypnos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), 'algea', [], 'geras', 'hypnos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'algea', \1, 'geras', 'hypnos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), 'algea', \1, 'geras', 'hypnos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'algea', 'algea', [], 'hypnos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), 'algea', 'algea', [], 'hypnos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'algea', 'algea', \1, 'hypnos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), 'algea', 'algea', \1, 'hypnos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ), 'algea', 'algea', 'geras', [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), 'algea', 'algea', 'geras', [])}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ), 'algea', 'algea', 'geras', \1 );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->write_file(bless({}, 'Test'), 'algea', 'algea', 'geras', \1)}
	);
};
done_testing();
