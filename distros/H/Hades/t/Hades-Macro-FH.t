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
		qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Macro::FH->new({ macro => {} })}
	);
	eval { $obj = Hades::Macro::FH->new( { macro => 'hypnos' } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Macro::FH->new({ macro => 'hypnos' })}
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
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->macro({})} );
	eval { $obj->macro('penthos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->macro('penthos')} );
	is_deeply( $obj->macro, ['test'], q{$obj->macro} );
};
subtest 'open_write' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'open_write' );
	eval { $obj->open_write( [], 'nosoi', 'aporia', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_write([], 'nosoi', 'aporia', 'curae')}
	);
	eval { $obj->open_write( 'aporia', 'nosoi', 'aporia', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_write('aporia', 'nosoi', 'aporia', 'curae')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), [], 'aporia', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_write(bless({}, 'Test'), [], 'aporia', 'curae')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), \1, 'aporia', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_write(bless({}, 'Test'), \1, 'aporia', 'curae')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), 'nosoi', [], 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_write(bless({}, 'Test'), 'nosoi', [], 'curae')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), 'nosoi', \1, 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_write(bless({}, 'Test'), 'nosoi', \1, 'curae')}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), 'nosoi', 'aporia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_write(bless({}, 'Test'), 'nosoi', 'aporia', [])}
	);
	eval { $obj->open_write( bless( {}, 'Test' ), 'nosoi', 'aporia', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_write(bless({}, 'Test'), 'nosoi', 'aporia', \1)}
	);
};
subtest 'open_read' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'open_read' );
	eval { $obj->open_read( [], 'phobos', 'algea', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_read([], 'phobos', 'algea', 'penthos')}
	);
	eval { $obj->open_read( 'nosoi', 'phobos', 'algea', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_read('nosoi', 'phobos', 'algea', 'penthos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), [], 'algea', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_read(bless({}, 'Test'), [], 'algea', 'penthos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), \1, 'algea', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_read(bless({}, 'Test'), \1, 'algea', 'penthos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), 'phobos', [], 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_read(bless({}, 'Test'), 'phobos', [], 'penthos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), 'phobos', \1, 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_read(bless({}, 'Test'), 'phobos', \1, 'penthos')}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), 'phobos', 'algea', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_read(bless({}, 'Test'), 'phobos', 'algea', [])}
	);
	eval { $obj->open_read( bless( {}, 'Test' ), 'phobos', 'algea', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->open_read(bless({}, 'Test'), 'phobos', 'algea', \1)}
	);
};
subtest 'close_file' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'close_file' );
	eval { $obj->close_file( [], 'hypnos', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->close_file([], 'hypnos', 'limos')}
	);
	eval { $obj->close_file( 'algea', 'hypnos', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->close_file('algea', 'hypnos', 'limos')}
	);
	eval { $obj->close_file( bless( {}, 'Test' ), [], 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->close_file(bless({}, 'Test'), [], 'limos')}
	);
	eval { $obj->close_file( bless( {}, 'Test' ), \1, 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->close_file(bless({}, 'Test'), \1, 'limos')}
	);
	eval { $obj->close_file( bless( {}, 'Test' ), 'hypnos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->close_file(bless({}, 'Test'), 'hypnos', [])}
	);
	eval { $obj->close_file( bless( {}, 'Test' ), 'hypnos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->close_file(bless({}, 'Test'), 'hypnos', \1)}
	);
};
subtest 'read_file' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'read_file' );
	eval { $obj->read_file( [], 'algea', 'aporia', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->read_file([], 'algea', 'aporia', 'geras')}
	);
	eval { $obj->read_file( 'penthos', 'algea', 'aporia', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->read_file('penthos', 'algea', 'aporia', 'geras')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), [], 'aporia', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->read_file(bless({}, 'Test'), [], 'aporia', 'geras')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), \1, 'aporia', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->read_file(bless({}, 'Test'), \1, 'aporia', 'geras')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), 'algea', [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->read_file(bless({}, 'Test'), 'algea', [], 'geras')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), 'algea', \1, 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->read_file(bless({}, 'Test'), 'algea', \1, 'geras')}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), 'algea', 'aporia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->read_file(bless({}, 'Test'), 'algea', 'aporia', [])}
	);
	eval { $obj->read_file( bless( {}, 'Test' ), 'algea', 'aporia', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->read_file(bless({}, 'Test'), 'algea', 'aporia', \1)}
	);
};
subtest 'write_file' => sub {
	plan tests => 12;
	ok( my $obj = Hades::Macro::FH->new( {} ),
		q{my $obj = Hades::Macro::FH->new({})}
	);
	can_ok( $obj, 'write_file' );
	eval { $obj->write_file( [], 'thanatos', 'geras', 'algea', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->write_file([], 'thanatos', 'geras', 'algea', 'penthos')}
	);
	eval {
		$obj->write_file( 'geras', 'thanatos', 'geras', 'algea', 'penthos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->write_file('geras', 'thanatos', 'geras', 'algea', 'penthos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			[], 'geras', 'algea', 'penthos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->write_file(bless({}, 'Test'), [], 'geras', 'algea', 'penthos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			\1, 'geras', 'algea', 'penthos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->write_file(bless({}, 'Test'), \1, 'geras', 'algea', 'penthos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'thanatos', [], 'algea', 'penthos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->write_file(bless({}, 'Test'), 'thanatos', [], 'algea', 'penthos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'thanatos', \1, 'algea', 'penthos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->write_file(bless({}, 'Test'), 'thanatos', \1, 'algea', 'penthos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'thanatos', 'geras', [], 'penthos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->write_file(bless({}, 'Test'), 'thanatos', 'geras', [], 'penthos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'thanatos', 'geras', \1, 'penthos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->write_file(bless({}, 'Test'), 'thanatos', 'geras', \1, 'penthos')}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'thanatos', 'geras', 'algea', [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->write_file(bless({}, 'Test'), 'thanatos', 'geras', 'algea', [])}
	);
	eval {
		$obj->write_file( bless( {}, 'Test' ),
			'thanatos', 'geras', 'algea', \1 );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->write_file(bless({}, 'Test'), 'thanatos', 'geras', 'algea', \1)}
	);
};
done_testing();
