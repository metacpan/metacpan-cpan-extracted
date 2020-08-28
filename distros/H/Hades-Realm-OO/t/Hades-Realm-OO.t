use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Hades::Realm::OO');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 20;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	ok( $obj = Hades::Realm::OO->new(), q{$obj = Hades::Realm::OO->new()} );
	isa_ok( $obj, 'Hades::Realm::OO' );
	ok( $obj = Hades::Realm::OO->new(
			{   meta => {
					'nosoi' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				current_class => 'limos',
				is_role       => 1
			}
		),
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, current_class => 'limos', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta => {
					'nosoi' =>
					    { types => [], attributes => { 'test' => 'test' } }
				},
				current_class => 'limos',
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => { types => [], attributes => { 'test' => 'test' } } }, current_class => 'limos', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta => {
					'nosoi' => {
						types      => 'aporia',
						attributes => { 'test' => 'test' }
					}
				},
				current_class => 'limos',
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => { types => 'aporia', attributes => { 'test' => 'test' } } }, current_class => 'limos', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta => {
					'nosoi' => {
						types      => undef,
						attributes => { 'test' => 'test' }
					}
				},
				current_class => 'limos',
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => { types => undef, attributes => { 'test' => 'test' } } }, current_class => 'limos', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta => {
					'nosoi' =>
					    { types => { 'test' => 'test' }, attributes => [] }
				},
				current_class => 'limos',
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => { types => { 'test' => 'test' }, attributes => [] } }, current_class => 'limos', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta => {
					'nosoi' => {
						types      => { 'test' => 'test' },
						attributes => 'hypnos'
					}
				},
				current_class => 'limos',
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => { types => { 'test' => 'test' }, attributes => 'hypnos' } }, current_class => 'limos', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta => {
					'nosoi' => {
						types      => { 'test' => 'test' },
						attributes => undef
					}
				},
				current_class => 'limos',
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => { types => { 'test' => 'test' }, attributes => undef } }, current_class => 'limos', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta          => { 'nosoi' => {} },
				current_class => 'limos',
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => {} }, current_class => 'limos', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta          => { 'nosoi' => [] },
				current_class => 'limos',
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => [] }, current_class => 'limos', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta          => { 'nosoi' => 'nosoi' },
				current_class => 'limos',
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => 'nosoi' }, current_class => 'limos', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta          => { 'nosoi' => undef },
				current_class => 'limos',
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => undef }, current_class => 'limos', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{ meta => [], current_class => 'limos', is_role => 1 } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => [], current_class => 'limos', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{ meta => 'curae', current_class => 'limos', is_role => 1 } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => 'curae', current_class => 'limos', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta => {
					'nosoi' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				current_class => [],
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, current_class => [], is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta => {
					'nosoi' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				current_class => \1,
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, current_class => \1, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta => {
					'nosoi' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				current_class => 'limos',
				is_role       => []
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, current_class => 'limos', is_role => [] })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   meta => {
					'nosoi' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				current_class => 'limos',
				is_role       => {}
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ meta => { 'nosoi' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, current_class => 'limos', is_role => {} })}
	);
};
subtest 'is_role' => sub {
	plan tests => 7;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'is_role' );
	is( $obj->is_role, undef, q{$obj->is_role} );
	is_deeply( $obj->is_role(1), 1, q{$obj->is_role(1)} );
	eval { $obj->is_role( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->is_role([])} );
	eval { $obj->is_role( {} ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->is_role({})} );
	is_deeply( $obj->is_role, 1, q{$obj->is_role} );
};
subtest 'meta' => sub {
	plan tests => 17;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'meta' );
	is( $obj->meta, undef, q{$obj->meta} );
	is_deeply(
		$obj->meta(
			{   'algea' => {
					types      => { 'test' => 'test' },
					attributes => { 'test' => 'test' }
				}
			}
		),
		{   'algea' => {
				types      => { 'test' => 'test' },
				attributes => { 'test' => 'test' }
			}
		},
		q{$obj->meta({ 'algea' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'algea' => { types => [], attributes => { 'test' => 'test' } }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'algea' => { types => [], attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'algea' =>
				    { types => 'geras', attributes => { 'test' => 'test' } }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'algea' => { types => 'geras', attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'algea' =>
				    { types => undef, attributes => { 'test' => 'test' } }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'algea' => { types => undef, attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'algea' => { types => { 'test' => 'test' }, attributes => [] }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'algea' => { types => { 'test' => 'test' }, attributes => [] } })}
	);
	eval {
		$obj->meta(
			{   'algea' =>
				    { types => { 'test' => 'test' }, attributes => 'curae' }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'algea' => { types => { 'test' => 'test' }, attributes => 'curae' } })}
	);
	eval {
		$obj->meta(
			{   'algea' =>
				    { types => { 'test' => 'test' }, attributes => undef }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'algea' => { types => { 'test' => 'test' }, attributes => undef } })}
	);
	eval { $obj->meta( { 'algea' => {} } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'algea' => {} })}
	);
	eval { $obj->meta( { 'algea' => [] } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'algea' => [] })}
	);
	eval { $obj->meta( { 'algea' => 'phobos' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'algea' => 'phobos' })}
	);
	eval { $obj->meta( { 'algea' => undef } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'algea' => undef })}
	);
	eval { $obj->meta( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta([])} );
	eval { $obj->meta('curae') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta('curae')} );
	is_deeply(
		$obj->meta,
		{   'algea' => {
				types      => { 'test' => 'test' },
				attributes => { 'test' => 'test' }
			}
		},
		q{$obj->meta}
	);
};
subtest 'current_class' => sub {
	plan tests => 7;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'current_class' );
	is( $obj->current_class, undef, q{$obj->current_class} );
	is_deeply( $obj->current_class('algea'),
		'algea', q{$obj->current_class('algea')} );
	eval { $obj->current_class( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->current_class([])} );
	eval { $obj->current_class( \1 ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->current_class(\1)} );
	is_deeply( $obj->current_class, 'algea', q{$obj->current_class} );
};
subtest 'clear_is_role' => sub {
	plan tests => 5;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'clear_is_role' );
	is_deeply( $obj->is_role(1), 1, q{$obj->is_role(1)} );
	ok( $obj->clear_is_role, q{$obj->clear_is_role} );
	is( $obj->is_role, undef, q{$obj->is_role} );
};
subtest 'module_generate' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'module_generate' );
	eval { $obj->module_generate( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->module_generate([])} );
	eval { $obj->module_generate('curae') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->module_generate('curae')}
	);
};
subtest 'build_with_keywords' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_with_keywords' );
	eval { $obj->build_with_keywords( {} ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_with_keywords({})}
	);
	eval { $obj->build_with_keywords('hypnos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_with_keywords('hypnos')}
	);
};
subtest 'build_requires' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_requires' );
	eval { $obj->build_requires( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_requires([])} );
	eval { $obj->build_requires('thanatos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_requires('thanatos')}
	);
};
subtest 'build_class_inheritance' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_class_inheritance' );
};
subtest 'build_predicate' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_predicate' );
};
subtest 'build_requires_keywords' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_requires_keywords' );
	eval { $obj->build_requires_keywords( {} ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_requires_keywords({})}
	);
	eval { $obj->build_requires_keywords('phobos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_requires_keywords('phobos')}
	);
};
subtest 'build_as_role' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_as_role' );
	eval { $obj->build_as_role( [], { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_role([], { 'test' => 'test' })}
	);
	eval { $obj->build_as_role( 'hypnos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_role('hypnos', { 'test' => 'test' })}
	);
	eval { $obj->build_as_role( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_role(bless({}, 'Test'), [])}
	);
	eval { $obj->build_as_role( bless( {}, 'Test' ), 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_role(bless({}, 'Test'), 'geras')}
	);
};
subtest 'build_before_keywords' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_before_keywords' );
	eval { $obj->build_before_keywords( {} ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_before_keywords({})}
	);
	eval { $obj->build_before_keywords('gaudia') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_before_keywords('gaudia')}
	);
};
subtest 'build_with' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_with' );
	eval { $obj->build_with( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_with([])} );
	eval { $obj->build_with('geras') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_with('geras')} );
};
subtest 'build_around_keywords' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_around_keywords' );
	eval { $obj->build_around_keywords( {} ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_around_keywords({})}
	);
	eval { $obj->build_around_keywords('penthos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_around_keywords('penthos')}
	);
};
subtest 'build_as_class' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_as_class' );
	eval { $obj->build_as_class( [], { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_class([], { 'test' => 'test' })}
	);
	eval { $obj->build_as_class( 'phobos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_class('phobos', { 'test' => 'test' })}
	);
	eval { $obj->build_as_class( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_class(bless({}, 'Test'), [])}
	);
	eval { $obj->build_as_class( bless( {}, 'Test' ), 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_class(bless({}, 'Test'), 'nosoi')}
	);
};
subtest 'build_new' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_new' );
	eval { $obj->build_new( [], { 'test' => 'test' }, { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new([], { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval {
		$obj->build_new(
			'thanatos',
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new('thanatos', { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval { $obj->build_new( bless( {}, 'Test' ), [], { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new(bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval {
		$obj->build_new( bless( {}, 'Test' ), 'nosoi', { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new(bless({}, 'Test'), 'nosoi', { 'test' => 'test' })}
	);
	eval { $obj->build_new( bless( {}, 'Test' ), { 'test' => 'test' }, [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new(bless({}, 'Test'), { 'test' => 'test' }, [])}
	);
	eval {
		$obj->build_new( bless( {}, 'Test' ), { 'test' => 'test' }, 'hypnos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new(bless({}, 'Test'), { 'test' => 'test' }, 'hypnos')}
	);
};
subtest 'after_class' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'after_class' );
	eval { $obj->after_class( [], { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->after_class([], { 'test' => 'test' })}
	);
	eval { $obj->after_class( 'hypnos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->after_class('hypnos', { 'test' => 'test' })}
	);
	eval { $obj->after_class( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->after_class(bless({}, 'Test'), [])}
	);
	eval { $obj->after_class( bless( {}, 'Test' ), 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->after_class(bless({}, 'Test'), 'gaudia')}
	);
};
subtest 'build_extends' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_extends' );
	eval { $obj->build_extends( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_extends([])} );
	eval { $obj->build_extends('penthos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_extends('penthos')}
	);
};
subtest 'build_before' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_before' );
	eval { $obj->build_before( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_before([])} );
	eval { $obj->build_before('algea') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_before('algea')}
	);
};
subtest 'build_has_keywords' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_has_keywords' );
	eval { $obj->build_has_keywords( {} ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has_keywords({})}
	);
	eval { $obj->build_has_keywords('penthos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has_keywords('penthos')}
	);
};
subtest 'build_clearer' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_clearer' );
};
subtest 'build_around' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_around' );
	eval { $obj->build_around( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_around([])} );
	eval { $obj->build_around('geras') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_around('geras')}
	);
};
subtest 'build_modify' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_modify' );
	eval { $obj->build_modify( [], 'penthos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify([], 'penthos', { 'test' => 'test' })}
	);
	eval { $obj->build_modify( 'hypnos', 'penthos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify('hypnos', 'penthos', { 'test' => 'test' })}
	);
	eval {
		$obj->build_modify( bless( {}, 'Test' ), [], { 'test' => 'test' } );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify(bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval {
		$obj->build_modify( bless( {}, 'Test' ), \1, { 'test' => 'test' } );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify(bless({}, 'Test'), \1, { 'test' => 'test' })}
	);
	eval { $obj->build_modify( bless( {}, 'Test' ), 'penthos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify(bless({}, 'Test'), 'penthos', [])}
	);
	eval { $obj->build_modify( bless( {}, 'Test' ), 'penthos', 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify(bless({}, 'Test'), 'penthos', 'curae')}
	);
};
subtest 'build_after' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_after' );
	eval { $obj->build_after( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_after([])} );
	eval { $obj->build_after('phobos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_after('phobos')}
	);
};
subtest 'build_has' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_has' );
	eval { $obj->build_has( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has([])} );
	eval { $obj->build_has('geras') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has('geras')} );
};
subtest 'build_accessor' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor' );
	eval { $obj->build_accessor( [], 'algea', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor([], 'algea', { 'test' => 'test' })}
	);
	eval { $obj->build_accessor( 'algea', 'algea', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor('algea', 'algea', { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor( bless( {}, 'Test' ), [], { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor(bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor( bless( {}, 'Test' ), \1, { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor(bless({}, 'Test'), \1, { 'test' => 'test' })}
	);
	eval { $obj->build_accessor( bless( {}, 'Test' ), 'algea', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor(bless({}, 'Test'), 'algea', [])}
	);
	eval { $obj->build_accessor( bless( {}, 'Test' ), 'algea', 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor(bless({}, 'Test'), 'algea', 'aporia')}
	);
};
subtest 'build_extends_keywords' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_extends_keywords' );
	eval { $obj->build_extends_keywords( {} ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_extends_keywords({})}
	);
	eval { $obj->build_extends_keywords('hypnos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_extends_keywords('hypnos')}
	);
};
subtest 'build_after_keywords' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_after_keywords' );
	eval { $obj->build_after_keywords( {} ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_after_keywords({})}
	);
	eval { $obj->build_after_keywords('hypnos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_after_keywords('hypnos')}
	);
};
subtest 'unique_types' => sub {
	plan tests => 5;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'unique_types' );
	eval { $obj->unique_types( \1, { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unique_types(\1, { 'test' => 'test' })}
	);
	eval { $obj->unique_types( 'nosoi', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unique_types('nosoi', [])}
	);
	eval { $obj->unique_types( 'nosoi', 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unique_types('nosoi', 'thanatos')}
	);
};
done_testing();
