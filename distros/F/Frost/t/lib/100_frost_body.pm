package main;

use Test::More;

BEGIN
{
	if ( $::MAKE_MUTABLE )
	{
		plan skip_all => 'make_mutable is VERBOTEN';
	}
	else
	{
#		plan tests => 216;
		plan tests => 214;
#		plan 'no_plan';
	}
}

our $ASYL;

{
	package Frost::Asylum;

	#	Cheap asylum...
	#
	use Moose;

	has DATA	=> ( is => 'rw', isa => 'HashRef', default => sub { {} } );

	sub _exists
	{
		my ( $self, $class, $id, $slot_name )	= @_;

		$slot_name	||= 'id';

		::IS_DEBUG and ::DEBUG ::Dump [ $self, $class, $id, $slot_name, $self->DATA ],[qw ( self class id slot_name DATA )];

		$self->DATA->{$class}			||= {};
		$self->DATA->{$class}->{$id}	||= {};

		exists $self->DATA->{$class}->{$id}->{$slot_name};
	}

	sub _silence
	{
		my ( $self, $class, $id, $slot_name, $value )	= @_;

		( defined $slot_name )					or die 'Param class missing';

		::IS_DEBUG and ::DEBUG ::Dump [ $self, $class, $id, $slot_name, $value, $self->DATA ],[qw ( self class id slot_name value DATA )];

		$self->DATA->{$class}			||= {};
		$self->DATA->{$class}->{$id}	||= {};

		$self->DATA->{$class}->{$id}->{$slot_name}	= $value;
	};

	sub _evoke
	{
		my ( $self, $class, $id, $slot_name )	= @_;

		$slot_name	||= 'id';

		::IS_DEBUG and ::DEBUG ::Dump [ $self, $class, $id, $slot_name, $self->DATA ],[qw ( self class id slot_name DATA )];

		$self->DATA->{$class}			||= {};
		$self->DATA->{$class}->{$id}	||= {};

		$self->DATA->{$class}->{$id}->{$slot_name};
	};


	no Moose;

	if ( $::MAKE_MUTABLE )	{ __PACKAGE__->meta->make_mutable();	}
	else							{ __PACKAGE__->meta->make_immutable();	}
}

{
	package My::Asylum;

	use Moose;
	extends 'Frost::Asylum';

	no Moose;

	if ( $::MAKE_MUTABLE )	{ __PACKAGE__->meta->make_mutable();	}
	else							{ __PACKAGE__->meta->make_immutable();	}
}

{
	package Existing::Class;

	use Moose;

	no Moose;

	if ( $::MAKE_MUTABLE )	{ __PACKAGE__->meta->make_mutable();	}
	else							{ __PACKAGE__->meta->make_immutable();	}
}

{
	package Bad::Bank;

	use Frost;
	use Frost::Util;

	my ( $text, $regex, $name );

	$name	= 'id';

	foreach my $feature ( qw( index derived virtual transient ) )
	{
		$text		= "Attribute $name can not be $feature";
		$regex	= qr/$text/;
		::throws_ok{ has $name			=> ( $feature => true )	} $regex, "Error: $text";
		::throws_ok{ has '+' . $name	=> ( $feature => true )	} $regex, "Error: $text [+]";
	}

	$text		= 'Illegal inherited options => \(is\)';
	$regex	= qr/$text/;
	$text		=~ s/\\//g;
	::throws_ok{ has $name			=> ( is => 'ro'	) } $regex, "Error: ro   $text";
	::throws_ok{ has $name			=> ( is => 'rw'	) } $regex, "Error: rw   $text";
	::throws_ok{ has $name			=> ( is => 'bare'	) } $regex, "Error: bare $text";
	::throws_ok{ has '+' . $name	=> ( is => 'ro'	) } $regex, "Error: ro   $text [+]";
	::throws_ok{ has '+' . $name	=> ( is => 'rw'	) } $regex, "Error: rw   $text [+]";
	::throws_ok{ has '+' . $name	=> ( is => 'bare'	) } $regex, "Error: bare $text [+]";

	$text		= 'Illegal inherited options => \(required\)';
	$regex	= qr/$text/;
	$text		=~ s/\\//g;
	::throws_ok{ has $name			=> ( required => true,	) } $regex, "Error: true  $text";
	::throws_ok{ has '+' . $name	=> ( required => true,	) } $regex, "Error: true  $text [+]";

	::throws_ok{ has $name			=> ( required => false,	) } $regex, "Error: false $text";
	::throws_ok{ has '+' . $name	=> ( required => false,	) } $regex, "Error: false $text [+]";

	foreach my $feature ( undef, '', 'uniqueid',		#	Frost::UniqueId...
		qw(
			Any
			Item
				Bool
				Undef
				Defined
					Value
					Ref
						ScalarRef
						ArrayRef
						HashRef
						CodeRef
						RegexpRef
						GlobRef
							FileHandle
						Object
		)
	)
	{
		$text		= "Attribute \\+\?$name\'s isa => '" . ( defined $feature ? $feature : 'undef' ) . "'...";
		$regex	= qr/$text/i;
		$text		=~ s/\+\?//g;
		$text		=~ s/\\//g;
		::throws_ok{ has $name			=> ( isa => $feature ) } $regex, "Error: $text";
		::throws_ok{ has '+' . $name	=> ( isa => $feature ) } $regex, "Error: $text [+]";
	}

#	foreach $name ( qw( asylum _status _dirty real_class ) )
	foreach $name ( qw( asylum _status _dirty ) )
	{
		$text		= "Attribute $name redefined";
		$regex	= qr/$text/;
		::throws_ok{ has $name			=> ( transient => true,	isa => 'My::Asylum' )	} $regex, "Error: $text";
		::throws_ok{ has '+' . $name	=> ( transient => true,	isa => 'My::Asylum' )	} $regex, "Error: $text [+]";
	}

	::throws_ok { has error_1				=> ( derived => true,	is => 'rw',	);	}
	qr/Derived attribute error_1 is read-only by default/,	'Error: virtual + rw';

	::throws_ok { has error_2				=> ( derived => true,	virtual => true,	);	}
	qr/Attribute error_2 can only be derived or virtual/,		'Error: derived + virtual';

	::throws_ok { has error_3				=> ( derived => true,	init_arg => 'error'	);	}
	qr/Derived attribute error_3 can not have an init_arg/,	'Error: derived + init_arg';

	::throws_ok { has error_4				=> ( virtual => true, is => 'bare'	);	}
	qr/Attribute error_4 must have at least a read-only accessor/,					'Error: virtual + bare';

	::throws_ok { has error_5				=> ( transient => true, is => 'bare'	);	}
	qr/Attribute error_5 must have at least a read-only accessor/,				'Error: transient + bare';

	::throws_ok { has error_6				=> ( derived => true,	index => true,	);	}
	qr/Derived attribute error_6 can not be indexed/,		'Error: derived + index';

	::throws_ok { has error_7				=> ( virtual => true,	index => true,	);	}
	qr/Virtual attribute error_7 can not be indexed/,		'Error: virtual + index';

	::throws_ok { has error_8				=> ( transient => true,	index => true,	);	}
	qr/Transient attribute error_8 can not be indexed/,		'Error: transient + index';

	::throws_ok { has error_9				=> ( index => 'foo', isa => 'Int'	);	}
	qr/I do not understand this option \(index => foo\) on attribute \(error_9\)/,				'Error: index => foo';

	::throws_ok { has error_10				=> ( index => true,		isa => 'HashRef'	);	}
	qr/Indexed attribute error_10\'s isa => 'HashRef' does not inherit from 'Num', 'Str' or 'Frost::UniqueId'/,	'Error: index + isa => HashRef';

	::throws_ok { has error_11				=> ( index => true	);	}
	qr/Indexed attribute error_11\'s isa => 'undef' does not inherit from 'Num', 'Str' or 'Frost::UniqueId'/,		'Error: index + no isa';

	::throws_ok { has error_12				=> ( index => true, isa => 'Int',	is => 'bare'	);	}
	qr/Attribute error_12 must have at least a read-only accessor/,				'Error: index + bare';
}

{
	package Foo;

	use Frost;
	use Frost::Util;

	has foo_normal			=> ( 							isa => 'Str',	is => 'rw'	);
	has foo_transient_rw	=> ( transient => true,	isa => 'Str',	is => 'rw'	);
	has foo_transient_ro	=> ( transient => true,	isa => 'Str',					);
	has foo_virtual_rw	=> ( virtual => true,	isa => 'Str',	is => 'rw'	);
	has foo_virtual_ro	=> ( virtual => true,	isa => 'Str',					);
	has foo_derived		=> ( derived => true,	isa => 'Str',					);
	has foo_derived_def	=> ( derived => true,	isa => 'Str',	default => 'FOO_DEFAULT'	);

	sub _build_foo_derived { 'FOO_BUILD' }

	no Frost;

	if ( $::MAKE_MUTABLE )	{ __PACKAGE__->meta->make_mutable();	}
	else							{ __PACKAGE__->meta->make_immutable();	}
}

{
	package Bar;

	use Moose;
	extends 'Foo';

	use Frost::Util;

	has bar_normal			=> ( 							isa => 'Str',	is => 'rw'	);
	has bar_transient_rw	=> ( transient => true,	isa => 'Str',	is => 'rw'	);
	has bar_transient_ro	=> ( transient => true,	isa => 'Str',					);
	has bar_virtual_rw	=> ( virtual => true,	isa => 'Str',	is => 'rw'	);
	has bar_virtual_ro	=> ( virtual => true,	isa => 'Str',					);
	has bar_derived		=> ( derived => true,	isa => 'Str',					);
	has bar_derived_def	=> ( derived => true,	isa => 'Str',	default => 'BAR_DEFAULT'	);

	#	no _build_bar_derived !!!

	no Moose;

	if ( $::MAKE_MUTABLE )	{ __PACKAGE__->meta->make_mutable();	}
	else							{ __PACKAGE__->meta->make_immutable();	}
}

ok( Foo->meta()->meta()->does_role ( 'Frost::Meta::Class' ),
	'apply Frost::Meta::Class        to Foo->meta()´s metaclass' );
ok( Foo->meta()->attribute_metaclass()->meta()->does_role ( 'Frost::Meta::Attribute' ),
	'apply Frost::Meta::Attribute    to Foo->meta()´s attribute metaclass' );
ok( Foo->meta()->instance_metaclass()->meta()->does_role ( 'Frost::Meta::Instance' ),
	'apply Frost::Meta::Instance     to Foo->meta()´s instance metaclass' );
ok( Foo->meta()->constructor_class()->meta()->does_role ( 'Frost::Meta::Constructor' ),
	'apply Frost::Meta::Constructor  to Foo->meta()´s constructor metaclass' );

ok( Bar->meta()->meta()->does_role ( 'Frost::Meta::Class' ),
	'apply Frost::Meta::Class        to Bar->meta()´s metaclass' );
ok( Bar->meta()->attribute_metaclass()->meta()->does_role ( 'Frost::Meta::Attribute' ),
	'apply Frost::Meta::Attribute    to Bar->meta()´s attribute metaclass' );
ok( Bar->meta()->instance_metaclass()->meta()->does_role ( 'Frost::Meta::Instance' ),
	'apply Frost::Meta::Instance     to Bar->meta()´s instance metaclass' );
ok( Bar->meta()->constructor_class()->meta()->does_role ( 'Frost::Meta::Constructor' ),
	'apply Frost::Meta::Constructor  to Bar->meta()´s constructor metaclass' );

lives_ok		{ $ASYL	= My::Asylum->new(); }	'My asylum constructed';

my ( $foo, $bar );

lives_ok		{ $foo	= Foo->new ( id => 'FOO', asylum => $ASYL );	}	'Foo->new accepts derived Asylum';
lives_ok		{ $bar	= Bar->new ( id => 'BAR', asylum => $ASYL	);	}	'Bar->new accepts derived Asylum';

diag "\nASYL is "	. ( $ASYL->meta->is_mutable	? 'mutable' : 'IMMUTABLE' );
diag 'foo  is '	. ( $foo->meta->is_mutable		? 'mutable' : 'IMMUTABLE' );
diag 'bar  is '	. ( $bar->meta->is_mutable		? 'mutable' : 'IMMUTABLE' );

isa_ok	( $foo, 'Foo', 'foo' );
ISA_NOT	( $foo, 'Frost', 'foo' );
isa_ok	( $foo, 'Frost::Locum', 'foo' );
ISA_NOT	( $foo, 'Frost::Nucleus', 'foo' );			#	importer
ISA_NOT	( $foo, 'Frost::Role::Nucleus', 'foo' );	#	role
isa_ok	( $foo, 'Moose::Object', 'foo' );

isa_ok	( $bar, 'Bar', 'bar' );
isa_ok	( $bar, 'Foo', 'bar' );
ISA_NOT	( $bar, 'Frost', 'bar' );
isa_ok	( $bar, 'Frost::Locum', 'bar' );
ISA_NOT	( $bar, 'Frost::Nucleus', 'bar' );			#	importer
ISA_NOT	( $bar, 'Frost::Role::Nucleus', 'bar' );	#	role
isa_ok	( $bar, 'Moose::Object', 'bar' );

isa_ok	( $foo->asylum, 'My::Asylum', 'foo->asylum' );
isa_ok	( $foo->asylum, 'Frost::Asylum', 'foo->asylum' );
isa_ok	( $bar->asylum, 'My::Asylum', 'bar->asylum' );
isa_ok	( $bar->asylum, 'Frost::Asylum', 'bar->asylum' );

is ( $foo->foo_derived,			'FOO_BUILD',	'got right foo->foo_derived' );
is ( $foo->foo_derived_def,	'FOO_DEFAULT',	'got right foo->foo_derived_def' );

is ( $bar->foo_derived,			'FOO_BUILD',	'got right bar->foo_derived' );
is ( $bar->foo_derived_def,	'FOO_DEFAULT',	'got right bar->foo_derived_def' );

throws_ok	{ $bar->bar_derived eq 'BAR_BUILD' }
qr/Bar does not support builder method '_build_bar_derived' for attribute 'bar_derived'/,
'No builder defined for bar->bar_derived';

is ( $bar->bar_derived_def,	'BAR_DEFAULT',	'got right bar->bar_derived_def' );

foreach my $obj ( $foo, $bar )
{
	test_attr ( $obj,	'foo_transient_rw',	'is_transient',	true	);
	test_attr ( $obj,	'foo_transient_rw',	'is_virtual',		false	);
	test_attr ( $obj,	'foo_transient_rw',	'is_derived',		false	);
	test_attr ( $obj,	'foo_transient_rw',	'is_readonly',		false	);
	test_attr ( $obj,	'foo_transient_rw',	'_is_metadata',	'rw'	);
	test_attr ( $obj,	'foo_transient_rw',	'is_lazy_build',	undef	);

	test_attr ( $obj,	'foo_transient_ro',	'is_transient',	true	);
	test_attr ( $obj,	'foo_transient_ro',	'is_virtual',		false	);
	test_attr ( $obj,	'foo_transient_ro',	'is_derived',		false	);
	test_attr ( $obj,	'foo_transient_ro',	'is_readonly',		true	);
	test_attr ( $obj,	'foo_transient_ro',	'_is_metadata',	'ro'	);
	test_attr ( $obj,	'foo_transient_ro',	'is_lazy_build',	undef	);

	test_attr ( $obj,	'foo_virtual_rw',		'is_transient',	false	);
	test_attr ( $obj,	'foo_virtual_rw',		'is_virtual',		true	);
	test_attr ( $obj,	'foo_virtual_rw',		'is_derived',		false	);
	test_attr ( $obj,	'foo_virtual_rw',		'is_readonly',		false	);
	test_attr ( $obj,	'foo_virtual_rw',		'_is_metadata',	'rw'	);
	test_attr ( $obj,	'foo_virtual_rw',		'is_lazy_build',	undef	);

	test_attr ( $obj,	'foo_virtual_ro',		'is_transient',	false	);
	test_attr ( $obj,	'foo_virtual_ro',		'is_virtual',		true	);
	test_attr ( $obj,	'foo_virtual_ro',		'is_derived',		false	);
	test_attr ( $obj,	'foo_virtual_ro',		'is_readonly',		true	);
	test_attr ( $obj,	'foo_virtual_ro',		'_is_metadata',	'ro'	);
	test_attr ( $obj,	'foo_virtual_ro',		'is_lazy_build',	undef	);

	test_attr ( $obj,	'foo_derived',			'is_transient',	false	);
	test_attr ( $obj,	'foo_derived',			'is_virtual',		true	);
	test_attr ( $obj,	'foo_derived',			'is_derived',		true	);
	test_attr ( $obj,	'foo_derived',			'is_readonly',		true	);
	test_attr ( $obj,	'foo_derived',			'_is_metadata',	'ro'	);
	test_attr ( $obj,	'foo_derived',			'is_lazy_build',	true	);

	test_attr ( $obj,	'foo_derived_def',	'is_transient',	false	);
	test_attr ( $obj,	'foo_derived_def',	'is_virtual',		true	);
	test_attr ( $obj,	'foo_derived_def',	'is_derived',		true	);
	test_attr ( $obj,	'foo_derived_def',	'is_readonly',		true	);
	test_attr ( $obj,	'foo_derived_def',	'_is_metadata',	'ro'	);
	test_attr ( $obj,	'foo_derived_def',	'is_lazy_build',	undef	);
}

{
	test_attr ( $bar,	'bar_transient_rw',	'is_transient',	true	);
	test_attr ( $bar,	'bar_transient_rw',	'is_virtual',		false	);
	test_attr ( $bar,	'bar_transient_rw',	'is_derived',		false	);
	test_attr ( $bar,	'bar_transient_rw',	'is_readonly',		false	);
	test_attr ( $bar,	'bar_transient_rw',	'_is_metadata',	'rw'	);
	test_attr ( $bar,	'bar_transient_rw',	'is_lazy_build',	undef	);

	test_attr ( $bar,	'bar_transient_ro',	'is_transient',	true	);
	test_attr ( $bar,	'bar_transient_ro',	'is_virtual',		false	);
	test_attr ( $bar,	'bar_transient_ro',	'is_derived',		false	);
	test_attr ( $bar,	'bar_transient_ro',	'is_readonly',		true	);
	test_attr ( $bar,	'bar_transient_ro',	'_is_metadata',	'ro'	);
	test_attr ( $bar,	'bar_transient_ro',	'is_lazy_build',	undef	);

	test_attr ( $bar,	'bar_virtual_rw',		'is_transient',	false	);
	test_attr ( $bar,	'bar_virtual_rw',		'is_virtual',		true	);
	test_attr ( $bar,	'bar_virtual_rw',		'is_derived',		false	);
	test_attr ( $bar,	'bar_virtual_rw',		'is_readonly',		false	);
	test_attr ( $bar,	'bar_virtual_rw',		'_is_metadata',	'rw'	);
	test_attr ( $bar,	'bar_virtual_rw',		'is_lazy_build',	undef	);

	test_attr ( $bar,	'bar_virtual_ro',		'is_transient',	false	);
	test_attr ( $bar,	'bar_virtual_ro',		'is_virtual',		true	);
	test_attr ( $bar,	'bar_virtual_ro',		'is_derived',		false	);
	test_attr ( $bar,	'bar_virtual_ro',		'is_readonly',		true	);
	test_attr ( $bar,	'bar_virtual_ro',		'_is_metadata',	'ro'	);
	test_attr ( $bar,	'bar_virtual_ro',		'is_lazy_build',	undef	);

	test_attr ( $bar,	'bar_derived',			'is_transient',	false	);
	test_attr ( $bar,	'bar_derived',			'is_virtual',		true	);
	test_attr ( $bar,	'bar_derived',			'is_derived',		true	);
	test_attr ( $bar,	'bar_derived',			'is_readonly',		true	);
	test_attr ( $bar,	'bar_derived',			'_is_metadata',	'ro'	);
	test_attr ( $bar,	'bar_derived',			'is_lazy_build',	true	);

	test_attr ( $bar,	'bar_derived_def',	'is_transient',	false	);
	test_attr ( $bar,	'bar_derived_def',	'is_virtual',		true	);
	test_attr ( $bar,	'bar_derived_def',	'is_derived',		true	);
	test_attr ( $bar,	'bar_derived_def',	'is_readonly',		true	);
	test_attr ( $bar,	'bar_derived_def',	'_is_metadata',	'ro'	);
	test_attr ( $bar,	'bar_derived_def',	'is_lazy_build',	undef	);
}

IS_DEBUG and DEBUG ::Dump [ $ASYL, $foo, $bar ], [qw ( ASYL foo bar )];

sub test_attr
{
	my ( $obj, $name, $test, $exp )	= @_;

	my $attr	= $obj->meta()->find_attribute_by_name ( $name );

	is $attr->$test, $exp, "$name $test = " . ( $exp ? $exp : 0 );
}

1;

__END__
