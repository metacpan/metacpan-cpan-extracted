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
			{   current_class => 'geras',
				meta          => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				is_role => 1
			}
		),
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => [],
				meta          => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				is_role => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => [], meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => \1,
				meta          => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				is_role => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => \1, meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => 'geras',
				meta          => {
					'aporia' =>
					    { types => [], attributes => { 'test' => 'test' } }
				},
				is_role => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => { 'aporia' => { types => [], attributes => { 'test' => 'test' } } }, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => 'geras',
				meta          => {
					'aporia' => {
						types      => 'geras',
						attributes => { 'test' => 'test' }
					}
				},
				is_role => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => { 'aporia' => { types => 'geras', attributes => { 'test' => 'test' } } }, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => 'geras',
				meta          => {
					'aporia' => {
						types      => undef,
						attributes => { 'test' => 'test' }
					}
				},
				is_role => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => { 'aporia' => { types => undef, attributes => { 'test' => 'test' } } }, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => 'geras',
				meta          => {
					'aporia' =>
					    { types => { 'test' => 'test' }, attributes => [] }
				},
				is_role => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => [] } }, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => 'geras',
				meta          => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => 'geras'
					}
				},
				is_role => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => 'geras' } }, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => 'geras',
				meta          => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => undef
					}
				},
				is_role => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => undef } }, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => 'geras',
				meta          => { 'aporia' => {} },
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => { 'aporia' => {} }, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => 'geras',
				meta          => { 'aporia' => [] },
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => { 'aporia' => [] }, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => 'geras',
				meta          => { 'aporia' => 'thanatos' },
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => { 'aporia' => 'thanatos' }, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => 'geras',
				meta          => { 'aporia' => undef },
				is_role       => 1
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => { 'aporia' => undef }, is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{ current_class => 'geras', meta => [], is_role => 1 } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => [], is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{ current_class => 'geras', meta => 'curae', is_role => 1 } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => 'curae', is_role => 1 })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => 'geras',
				meta          => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				is_role => []
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, is_role => [] })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   current_class => 'geras',
				meta          => {
					'aporia' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				},
				is_role => {}
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Hades::Realm::OO->new({ current_class => 'geras', meta => { 'aporia' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } }, is_role => {} })}
	);
};
subtest 'current_class' => sub {
	plan tests => 7;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'current_class' );
	is( $obj->current_class, undef, q{$obj->current_class} );
	is_deeply( $obj->current_class('phobos'),
		'phobos', q{$obj->current_class('phobos')} );
	eval { $obj->current_class( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->current_class([])} );
	eval { $obj->current_class( \1 ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->current_class(\1)} );
	is_deeply( $obj->current_class, 'phobos', q{$obj->current_class} );
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
			{   'nosoi' => {
					types      => { 'test' => 'test' },
					attributes => { 'test' => 'test' }
				}
			}
		),
		{   'nosoi' => {
				types      => { 'test' => 'test' },
				attributes => { 'test' => 'test' }
			}
		},
		q{$obj->meta({ 'nosoi' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'nosoi' => { types => [], attributes => { 'test' => 'test' } }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'nosoi' => { types => [], attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'nosoi' =>
				    { types => 'nosoi', attributes => { 'test' => 'test' } }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'nosoi' => { types => 'nosoi', attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'nosoi' =>
				    { types => undef, attributes => { 'test' => 'test' } }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'nosoi' => { types => undef, attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'nosoi' => { types => { 'test' => 'test' }, attributes => [] }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'nosoi' => { types => { 'test' => 'test' }, attributes => [] } })}
	);
	eval {
		$obj->meta(
			{   'nosoi' =>
				    { types => { 'test' => 'test' }, attributes => 'hypnos' }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'nosoi' => { types => { 'test' => 'test' }, attributes => 'hypnos' } })}
	);
	eval {
		$obj->meta(
			{   'nosoi' =>
				    { types => { 'test' => 'test' }, attributes => undef }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'nosoi' => { types => { 'test' => 'test' }, attributes => undef } })}
	);
	eval { $obj->meta( { 'nosoi' => {} } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'nosoi' => {} })}
	);
	eval { $obj->meta( { 'nosoi' => [] } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'nosoi' => [] })}
	);
	eval { $obj->meta( { 'nosoi' => 'aporia' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'nosoi' => 'aporia' })}
	);
	eval { $obj->meta( { 'nosoi' => undef } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta({ 'nosoi' => undef })}
	);
	eval { $obj->meta( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta([])} );
	eval { $obj->meta('phobos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta('phobos')} );
	is_deeply(
		$obj->meta,
		{   'nosoi' => {
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
	eval { $obj->module_generate('nosoi') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->module_generate('nosoi')}
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
		$obj->build_new( 'nosoi', { 'test' => 'test' }, { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new('nosoi', { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval { $obj->build_new( bless( {}, 'Test' ), [], { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new(bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval {
		$obj->build_new( bless( {}, 'Test' ), 'limos', { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_new(bless({}, 'Test'), 'limos', { 'test' => 'test' })}
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
		$obj->build_accessor_no_arguments( 'nosoi', ['test'],
			{ 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_no_arguments('nosoi', ['test'], { 'test' => 'test' })}
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
			'limos', { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_no_arguments(bless({}, 'Test'), 'limos', { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor_no_arguments( bless( {}, 'Test' ), ['test'], [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_no_arguments(bless({}, 'Test'), ['test'], [])}
	);
	eval {
		$obj->build_accessor_no_arguments( bless( {}, 'Test' ),
			['test'], 'hypnos' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_no_arguments(bless({}, 'Test'), ['test'], 'hypnos')}
	);
};
subtest 'build_accessor' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor' );
	eval { $obj->build_accessor( [], 'thanatos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor([], 'thanatos', { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor( 'phobos', 'thanatos', { 'test' => 'test' } );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor('phobos', 'thanatos', { 'test' => 'test' })}
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
	eval { $obj->build_accessor( bless( {}, 'Test' ), 'thanatos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor(bless({}, 'Test'), 'thanatos', [])}
	);
	eval { $obj->build_accessor( bless( {}, 'Test' ), 'thanatos', 'nosoi' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor(bless({}, 'Test'), 'thanatos', 'nosoi')}
	);
};
subtest 'build_modify' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_modify' );
	eval { $obj->build_modify( [], 'limos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify([], 'limos', { 'test' => 'test' })}
	);
	eval { $obj->build_modify( 'hypnos', 'limos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify('hypnos', 'limos', { 'test' => 'test' })}
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
	eval { $obj->build_modify( bless( {}, 'Test' ), 'limos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify(bless({}, 'Test'), 'limos', [])}
	);
	eval { $obj->build_modify( bless( {}, 'Test' ), 'limos', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_modify(bless({}, 'Test'), 'limos', 'geras')}
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
	eval { $obj->after_class( 'nosoi', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->after_class('nosoi', { 'test' => 'test' })}
	);
	eval { $obj->after_class( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->after_class(bless({}, 'Test'), [])}
	);
	eval { $obj->after_class( bless( {}, 'Test' ), 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->after_class(bless({}, 'Test'), 'aporia')}
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
	eval { $obj->unique_types( 'curae', 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->unique_types('curae', 'geras')}
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
	eval { $obj->build_as_class( 'aporia', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_class('aporia', { 'test' => 'test' })}
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
	eval { $obj->build_as_role( 'nosoi', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_as_role('nosoi', { 'test' => 'test' })}
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
	eval { $obj->build_has_keywords('nosoi') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has_keywords('nosoi')}
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
	eval { $obj->build_has('thanatos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_has('thanatos')}
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
	eval { $obj->build_extends_keywords('penthos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_extends_keywords('penthos')}
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
	eval { $obj->build_extends('limos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_extends('limos')}
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
	eval { $obj->build_with_keywords('aporia') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_with_keywords('aporia')}
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
	eval { $obj->build_with('algea') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_with('algea')} );
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
	eval { $obj->build_requires_keywords('penthos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_requires_keywords('penthos')}
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
	eval { $obj->build_requires('hypnos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_requires('hypnos')}
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
	eval { $obj->build_before_keywords('hypnos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_before_keywords('hypnos')}
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
	eval { $obj->build_before('thanatos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_before('thanatos')}
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
	eval { $obj->build_around_keywords('phobos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_around_keywords('phobos')}
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
	eval { $obj->build_around('penthos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_around('penthos')}
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
	eval { $obj->build_after_keywords('limos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_after_keywords('limos')}
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
	eval { $obj->build_after('geras') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_after('geras')} );
};
subtest 'build_accessor_builder' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor_builder' );
	eval { $obj->build_accessor_builder( [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder([], 'phobos')}
	);
	eval { $obj->build_accessor_builder( \1, 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_builder(\1, 'phobos')}
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
	eval { $obj->build_accessor_coerce( [], 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_coerce([], 'gaudia')}
	);
	eval { $obj->build_accessor_coerce( \1, 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_coerce(\1, 'gaudia')}
	);
	eval { $obj->build_accessor_coerce( 'hypnos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_coerce('hypnos', [])}
	);
	eval { $obj->build_accessor_coerce( 'hypnos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_coerce('hypnos', \1)}
	);
};
subtest 'build_accessor_trigger' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor_trigger' );
	eval { $obj->build_accessor_trigger( [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_trigger([], 'geras')}
	);
	eval { $obj->build_accessor_trigger( \1, 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_trigger(\1, 'geras')}
	);
	eval { $obj->build_accessor_trigger( 'limos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_trigger('limos', [])}
	);
	eval { $obj->build_accessor_trigger( 'limos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_trigger('limos', \1)}
	);
};
subtest 'build_accessor_default' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor_default' );
	eval { $obj->build_accessor_default( [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_default([], 'geras')}
	);
	eval { $obj->build_accessor_default( \1, 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_default(\1, 'geras')}
	);
	eval { $obj->build_accessor_default( 'penthos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_default('penthos', [])}
	);
	eval { $obj->build_accessor_default( 'penthos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->build_accessor_default('penthos', \1)}
	);
};
done_testing();
