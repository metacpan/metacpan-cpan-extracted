use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Hades::Macro');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 14;
	ok( my $obj = Hades::Macro->new( {} ),
		q{my $obj = Hades::Macro->new({})}
	);
	ok( $obj = Hades::Macro->new(), q{$obj = Hades::Macro->new()} );
	isa_ok( $obj, 'Hades::Macro' );
	ok( $obj = Hades::Macro->new( { alias => { test => ['test'] } } ),
		q{$obj = Hades::Macro->new({alias => { test => ['test'] }})}
	);
	ok( $obj = Hades::Macro->new( alias => { test => ['test'] } ),
		q{$obj = Hades::Macro->new(alias => { test => ['test'] })}
	);
	is_deeply( $obj->macro, [], q{$obj->macro} );
	ok( $obj = Hades::Macro->new(
			{ macro => ['test'], alias => { test => ['test'] } }
		),
		q{$obj = Hades::Macro->new({ macro => ['test'], alias => { test => ['test'] } })}
	);
	eval {
		$obj = Hades::Macro->new(
			{ macro => {}, alias => { test => ['test'] } } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro->new({ macro => {}, alias => { test => ['test'] } })}
	);
	eval {
		$obj = Hades::Macro->new(
			{ macro => 'thanatos', alias => { test => ['test'] } } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro->new({ macro => 'thanatos', alias => { test => ['test'] } })}
	);
	eval {
		$obj = Hades::Macro->new(
			{ macro => ['test'], alias => { test => {} } } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro->new({ macro => ['test'], alias => { test => {} } })}
	);
	eval {
		$obj = Hades::Macro->new(
			{ macro => ['test'], alias => { test => 'geras' } } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro->new({ macro => ['test'], alias => { test => 'geras' } })}
	);
	eval {
		$obj = Hades::Macro->new(
			{ macro => ['test'], alias => { test => undef } } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro->new({ macro => ['test'], alias => { test => undef } })}
	);
	eval { $obj = Hades::Macro->new( { macro => ['test'], alias => [] } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro->new({ macro => ['test'], alias => [] })}
	);
	eval {
		$obj = Hades::Macro->new( { macro => ['test'], alias => 'thanatos' } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Macro->new({ macro => ['test'], alias => 'thanatos' })}
	);
};
subtest 'macro' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro->new( {} ),
		q{my $obj = Hades::Macro->new({})}
	);
	can_ok( $obj, 'macro' );
	is_deeply( $obj->macro( ['test'] ), ['test'], q{$obj->macro(['test'])} );
	eval { $obj->macro( {} ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->macro({})} );
	eval { $obj->macro('geras') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->macro('geras')} );
	is_deeply( $obj->macro, ['test'], q{$obj->macro} );
};
subtest 'alias' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Macro->new( {} ),
		q{my $obj = Hades::Macro->new({})}
	);
	can_ok( $obj, 'alias' );
	is( $obj->alias, undef, q{$obj->alias} );
	is_deeply(
		$obj->alias( { test => ['test'] } ),
		{ test => ['test'] },
		q{$obj->alias({ test => ['test'] })}
	);
	eval { $obj->alias( { test => {} } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->alias({ test => {} })}
	);
	eval { $obj->alias( { test => 'penthos' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->alias({ test => 'penthos' })}
	);
	eval { $obj->alias( { test => undef } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->alias({ test => undef })}
	);
	eval { $obj->alias( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->alias([])} );
	eval { $obj->alias('aporia') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->alias('aporia')} );
	is_deeply( $obj->alias, { test => ['test'] }, q{$obj->alias} );
};
subtest 'has_alias' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Macro->new( {} ),
		q{my $obj = Hades::Macro->new({})}
	);
	can_ok( $obj, 'has_alias' );
	ok( do { delete $obj->{alias}; 1; }, q{do{ delete $obj->{alias}; 1;}} );
	is( $obj->has_alias, '', q{$obj->has_alias} );
	is_deeply(
		$obj->alias( { test => ['test'] } ),
		{ test => ['test'] },
		q{$obj->alias({ test => ['test'] })}
	);
	is( $obj->has_alias, 1, q{$obj->has_alias} );
};
subtest 'meta' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Macro->new( {} ),
		q{my $obj = Hades::Macro->new({})}
	);
	can_ok( $obj, 'meta' );
	eval { $obj->meta( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta([])} );
	eval { $obj->meta('geras') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta('geras')} );
};
done_testing();
