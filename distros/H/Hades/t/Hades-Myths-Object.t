use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Hades::Myths::Object');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 16;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	ok( $obj = Hades::Myths::Object->new(),
		q{$obj = Hades::Myths::Object->new()}
	);
	isa_ok( $obj, 'Hades::Myths::Object' );
	ok( $obj = Hades::Myths::Object->new(
			{   locales => { 'gaudia' => { 'test' => 'test' } },
				locale  => 'curae',
				fb      => 'penthos'
			}
		),
		q{$obj = Hades::Myths::Object->new({ locales => { 'gaudia' => { 'test' => 'test' } }, locale => 'curae', fb => 'penthos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'gaudia' => [] },
				locale  => 'curae',
				fb      => 'penthos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Myths::Object->new({ locales => { 'gaudia' => [] }, locale => 'curae', fb => 'penthos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'gaudia' => 'penthos' },
				locale  => 'curae',
				fb      => 'penthos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Myths::Object->new({ locales => { 'gaudia' => 'penthos' }, locale => 'curae', fb => 'penthos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'gaudia' => undef },
				locale  => 'curae',
				fb      => 'penthos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Myths::Object->new({ locales => { 'gaudia' => undef }, locale => 'curae', fb => 'penthos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{ locales => [], locale => 'curae', fb => 'penthos' } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Myths::Object->new({ locales => [], locale => 'curae', fb => 'penthos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{ locales => 'geras', locale => 'curae', fb => 'penthos' } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Myths::Object->new({ locales => 'geras', locale => 'curae', fb => 'penthos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'gaudia' => { 'test' => 'test' } },
				locale  => [],
				fb      => 'penthos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Myths::Object->new({ locales => { 'gaudia' => { 'test' => 'test' } }, locale => [], fb => 'penthos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'gaudia' => { 'test' => 'test' } },
				locale  => \1,
				fb      => 'penthos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Myths::Object->new({ locales => { 'gaudia' => { 'test' => 'test' } }, locale => \1, fb => 'penthos' })}
	);
	ok( $obj = Hades::Myths::Object->new(
			{   locales => { 'gaudia' => { 'test' => 'test' } },
				locale  => 'curae'
			}
		),
		q{$obj = Hades::Myths::Object->new({locales => { 'gaudia' => { 'test' => 'test' } }, locale => 'curae'})}
	);
	ok( $obj = Hades::Myths::Object->new(
			locales => { 'gaudia' => { 'test' => 'test' } },
			locale  => 'curae'
		),
		q{$obj = Hades::Myths::Object->new(locales => { 'gaudia' => { 'test' => 'test' } }, locale => 'curae')}
	);
	is_deeply( $obj->fb, 'en', q{$obj->fb} );
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'gaudia' => { 'test' => 'test' } },
				locale  => 'curae',
				fb      => []
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Myths::Object->new({ locales => { 'gaudia' => { 'test' => 'test' } }, locale => 'curae', fb => [] })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'gaudia' => { 'test' => 'test' } },
				locale  => 'curae',
				fb      => \1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Myths::Object->new({ locales => { 'gaudia' => { 'test' => 'test' } }, locale => 'curae', fb => \1 })}
	);
};
subtest 'fb' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'fb' );
	is_deeply( $obj->fb('aporia'), 'aporia', q{$obj->fb('aporia')} );
	eval { $obj->fb( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->fb([])} );
	eval { $obj->fb( \1 ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->fb(\1)} );
	is_deeply( $obj->fb, 'aporia', q{$obj->fb} );
};
subtest 'locale' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'locale' );
	is_deeply( $obj->locale('geras'), 'geras', q{$obj->locale('geras')} );
	eval { $obj->locale( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->locale([])} );
	eval { $obj->locale( \1 ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->locale(\1)} );
	is_deeply( $obj->locale, 'geras', q{$obj->locale} );
};
subtest '_build_locale' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, '_build_locale' );
	eval { $obj->_build_locale( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->_build_locale([])} );
	eval { $obj->_build_locale( \1 ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->_build_locale(\1)} );
};
subtest '_set_language_from_locale' => sub {
	plan tests => 5;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, '_set_language_from_locale' );
	eval { $obj->_set_language_from_locale( [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->_set_language_from_locale([])}
	);
	eval { $obj->_set_language_from_locale( \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->_set_language_from_locale(\1)}
	);
	eval { $obj->_set_language_from_locale() };
	like( $@, qr/undef/i, q{$obj->_set_language_from_locale()} );
};
subtest 'language' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'language' );
	eval { $obj->language( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->language([])} );
	eval { $obj->language( \1 ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->language(\1)} );
};
subtest 'has_language' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'has_language' );
	ok( do { delete $obj->{language}; 1; },
		q{do{ delete $obj->{language}; 1;}}
	);
	is( $obj->has_language, '', q{$obj->has_language} );
	is_deeply( $obj->language('gaudia'),
		'gaudia', q{$obj->language('gaudia')} );
	is( $obj->has_language, 1, q{$obj->has_language} );
};
subtest 'locales' => sub {
	plan tests => 9;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'locales' );
	is_deeply(
		$obj->locales( { 'curae' => { 'test' => 'test' } } ),
		{ 'curae' => { 'test' => 'test' } },
		q{$obj->locales({ 'curae' => { 'test' => 'test' } })}
	);
	eval { $obj->locales( { 'curae' => [] } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->locales({ 'curae' => [] })}
	);
	eval { $obj->locales( { 'curae' => 'thanatos' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->locales({ 'curae' => 'thanatos' })}
	);
	eval { $obj->locales( { 'curae' => undef } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->locales({ 'curae' => undef })}
	);
	eval { $obj->locales( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->locales([])} );
	eval { $obj->locales('aporia') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->locales('aporia')} );
	is_deeply( $obj->locales, { 'curae' => { 'test' => 'test' } },
		q{$obj->locales} );
};
subtest '_build_locales' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, '_build_locales' );
	eval { $obj->_build_locales( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->_build_locales([])} );
	eval { $obj->_build_locales('penthos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->_build_locales('penthos')}
	);
};
subtest 'convert_locale' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'convert_locale' );
	eval { $obj->convert_locale( [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->convert_locale([], 'geras')}
	);
	eval { $obj->convert_locale( \1, 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->convert_locale(\1, 'geras')}
	);
	eval { $obj->convert_locale( 'nosoi', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->convert_locale('nosoi', [])}
	);
	eval { $obj->convert_locale( 'nosoi', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->convert_locale('nosoi', \1)}
	);
};
subtest 'add' => sub {
	plan tests => 9;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'add' );
	eval { $obj->add( [], { 'curae' => { 'test' => 'test' } } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->add([], { 'curae' => { 'test' => 'test' } })}
	);
	eval { $obj->add( \1, { 'curae' => { 'test' => 'test' } } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->add(\1, { 'curae' => { 'test' => 'test' } })}
	);
	eval { $obj->add( 'penthos', { 'curae' => [] } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->add('penthos', { 'curae' => [] })}
	);
	eval { $obj->add( 'penthos', { 'curae' => 'thanatos' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->add('penthos', { 'curae' => 'thanatos' })}
	);
	eval { $obj->add( 'penthos', { 'curae' => undef } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->add('penthos', { 'curae' => undef })}
	);
	eval { $obj->add( 'penthos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->add('penthos', [])}
	);
	eval { $obj->add( 'penthos', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->add('penthos', 'geras')}
	);
};
subtest 'string' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'string' );
	eval { $obj->string( [], 'penthos', 'phobos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->string([], 'penthos', 'phobos', 'nosoi')}
	);
	eval { $obj->string( \1, 'penthos', 'phobos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->string(\1, 'penthos', 'phobos', 'nosoi')}
	);
	eval { $obj->string( 'algea', [], 'phobos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->string('algea', [], 'phobos', 'nosoi')}
	);
	eval { $obj->string( 'algea', \1, 'phobos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->string('algea', \1, 'phobos', 'nosoi')}
	);
	eval { $obj->string( 'algea', 'penthos', [], 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->string('algea', 'penthos', [], 'nosoi')}
	);
	eval { $obj->string( 'algea', 'penthos', \1, 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->string('algea', 'penthos', \1, 'nosoi')}
	);
	eval { $obj->string( 'algea', 'penthos', 'phobos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->string('algea', 'penthos', 'phobos', [])}
	);
	eval { $obj->string( 'algea', 'penthos', 'phobos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->string('algea', 'penthos', 'phobos', \1)}
	);
};
subtest 'debug_steps' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'debug_steps' );
};
subtest 'DESTROY' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'DESTROY' );
};
subtest 'AUTOLOAD' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'AUTOLOAD' );
};
done_testing();
