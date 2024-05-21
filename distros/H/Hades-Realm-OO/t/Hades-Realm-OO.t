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
			{   is_role       => 1,
				current_class => 'phobos',
				meta          => {
					'thanatos' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				}
			}
		),
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => 'phobos', meta => { 'thanatos' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => [],
				current_class => 'phobos',
				meta          => {
					'thanatos' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				}
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => [], current_class => 'phobos', meta => { 'thanatos' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => {},
				current_class => 'phobos',
				meta          => {
					'thanatos' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				}
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => {}, current_class => 'phobos', meta => { 'thanatos' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				current_class => [],
				meta          => {
					'thanatos' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				}
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => [], meta => { 'thanatos' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				current_class => \1,
				meta          => {
					'thanatos' => {
						types      => { 'test' => 'test' },
						attributes => { 'test' => 'test' }
					}
				}
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => \1, meta => { 'thanatos' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				current_class => 'phobos',
				meta          => {
					'thanatos' =>
					    { types => [], attributes => { 'test' => 'test' } }
				}
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => 'phobos', meta => { 'thanatos' => { types => [], attributes => { 'test' => 'test' } } } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				current_class => 'phobos',
				meta          => {
					'thanatos' => {
						types      => 'limos',
						attributes => { 'test' => 'test' }
					}
				}
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => 'phobos', meta => { 'thanatos' => { types => 'limos', attributes => { 'test' => 'test' } } } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				current_class => 'phobos',
				meta          => {
					'thanatos' => {
						types      => undef,
						attributes => { 'test' => 'test' }
					}
				}
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => 'phobos', meta => { 'thanatos' => { types => undef, attributes => { 'test' => 'test' } } } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				current_class => 'phobos',
				meta          => {
					'thanatos' =>
					    { types => { 'test' => 'test' }, attributes => [] }
				}
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => 'phobos', meta => { 'thanatos' => { types => { 'test' => 'test' }, attributes => [] } } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				current_class => 'phobos',
				meta          => {
					'thanatos' => {
						types      => { 'test' => 'test' },
						attributes => 'penthos'
					}
				}
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => 'phobos', meta => { 'thanatos' => { types => { 'test' => 'test' }, attributes => 'penthos' } } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				current_class => 'phobos',
				meta          => {
					'thanatos' => {
						types      => { 'test' => 'test' },
						attributes => undef
					}
				}
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => 'phobos', meta => { 'thanatos' => { types => { 'test' => 'test' }, attributes => undef } } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				current_class => 'phobos',
				meta          => { 'thanatos' => {} }
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => 'phobos', meta => { 'thanatos' => {} } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				current_class => 'phobos',
				meta          => { 'thanatos' => [] }
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => 'phobos', meta => { 'thanatos' => [] } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				current_class => 'phobos',
				meta          => { 'thanatos' => 'penthos' }
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => 'phobos', meta => { 'thanatos' => 'penthos' } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{   is_role       => 1,
				current_class => 'phobos',
				meta          => { 'thanatos' => undef }
			}
		);
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => 'phobos', meta => { 'thanatos' => undef } })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{ is_role => 1, current_class => 'phobos', meta => [] } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => 'phobos', meta => [] })}
	);
	eval {
		$obj = Hades::Realm::OO->new(
			{ is_role => 1, current_class => 'phobos', meta => 'thanatos' } );
	};
	like( $@, qr/invalid|type|constraint|greater|atleast/i,
		q{$obj = Hades::Realm::OO->new({ is_role => 1, current_class => 'phobos', meta => 'thanatos' })}
	);
};
subtest 'current_class' => sub {
	plan tests => 7;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'current_class' );
	is( $obj->current_class, undef, q{$obj->current_class} );
	is_deeply( $obj->current_class('thanatos'),
		'thanatos', q{$obj->current_class('thanatos')} );
	eval { $obj->current_class( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->current_class([])} );
	eval { $obj->current_class( \1 ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->current_class(\1)} );
	is_deeply( $obj->current_class, 'thanatos', q{$obj->current_class} );
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
			{   'thanatos' => {
					types      => { 'test' => 'test' },
					attributes => { 'test' => 'test' }
				}
			}
		),
		{   'thanatos' => {
				types      => { 'test' => 'test' },
				attributes => { 'test' => 'test' }
			}
		},
		q{$obj->meta({ 'thanatos' => { types => { 'test' => 'test' }, attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'thanatos' =>
				    { types => [], attributes => { 'test' => 'test' } }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta({ 'thanatos' => { types => [], attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'thanatos' =>
				    { types => 'geras', attributes => { 'test' => 'test' } }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta({ 'thanatos' => { types => 'geras', attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'thanatos' =>
				    { types => undef, attributes => { 'test' => 'test' } }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta({ 'thanatos' => { types => undef, attributes => { 'test' => 'test' } } })}
	);
	eval {
		$obj->meta(
			{   'thanatos' =>
				    { types => { 'test' => 'test' }, attributes => [] }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta({ 'thanatos' => { types => { 'test' => 'test' }, attributes => [] } })}
	);
	eval {
		$obj->meta(
			{   'thanatos' =>
				    { types => { 'test' => 'test' }, attributes => 'curae' }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta({ 'thanatos' => { types => { 'test' => 'test' }, attributes => 'curae' } })}
	);
	eval {
		$obj->meta(
			{   'thanatos' =>
				    { types => { 'test' => 'test' }, attributes => undef }
			}
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta({ 'thanatos' => { types => { 'test' => 'test' }, attributes => undef } })}
	);
	eval { $obj->meta( { 'thanatos' => {} } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta({ 'thanatos' => {} })}
	);
	eval { $obj->meta( { 'thanatos' => [] } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta({ 'thanatos' => [] })}
	);
	eval { $obj->meta( { 'thanatos' => 'curae' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta({ 'thanatos' => 'curae' })}
	);
	eval { $obj->meta( { 'thanatos' => undef } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta({ 'thanatos' => undef })}
	);
	eval { $obj->meta( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta([])} );
	eval { $obj->meta('algea') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->meta('algea')} );
	is_deeply(
		$obj->meta,
		{   'thanatos' => {
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
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->is_role([])} );
	eval { $obj->is_role( {} ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
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
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->module_generate([])} );
	eval { $obj->module_generate('hypnos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->module_generate('hypnos')}
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_new([], { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval {
		$obj->build_new(
			'aporia',
			{ 'test' => 'test' },
			{ 'test' => 'test' }
		);
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_new('aporia', { 'test' => 'test' }, { 'test' => 'test' })}
	);
	eval { $obj->build_new( bless( {}, 'Test' ), [], { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_new(bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval {
		$obj->build_new( bless( {}, 'Test' ), 'nosoi', { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_new(bless({}, 'Test'), 'nosoi', { 'test' => 'test' })}
	);
	eval { $obj->build_new( bless( {}, 'Test' ), { 'test' => 'test' }, [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_new(bless({}, 'Test'), { 'test' => 'test' }, [])}
	);
	eval {
		$obj->build_new( bless( {}, 'Test' ), { 'test' => 'test' }, 'geras' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_new(bless({}, 'Test'), { 'test' => 'test' }, 'geras')}
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
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_no_arguments([], ['test'], { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor_no_arguments( 'algea', ['test'],
			{ 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_no_arguments('algea', ['test'], { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor_no_arguments( bless( {}, 'Test' ),
			{}, { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_no_arguments(bless({}, 'Test'), {}, { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor_no_arguments( bless( {}, 'Test' ),
			'curae', { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_no_arguments(bless({}, 'Test'), 'curae', { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor_no_arguments( bless( {}, 'Test' ), ['test'], [] );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_no_arguments(bless({}, 'Test'), ['test'], [])}
	);
	eval {
		$obj->build_accessor_no_arguments( bless( {}, 'Test' ),
			['test'], 'nosoi' );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_no_arguments(bless({}, 'Test'), ['test'], 'nosoi')}
	);
};
subtest 'build_accessor' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor' );
	eval { $obj->build_accessor( [], 'curae', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor([], 'curae', { 'test' => 'test' })}
	);
	eval { $obj->build_accessor( 'curae', 'curae', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor('curae', 'curae', { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor( bless( {}, 'Test' ), [], { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor(bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval {
		$obj->build_accessor( bless( {}, 'Test' ), \1, { 'test' => 'test' } );
	};
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor(bless({}, 'Test'), \1, { 'test' => 'test' })}
	);
	eval { $obj->build_accessor( bless( {}, 'Test' ), 'curae', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor(bless({}, 'Test'), 'curae', [])}
	);
	eval { $obj->build_accessor( bless( {}, 'Test' ), 'curae', 'limos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor(bless({}, 'Test'), 'curae', 'limos')}
	);
};
subtest 'build_sub' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_sub' );
	eval { $obj->build_sub( [], 'algea', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_sub([], 'algea', { 'test' => 'test' })}
	);
	eval { $obj->build_sub( 'aporia', 'algea', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_sub('aporia', 'algea', { 'test' => 'test' })}
	);
	eval { $obj->build_sub( bless( {}, 'Test' ), [], { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_sub(bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval { $obj->build_sub( bless( {}, 'Test' ), \1, { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_sub(bless({}, 'Test'), \1, { 'test' => 'test' })}
	);
	eval { $obj->build_sub( bless( {}, 'Test' ), 'algea', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_sub(bless({}, 'Test'), 'algea', [])}
	);
	eval { $obj->build_sub( bless( {}, 'Test' ), 'algea', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_sub(bless({}, 'Test'), 'algea', 'hypnos')}
	);
};
subtest 'build_modify' => sub {
	plan tests => 8;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_modify' );
	eval { $obj->build_modify( [], 'hypnos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_modify([], 'hypnos', { 'test' => 'test' })}
	);
	eval { $obj->build_modify( 'geras', 'hypnos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_modify('geras', 'hypnos', { 'test' => 'test' })}
	);
	eval {
		$obj->build_modify( bless( {}, 'Test' ), [], { 'test' => 'test' } );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_modify(bless({}, 'Test'), [], { 'test' => 'test' })}
	);
	eval {
		$obj->build_modify( bless( {}, 'Test' ), \1, { 'test' => 'test' } );
	};
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_modify(bless({}, 'Test'), \1, { 'test' => 'test' })}
	);
	eval { $obj->build_modify( bless( {}, 'Test' ), 'hypnos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_modify(bless({}, 'Test'), 'hypnos', [])}
	);
	eval { $obj->build_modify( bless( {}, 'Test' ), 'hypnos', 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_modify(bless({}, 'Test'), 'hypnos', 'algea')}
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->after_class([], { 'test' => 'test' })}
	);
	eval { $obj->after_class( 'limos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->after_class('limos', { 'test' => 'test' })}
	);
	eval { $obj->after_class( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->after_class(bless({}, 'Test'), [])}
	);
	eval { $obj->after_class( bless( {}, 'Test' ), 'algea' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->after_class(bless({}, 'Test'), 'algea')}
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->unique_types(\1, { 'test' => 'test' })}
	);
	eval { $obj->unique_types( 'aporia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->unique_types('aporia', [])}
	);
	eval { $obj->unique_types( 'aporia', 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->unique_types('aporia', 'hypnos')}
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_as_class([], { 'test' => 'test' })}
	);
	eval { $obj->build_as_class( 'phobos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_as_class('phobos', { 'test' => 'test' })}
	);
	eval { $obj->build_as_class( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_as_class(bless({}, 'Test'), [])}
	);
	eval { $obj->build_as_class( bless( {}, 'Test' ), 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_as_class(bless({}, 'Test'), 'phobos')}
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_as_role([], { 'test' => 'test' })}
	);
	eval { $obj->build_as_role( 'hypnos', { 'test' => 'test' } ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_as_role('hypnos', { 'test' => 'test' })}
	);
	eval { $obj->build_as_role( bless( {}, 'Test' ), [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_as_role(bless({}, 'Test'), [])}
	);
	eval { $obj->build_as_role( bless( {}, 'Test' ), 'hypnos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_as_role(bless({}, 'Test'), 'hypnos')}
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_has_keywords({})}
	);
	eval { $obj->build_has_keywords('limos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_has_keywords('limos')}
	);
};
subtest 'build_has' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_has' );
	eval { $obj->build_has( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_has([])} );
	eval { $obj->build_has('thanatos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_has('thanatos')}
	);
};
subtest 'build_function_keywords' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_function_keywords' );
	eval { $obj->build_function_keywords( {} ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_function_keywords({})}
	);
	eval { $obj->build_function_keywords('hypnos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_function_keywords('hypnos')}
	);
};
subtest 'build_function' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_function' );
	eval { $obj->build_function( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_function([])} );
	eval { $obj->build_function('gaudia') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_function('gaudia')}
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_extends_keywords({})}
	);
	eval { $obj->build_extends_keywords('limos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_extends_keywords('limos')}
	);
};
subtest 'build_extends' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_extends' );
	eval { $obj->build_extends( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_extends([])} );
	eval { $obj->build_extends('algea') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_extends('algea')}
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_with_keywords({})}
	);
	eval { $obj->build_with_keywords('gaudia') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_with_keywords('gaudia')}
	);
};
subtest 'build_with' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_with' );
	eval { $obj->build_with( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_with([])} );
	eval { $obj->build_with('nosoi') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_with('nosoi')} );
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_requires_keywords({})}
	);
	eval { $obj->build_requires_keywords('phobos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_requires_keywords('phobos')}
	);
};
subtest 'build_requires' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_requires' );
	eval { $obj->build_requires( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_requires([])} );
	eval { $obj->build_requires('penthos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_requires('penthos')}
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_before_keywords({})}
	);
	eval { $obj->build_before_keywords('phobos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_before_keywords('phobos')}
	);
};
subtest 'build_before' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_before' );
	eval { $obj->build_before( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_before([])} );
	eval { $obj->build_before('aporia') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_before('aporia')}
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_around_keywords({})}
	);
	eval { $obj->build_around_keywords('aporia') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_around_keywords('aporia')}
	);
};
subtest 'build_around' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_around' );
	eval { $obj->build_around( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_around([])} );
	eval { $obj->build_around('hypnos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_around('hypnos')}
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
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_after_keywords({})}
	);
	eval { $obj->build_after_keywords('phobos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_after_keywords('phobos')}
	);
};
subtest 'build_after' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_after' );
	eval { $obj->build_after( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_after([])} );
	eval { $obj->build_after('aporia') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_after('aporia')}
	);
};
subtest 'build_accessor_builder' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor_builder' );
	eval { $obj->build_accessor_builder( [], 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder([], 'gaudia')}
	);
	eval { $obj->build_accessor_builder( \1, 'gaudia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder(\1, 'gaudia')}
	);
	eval { $obj->build_accessor_builder( 'geras', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder('geras', [])}
	);
	eval { $obj->build_accessor_builder( 'geras', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_builder('geras', \1)}
	);
};
subtest 'build_accessor_coerce' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor_coerce' );
	eval { $obj->build_accessor_coerce( [], 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_coerce([], 'geras')}
	);
	eval { $obj->build_accessor_coerce( \1, 'geras' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_coerce(\1, 'geras')}
	);
	eval { $obj->build_accessor_coerce( 'aporia', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_coerce('aporia', [])}
	);
	eval { $obj->build_accessor_coerce( 'aporia', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_coerce('aporia', \1)}
	);
};
subtest 'build_accessor_trigger' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor_trigger' );
	eval { $obj->build_accessor_trigger( [], 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_trigger([], 'thanatos')}
	);
	eval { $obj->build_accessor_trigger( \1, 'thanatos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_trigger(\1, 'thanatos')}
	);
	eval { $obj->build_accessor_trigger( 'phobos', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_trigger('phobos', [])}
	);
	eval { $obj->build_accessor_trigger( 'phobos', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_trigger('phobos', \1)}
	);
};
subtest 'build_accessor_default' => sub {
	plan tests => 6;
	ok( my $obj = Hades::Realm::OO->new( {} ),
		q{my $obj = Hades::Realm::OO->new({})}
	);
	can_ok( $obj, 'build_accessor_default' );
	eval { $obj->build_accessor_default( [], 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_default([], 'aporia')}
	);
	eval { $obj->build_accessor_default( \1, 'aporia' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_default(\1, 'aporia')}
	);
	eval { $obj->build_accessor_default( 'algea', [] ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_default('algea', [])}
	);
	eval { $obj->build_accessor_default( 'algea', \1 ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->build_accessor_default('algea', \1)}
	);
};
done_testing();
