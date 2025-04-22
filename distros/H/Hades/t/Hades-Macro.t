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
	ok( $obj = Hades::Macro->new(
			{ alias => { test => ['test'] }, macro => ['test'] }
		),
		q{$obj = Hades::Macro->new({ alias => { test => ['test'] }, macro => ['test'] })}
	);
	eval {
		$obj = Hades::Macro->new(
			{ alias => { test => {} }, macro => ['test'] } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Macro->new({ alias => { test => {} }, macro => ['test'] })}
	);
	eval {
		$obj = Hades::Macro->new(
			{ alias => { test => 'aporia' }, macro => ['test'] } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Macro->new({ alias => { test => 'aporia' }, macro => ['test'] })}
	);
	eval {
		$obj = Hades::Macro->new(
			{ alias => { test => undef }, macro => ['test'] } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Macro->new({ alias => { test => undef }, macro => ['test'] })}
	);
	eval { $obj = Hades::Macro->new( { alias => [], macro => ['test'] } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Macro->new({ alias => [], macro => ['test'] })}
	);
	eval {
		$obj = Hades::Macro->new( { alias => 'phobos', macro => ['test'] } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Macro->new({ alias => 'phobos', macro => ['test'] })}
	);
	ok( $obj = Hades::Macro->new( { alias => { test => ['test'] } } ),
		q{$obj = Hades::Macro->new({alias => { test => ['test'] }})}
	);
	ok( $obj = Hades::Macro->new( alias => { test => ['test'] } ),
		q{$obj = Hades::Macro->new(alias => { test => ['test'] })}
	);
	is_deeply( $obj->macro, [], q{$obj->macro} );
	eval {
		$obj = Hades::Macro->new(
			{ alias => { test => ['test'] }, macro => {} } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Macro->new({ alias => { test => ['test'] }, macro => {} })}
	);
	eval {
		$obj = Hades::Macro->new(
			{ alias => { test => ['test'] }, macro => 'algea' } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Macro->new({ alias => { test => ['test'] }, macro => 'algea' })}
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
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->macro({})} );
	eval { $obj->macro('gaudia') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->macro('gaudia')} );
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->alias({ test => {} })}
	);
	eval { $obj->alias( { test => 'geras' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->alias({ test => 'geras' })}
	);
	eval { $obj->alias( { test => undef } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->alias({ test => undef })}
	);
	eval { $obj->alias( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->alias([])} );
	eval { $obj->alias('hypnos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->alias('hypnos')} );
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
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta([])} );
	eval { $obj->meta('nosoi') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta('nosoi')} );
};
done_testing();
