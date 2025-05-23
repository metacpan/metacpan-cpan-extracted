use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Hades::Realm::Import::Export');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 3;
	ok( my $obj = Hades::Realm::Import::Export->new( {} ),
		q{my $obj = Hades::Realm::Import::Export->new({})}
	);
	ok( $obj = Hades::Realm::Import::Export->new(),
		q{$obj = Hades::Realm::Import::Export->new()}
	);
	isa_ok( $obj, 'Hades::Realm::Import::Export' );
};
subtest 'build_new' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::Import::Export->new( {} ),
		q{my $obj = Hades::Realm::Import::Export->new({})}
	);
	can_ok( $obj, 'build_new' );
};
subtest 'build_exporter' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Realm::Import::Export->new( {} ),
		q{my $obj = Hades::Realm::Import::Export->new({})}
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
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
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
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_exporter(\1, bless({}, 'Test'), { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter(
			'curae', [],
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_exporter('curae', [], { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter(
			'curae', 'phobos',
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_exporter('curae', 'phobos', { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter( 'curae', bless( {}, 'Test' ),
			[], { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_exporter('curae', bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter( 'curae', bless( {}, 'Test' ),
			'aporia', { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_exporter('curae', bless({}, 'Test'), 'aporia', { 'test' => 'test' })}
	);
	eval {
		$obj->build_exporter(
			'curae',
			bless( {}, 'Test' ),
			{ 'test' => 'test' }, []
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_exporter('curae', bless({}, 'Test'), { 'test' => 'test' }, [])}
	);
	eval {
		$obj->build_exporter(
			'curae',
			bless( {}, 'Test' ),
			{ 'test' => 'test' }, 'nosoi'
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_exporter('curae', bless({}, 'Test'), { 'test' => 'test' }, 'nosoi')}
	);
};
subtest 'after_class' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::Import::Export->new( {} ),
		q{my $obj = Hades::Realm::Import::Export->new({})}
	);
	can_ok( $obj, 'after_class' );
	eval { $obj->after_class( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->after_class([])} );
	eval { $obj->after_class('geras') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->after_class('geras')} );
};
done_testing();
