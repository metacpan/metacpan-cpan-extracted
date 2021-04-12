
=pod

=encoding utf-8

=head1 PURPOSE

Checks LINQ::FieldSet::Selector.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::Modern;
use LINQ qw( LINQ );
use LINQ::Util qw( fields );
use Object::Adhoc qw( object );

my ( $alice, $bob ) = LINQ(
	[
		object( { name => 'Alice', xyz => 'ABC', min => 1,  max => 99 } ),
		object( { name => 'Bob',   xyz => 'DEF', min => 18, max => 49 } ),
	]
)->select(
	fields(
		'name', -as => 'moniker',
		'xyz',
		sub { sprintf( '%d-%d', $_->min, $_->max ) }, -as => 'range',
	)
)->to_list;

object_ok(
	$alice,
	'$alice',
	'can'  => [qw( moniker xyz range )],
	'more' => sub {
		my $object = shift;
		is( $object->moniker, 'Alice' );
		is( $object->xyz,     'ABC' );
		is( $object->range,   '1-99' );
	},
);

object_ok(
	$bob,
	'$bob',
	'can'  => [qw( moniker xyz range )],
	'more' => sub {
		my $object = shift;
		is( $object->moniker, 'Bob' );
		is( $object->xyz,     'DEF' );
		is( $object->range,   '18-49' );
	},
);

my ( $carol ) = LINQ(
	[
		{ name => 'Carol', xyz => 'XYZ', min => 49, max => 75 },
	]
)->select(
	fields(
		'name', -as => 'moniker',
		'xyz',
		sub { sprintf( '%d-%d', $_->{min}, $_->{max} ) }, -as => 'range',
	)
)->to_list;

object_ok(
	$carol,
	'$carol',
	'can'  => [qw( moniker xyz range )],
	'more' => sub {
		my $object = shift;
		is( $object->moniker, 'Carol' );
		is( $object->xyz,     'XYZ' );
		is( $object->range,   '49-75' );
	},
);

my ( $dave ) = LINQ(
	[
		object( { name => 'Dave', xyz => 'UVW', min => 49, max => 75 } ),
	]
)->select(
	fields(
		'name', -as => 'moniker',
		'xyz',
		'*',
		sub { sprintf( '%d-%d', $_->min, $_->max ) }, -as => 'range',
	)
)->to_list;

object_ok(
	$dave,
	'$dave',
	'can'  => [qw( moniker xyz range name min max )],
	'more' => sub {
		my $object = shift;
		is( $object->moniker, 'Dave' );
		is( $object->xyz,     'UVW' );
		is( $object->range,   '49-75' );
		is( $object->name,    'Dave' );
		is( $object->min,     '49' );
		is( $object->max,     '75' );
	},
);

is(
	fields( "foo", "bar", -as => "barr", "baz" )->_sql_selection,
	'"foo", "bar" AS "barr", "baz"',
	'Simple SQL generation',
);

is(
	fields( "foo", "bar", -as => "barr", "baz" )->_sql_selection( sub { uc($_[0]) } ),
	'FOO, BAR AS BARR, BAZ',
	'Simple SQL generation with custom quoter',
);

is(
	fields( "foo", "bar", -as => "barr", "baz", "*" )->_sql_selection,
	undef,
	'Simple SQL generation with asterisk',
);

is(
	fields( "foo", sub { }, "bar", -as => "barr", "baz" )->_sql_selection,
	undef,
	'Simple SQL generation with coderef',
);

my $selector = fields(
	'~yay~',
	sub { $_->{'monkee'} },
);

object_ok(
	LINQ( [
		{ '~yay~' => 42, 'monkee' => 69 },
	] )->select( $selector )->single( sub { 1 } ),
	'$weirdo',
	more => sub {
		my $weirdo = shift;
		is( $weirdo->_1, 42 );
		is( $weirdo->_2, 69 );
	},
);

{
	my $thung = fields( '*', 'foo', 'bar', -as => 'baz' );
	
	is_deeply(
		{%{ $thung }},
		{%{ 'LINQ::FieldSet::Selection'->new( {
			'fields' => [
				'LINQ::Field'->new( {
					index  => 1,
					name   => 'foo',
					value  => 'foo',
					params => {},
				} ),
				'LINQ::Field'->new( {
					index  => 2,
					name   => 'baz',
					value  => 'bar',
					params => { as => 'baz' },
				} ),
			],
			'seen_asterisk' => !!1,
		} ) }},
		'FieldSet constructor'
	);
	
	is(
		$thung->target_class,
		$thung->target_class,
		'->target_class',
	);
	
	my $fh = $thung->fields_hash;
	
	is_deeply(
		$fh,
		{
			foo => 'LINQ::Field'->new( {
				index  => 1,
				name   => 'foo',
				value  => 'foo',
				params => {},
			} ),
			baz => 'LINQ::Field'->new( {
				index  => 2,
				name   => 'baz',
				value  => 'bar',
				params => { as => 'baz' },
			} ),
		},
		'->fields_hash'
	);
	
	use Scalar::Util 'refaddr';
	is(
		refaddr( $fh ),
		refaddr( $thung->fields_hash ),
		'->fields_hash again'
	);
	
	# Weird stuff for coverage...
	
	{
		package Silly::Class;
		our @ISA = 'LINQ::FieldSet::Selection';
		sub _build_fields_hash  { 0 }
		sub _build_coderef      { 0 }
		sub _build_target_class { 0 }
	}
	$thung = fields( '*', 'foo', 'bar', -as => 'baz' );
	bless( $thung, 'Silly::Class' );
	is( $thung->fields_hash,  0, 'Silly::Class->fields_hash' );
	is( $thung->fields_hash,  0, 'Silly::Class->fields_hash again' );
	is( $thung->coderef,      0, 'Silly::Class->coderef_hash' );
	is( $thung->coderef,      0, 'Silly::Class->coderef again' );
	is( $thung->target_class, 0, 'Silly::Class->target_class' );
	is( $thung->target_class, 0, 'Silly::Class->target_class again' );
	
	{
		package Silly::Class2;
		our @ISA = 'LINQ::Field';
		sub _build_getter { 0 }
	}
	$thung = fields( '*', 'foo', 'bar', -as => 'baz' );
	bless( $_, 'Silly::Class2' ) for @{ $thung->fields };
	is( $thung->fields->[0]->getter, 0, 'Silly::Class2' );
	is( $thung->fields->[0]->getter, 0, 'Silly::Class2 again' );
	
	{
		package Silly::Class3;
		sub foo { 66 }
		sub bar { 99 }
	}
	$thung = fields( 'foo', 'bar', -as => 'baz' );
	is_deeply(
		{%{ LINQ( [ bless [], 'Silly::Class3'  ] )->select( $thung )->first }},
		{ foo => 66, baz => 99 },
		'Silly::Class3'
	);
}

object_ok(
	exception { fields( 'foo', -boop ) }, '$e',
	isa   => 'LINQ::Exception::CallerError',
	more  => sub {
		my $e = shift;
		like( $e->message, qr/Unknown field parameter/ );
	},
);

done_testing;
