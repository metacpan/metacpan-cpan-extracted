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
			{   locales => { 'algea' => { 'test' => 'test' } },
				fb      => 'nosoi',
				locale  => 'thanatos'
			}
		),
		q{$obj = Hades::Myths::Object->new({ locales => { 'algea' => { 'test' => 'test' } }, fb => 'nosoi', locale => 'thanatos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'algea' => [] },
				fb      => 'nosoi',
				locale  => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Myths::Object->new({ locales => { 'algea' => [] }, fb => 'nosoi', locale => 'thanatos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'algea' => 'geras' },
				fb      => 'nosoi',
				locale  => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Myths::Object->new({ locales => { 'algea' => 'geras' }, fb => 'nosoi', locale => 'thanatos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'algea' => undef },
				fb      => 'nosoi',
				locale  => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Myths::Object->new({ locales => { 'algea' => undef }, fb => 'nosoi', locale => 'thanatos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{ locales => [], fb => 'nosoi', locale => 'thanatos' } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Myths::Object->new({ locales => [], fb => 'nosoi', locale => 'thanatos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{ locales => 'geras', fb => 'nosoi', locale => 'thanatos' } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Myths::Object->new({ locales => 'geras', fb => 'nosoi', locale => 'thanatos' })}
	);
	ok( $obj = Hades::Myths::Object->new(
			{   locales => { 'algea' => { 'test' => 'test' } },
				locale  => 'thanatos'
			}
		),
		q{$obj = Hades::Myths::Object->new({locales => { 'algea' => { 'test' => 'test' } }, locale => 'thanatos'})}
	);
	ok( $obj = Hades::Myths::Object->new(
			locales => { 'algea' => { 'test' => 'test' } },
			locale  => 'thanatos'
		),
		q{$obj = Hades::Myths::Object->new(locales => { 'algea' => { 'test' => 'test' } }, locale => 'thanatos')}
	);
	is_deeply( $obj->fb, 'en', q{$obj->fb} );
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'algea' => { 'test' => 'test' } },
				fb      => [],
				locale  => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Myths::Object->new({ locales => { 'algea' => { 'test' => 'test' } }, fb => [], locale => 'thanatos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'algea' => { 'test' => 'test' } },
				fb      => \1,
				locale  => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Myths::Object->new({ locales => { 'algea' => { 'test' => 'test' } }, fb => \1, locale => 'thanatos' })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'algea' => { 'test' => 'test' } },
				fb      => 'nosoi',
				locale  => []
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Myths::Object->new({ locales => { 'algea' => { 'test' => 'test' } }, fb => 'nosoi', locale => [] })}
	);
	eval {
		$obj = Hades::Myths::Object->new(
			{   locales => { 'algea' => { 'test' => 'test' } },
				fb      => 'nosoi',
				locale  => \1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Myths::Object->new({ locales => { 'algea' => { 'test' => 'test' } }, fb => 'nosoi', locale => \1 })}
	);
};
subtest 'fb' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'fb' );
	is_deeply( $obj->fb('nosoi'), 'nosoi', q{$obj->fb('nosoi')} );
	eval { $obj->fb( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->fb([])} );
	eval { $obj->fb( \1 ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->fb(\1)} );
	is_deeply( $obj->fb, 'nosoi', q{$obj->fb} );
};
subtest 'locale' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'locale' );
	is_deeply( $obj->locale('nosoi'), 'nosoi', q{$obj->locale('nosoi')} );
	eval { $obj->locale( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->locale([])} );
	eval { $obj->locale( \1 ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->locale(\1)} );
	is_deeply( $obj->locale, 'nosoi', q{$obj->locale} );
};
subtest '_build_locale' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, '_build_locale' );
	eval { $obj->_build_locale( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_build_locale([])} );
	eval { $obj->_build_locale( \1 ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
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
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_set_language_from_locale([])}
	);
	eval { $obj->_set_language_from_locale( \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_set_language_from_locale(\1)}
	);
	eval { $obj->_set_language_from_locale() };
	like( $@, qr/undef/, q{$obj->_set_language_from_locale()} );
};
subtest 'language' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'language' );
	eval { $obj->language( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->language([])} );
	eval { $obj->language( \1 ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
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
	is_deeply( $obj->language('algea'), 'algea', q{$obj->language('algea')} );
	is( $obj->has_language, 1, q{$obj->has_language} );
};
subtest 'locales' => sub {
	plan tests => 9;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'locales' );
	is_deeply(
		$obj->locales( { 'thanatos' => { 'test' => 'test' } } ),
		{ 'thanatos' => { 'test' => 'test' } },
		q{$obj->locales({ 'thanatos' => { 'test' => 'test' } })}
	);
	eval { $obj->locales( { 'thanatos' => [] } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->locales({ 'thanatos' => [] })}
	);
	eval { $obj->locales( { 'thanatos' => 'curae' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->locales({ 'thanatos' => 'curae' })}
	);
	eval { $obj->locales( { 'thanatos' => undef } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->locales({ 'thanatos' => undef })}
	);
	eval { $obj->locales( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->locales([])} );
	eval { $obj->locales('algea') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->locales('algea')} );
	is_deeply( $obj->locales, { 'thanatos' => { 'test' => 'test' } },
		q{$obj->locales} );
};
subtest '_build_locales' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, '_build_locales' );
	eval { $obj->_build_locales( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_build_locales([])} );
	eval { $obj->_build_locales('thanatos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->_build_locales('thanatos')}
	);
};
subtest 'convert_locale' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'convert_locale' );
	eval { $obj->convert_locale( [], 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->convert_locale([], 'gaudia')}
	);
	eval { $obj->convert_locale( \1, 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->convert_locale(\1, 'gaudia')}
	);
	eval { $obj->convert_locale( 'hypnos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->convert_locale('hypnos', [])}
	);
	eval { $obj->convert_locale( 'hypnos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->convert_locale('hypnos', \1)}
	);
};
subtest 'add' => sub {
	plan tests => 9;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'add' );
	eval { $obj->add( [], { 'geras' => { 'test' => 'test' } } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->add([], { 'geras' => { 'test' => 'test' } })}
	);
	eval { $obj->add( \1, { 'geras' => { 'test' => 'test' } } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->add(\1, { 'geras' => { 'test' => 'test' } })}
	);
	eval { $obj->add( 'phobos', { 'geras' => [] } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->add('phobos', { 'geras' => [] })}
	);
	eval { $obj->add( 'phobos', { 'geras' => 'phobos' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->add('phobos', { 'geras' => 'phobos' })}
	);
	eval { $obj->add( 'phobos', { 'geras' => undef } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->add('phobos', { 'geras' => undef })}
	);
	eval { $obj->add( 'phobos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->add('phobos', [])}
	);
	eval { $obj->add( 'phobos', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->add('phobos', 'phobos')}
	);
};
subtest 'string' => sub {
	plan tests => 10;
	ok( my $obj = Hades::Myths::Object->new( {} ),
		q{my $obj = Hades::Myths::Object->new({})}
	);
	can_ok( $obj, 'string' );
	eval { $obj->string( [], 'geras', 'hypnos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->string([], 'geras', 'hypnos', 'nosoi')}
	);
	eval { $obj->string( \1, 'geras', 'hypnos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->string(\1, 'geras', 'hypnos', 'nosoi')}
	);
	eval { $obj->string( 'aporia', [], 'hypnos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->string('aporia', [], 'hypnos', 'nosoi')}
	);
	eval { $obj->string( 'aporia', \1, 'hypnos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->string('aporia', \1, 'hypnos', 'nosoi')}
	);
	eval { $obj->string( 'aporia', 'geras', [], 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->string('aporia', 'geras', [], 'nosoi')}
	);
	eval { $obj->string( 'aporia', 'geras', \1, 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->string('aporia', 'geras', \1, 'nosoi')}
	);
	eval { $obj->string( 'aporia', 'geras', 'hypnos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->string('aporia', 'geras', 'hypnos', [])}
	);
	eval { $obj->string( 'aporia', 'geras', 'hypnos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->string('aporia', 'geras', 'hypnos', \1)}
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
