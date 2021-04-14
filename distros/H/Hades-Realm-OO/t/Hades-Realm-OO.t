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
			{   is_role => 1,
				meta    => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				current_class => 'thanatos'
			}
		),
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role => [],
				meta    => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				current_class => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => [], meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role => {},
				meta    => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				current_class => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => {}, meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role => 1,
				meta    => {
					'aporia' =>
					    { types => [], attributes => { 'test' => 'test' } }
				},
				current_class => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => { 'aporia' => { types => [], attributes => { 'test' => 'test' } } }, current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role => 1,
				meta    => {
					'aporia' => {
						types      => 'thanatos',
						attributes => { 'test' => 'test' }
					}
				},
				current_class => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => { 'aporia' => { types => 'thanatos', attributes => { 'test' => 'test' } } }, current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role => 1,
				meta    => {
					'aporia' => {
						types      => undef,
						attributes => { 'test' => 'test' }
					}
				},
				current_class => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => { 'aporia' => { types => undef, attributes => { 'test' => 'test' } } }, current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role => 1,
				meta    => {
					'aporia' =>
					    { types => { 'test' => 'test' }, attributes => [] }
				},
				current_class => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => [] } }, current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role => 1,
				meta    => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => 'gaudia'
					}
				},
				current_class => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => 'gaudia' } }, current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role => 1,
				meta    => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => undef
					}
				},
				current_class => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => undef } }, current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				meta          => { 'aporia' => {} },
				current_class => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => { 'aporia' => {} }, current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				meta          => { 'aporia' => [] },
				current_class => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => { 'aporia' => [] }, current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				meta          => { 'aporia' => 'hypnos' },
				current_class => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => { 'aporia' => 'hypnos' }, current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				meta          => { 'aporia' => undef },
				current_class => 'thanatos'
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => { 'aporia' => undef }, current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{ is_role => 1, meta => [], current_class => 'thanatos' } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => [], current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{ is_role => 1, meta => 'penthos', current_class => 'thanatos' } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => 'penthos', current_class => 'thanatos' })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role => 1,
				meta    => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				current_class => []
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, current_class => [] })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role => 1,
				meta    => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				current_class => \1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, current_class => \1 })}
	);
};
subtest 'current_class' => sub {
	plan tests => 7;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'current_class' );
	is( $obj->current_class, undef, q{$obj->current_class} );
	is_deeply( $obj->current_class('hypnos'),
		'hypnos', q{$obj->current_class('hypnos')} );
	eval { $obj->current_class( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->current_class([])} );
	eval { $obj->current_class( \1 ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->current_class(\1)} );
	is_deeply( $obj->current_class, 'hypnos', q{$obj->current_class} );
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
			{   'curae' => {
					types      => { 'test' => 'test' },
					attributes => { 'test' => 'test' }
				}
			}
		),
		{   'curae' => {
				types      => { 'test' => 'test' },
				attributes => { 'test' => 'test' }
			}
		},
		q{$obj->meta({ 'curae' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'curae' => { types => [], attributes => { 'test' => 'test' } }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'curae' => { types => [], attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'curae' => {
					types      => 'thanatos',
					attributes => { 'test' => 'test' }
				}
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'curae' => { types => 'thanatos', attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'curae' =>
				    { types => undef, attributes => { 'test' => 'test' } }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'curae' => { types => undef, attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'curae' => { types => { 'test' => 'test' }, attributes => [] }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'curae' => { types => { 'test' => 'test' }, attributes => [] } })}
	);
	eval {
		$obj->meta(
			{   'curae' =>
				    { types => { 'test' => 'test' }, attributes => 'gaudia' }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'curae' => { types => { 'test' => 'test' }, attributes => 'gaudia' } })}
	);
	eval {
		$obj->meta(
			{   'curae' =>
				    { types => { 'test' => 'test' }, attributes => undef }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'curae' => { types => { 'test' => 'test' }, attributes => undef } })}
	);
	eval { $obj->meta( { 'curae' => {} } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'curae' => {} })}
	);
	eval { $obj->meta( { 'curae' => [] } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'curae' => [] })}
	);
	eval { $obj->meta( { 'curae' => 'penthos' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'curae' => 'penthos' })}
	);
	eval { $obj->meta( { 'curae' => undef } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'curae' => undef })}
	);
	eval { $obj->meta( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta([])} );
	eval { $obj->meta('aporia') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta('aporia')} );
	is_deeply(
		$obj->meta,
		{   'curae' => {
				types      => { 'test' => 'test' },
				attributes => { 'test' => 'test' }
			}
		},
		q{$obj->meta}
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
	eval { $obj->module_generate('thanatos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->module_generate('thanatos')}
	);
};
subtest 'build_class_inheritance' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_class_inheritance' );
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
			'penthos',
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new('penthos', { 'test' => 'test' }, { 'test' => 'test' })}
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
		$obj->build_new( bless( {}, 'Test' ), { 'test' => 'test' }, 'gaudia' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new(bless({}, 'Test'), { 'test' => 'test' }, 'gaudia')}
	);
};
subtest 'build_clearer' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_clearer' );
};
subtest 'build_predicate' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_predicate' );
};
subtest 'build_accessor_no_arguments' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor_no_arguments' );
	eval {
		$obj->build_accessor_no_arguments( [], ['test'],
			{ 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_no_arguments([], ['test'], { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor_no_arguments( 'geras', ['test'],
			{ 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_no_arguments('geras', ['test'], { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor_no_arguments( bless( {}, 'Test' ),
			{}, { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_no_arguments(bless({}, 'Test'), {}, { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor_no_arguments( bless( {}, 'Test' ),
			'nosoi', { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_no_arguments(bless({}, 'Test'), 'nosoi', { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor_no_arguments( bless( {}, 'Test' ), ['test'], [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_no_arguments(bless({}, 'Test'), ['test'], [])}
	);
	eval {
		$obj->build_accessor_no_arguments( bless( {}, 'Test' ),
			['test'], 'curae' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_no_arguments(bless({}, 'Test'), ['test'], 'curae')}
	);
};
subtest 'build_accessor' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor' );
	eval { $obj->build_accessor( [], 'limos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor([], 'limos', { 'test' => 'test' })}
	);
	eval { $obj->build_accessor( 'thanatos', 'limos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor('thanatos', 'limos', { 'test' => 'test' })}
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
	eval { $obj->build_accessor( bless( {}, 'Test' ), 'limos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor(bless({}, 'Test'), 'limos', [])}
	);
	eval { $obj->build_accessor( bless( {}, 'Test' ), 'limos', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor(bless({}, 'Test'), 'limos', 'hypnos')}
	);
};
subtest 'build_modify' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_modify' );
	eval { $obj->build_modify( [], 'thanatos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify([], 'thanatos', { 'test' => 'test' })}
	);
	eval { $obj->build_modify( 'algea', 'thanatos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify('algea', 'thanatos', { 'test' => 'test' })}
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
	eval { $obj->build_modify( bless( {}, 'Test' ), 'thanatos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify(bless({}, 'Test'), 'thanatos', [])}
	);
	eval { $obj->build_modify( bless( {}, 'Test' ), 'thanatos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify(bless({}, 'Test'), 'thanatos', 'nosoi')}
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
	eval { $obj->after_class( 'aporia', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->after_class('aporia', { 'test' => 'test' })}
	);
	eval { $obj->after_class( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->after_class(bless({}, 'Test'), [])}
	);
	eval { $obj->after_class( bless( {}, 'Test' ), 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->after_class(bless({}, 'Test'), 'penthos')}
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
	eval { $obj->unique_types( 'curae', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unique_types('curae', [])}
	);
	eval { $obj->unique_types( 'curae', 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unique_types('curae', 'penthos')}
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
	eval { $obj->build_as_class( 'curae', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_class('curae', { 'test' => 'test' })}
	);
	eval { $obj->build_as_class( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_class(bless({}, 'Test'), [])}
	);
	eval { $obj->build_as_class( bless( {}, 'Test' ), 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_class(bless({}, 'Test'), 'hypnos')}
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
	eval { $obj->build_as_role( 'algea', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_role('algea', { 'test' => 'test' })}
	);
	eval { $obj->build_as_role( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_role(bless({}, 'Test'), [])}
	);
	eval { $obj->build_as_role( bless( {}, 'Test' ), 'penthos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_role(bless({}, 'Test'), 'penthos')}
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
	eval { $obj->build_has_keywords('thanatos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has_keywords('thanatos')}
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
	eval { $obj->build_has('nosoi') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has('nosoi')} );
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
	eval { $obj->build_extends_keywords('curae') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_extends_keywords('curae')}
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
	eval { $obj->build_extends('nosoi') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_extends('nosoi')}
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
	eval { $obj->build_with_keywords('phobos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_with_keywords('phobos')}
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
	eval { $obj->build_with('hypnos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_with('hypnos')} );
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
	eval { $obj->build_requires_keywords('limos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_requires_keywords('limos')}
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
	eval { $obj->build_before_keywords('algea') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_before_keywords('algea')}
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
	eval { $obj->build_before('nosoi') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_before('nosoi')}
	);
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
	eval { $obj->build_around_keywords('thanatos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_around_keywords('thanatos')}
	);
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
	eval { $obj->build_around('aporia') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_around('aporia')}
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
	eval { $obj->build_after_keywords('thanatos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_after_keywords('thanatos')}
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
	eval { $obj->build_after('algea') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_after('algea')} );
};
subtest 'build_accessor_builder' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor_builder' );
	eval { $obj->build_accessor_builder( [], 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder([], 'curae')}
	);
	eval { $obj->build_accessor_builder( \1, 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder(\1, 'curae')}
	);
	eval { $obj->build_accessor_builder( 'nosoi', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder('nosoi', [])}
	);
	eval { $obj->build_accessor_builder( 'nosoi', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder('nosoi', \1)}
	);
};
subtest 'build_accessor_coerce' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor_coerce' );
	eval { $obj->build_accessor_coerce( [], 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_coerce([], 'algea')}
	);
	eval { $obj->build_accessor_coerce( \1, 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_coerce(\1, 'algea')}
	);
	eval { $obj->build_accessor_coerce( 'gaudia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_coerce('gaudia', [])}
	);
	eval { $obj->build_accessor_coerce( 'gaudia', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_coerce('gaudia', \1)}
	);
};
subtest 'build_accessor_trigger' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor_trigger' );
	eval { $obj->build_accessor_trigger( [], 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_trigger([], 'curae')}
	);
	eval { $obj->build_accessor_trigger( \1, 'curae' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_trigger(\1, 'curae')}
	);
	eval { $obj->build_accessor_trigger( 'curae', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_trigger('curae', [])}
	);
	eval { $obj->build_accessor_trigger( 'curae', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_trigger('curae', \1)}
	);
};
subtest 'build_accessor_default' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor_default' );
	eval { $obj->build_accessor_default( [], 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_default([], 'limos')}
	);
	eval { $obj->build_accessor_default( \1, 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_default(\1, 'limos')}
	);
	eval { $obj->build_accessor_default( 'curae', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_default('curae', [])}
	);
	eval { $obj->build_accessor_default( 'curae', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_default('curae', \1)}
	);
};
done_testing();
