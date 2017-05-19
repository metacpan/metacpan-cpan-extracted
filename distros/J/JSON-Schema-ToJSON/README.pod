package JSON::Schema::ToJSON;

use strict;
use warnings;

use Mojo::Base -base;
use Cpanel::JSON::XS;
use JSON::Validator;
use String::Random;
use DateTime;
use Hash::Merge qw/ merge /;

our $VERSION = '0.11';

has _validator  => sub { JSON::Validator->new };
has _str_rand   => sub { String::Random->new };
has _depth      => sub { 0 };

has max_depth   => sub { 10 };
has example_key => sub { 0 };

sub json_schema_to_json {
	my ( $self,%args ) = @_;

	my $schema = $args{schema}; # an already parsed JSON schema

	if ( ! $schema ) {
		$schema = $args{schema_str} # an unparsed JSON schema
			|| die "json_schema_to_json needs schema or schema_str arg";

		eval { $schema = decode_json( $schema ); }
		or do { die "json_schema_to_json failed to parse schema: $@" };
	}

	$self->example_key( $args{example_key} ) if $args{example_key};

	$self->_validator->schema( $schema );
	$schema = $self->_validator->schema->data;

	$self->_depth( $self->_depth + 1 );
	my ( $method,$sub_schema ) = $self->_guess_method( $schema );
	$self->_depth( $self->_depth - 1 ) if $self->_depth;

	return $self->$method( $sub_schema );
}

sub _example_from_spec {
	my ( $self,$schema ) = @_;

	# spec/schema can contain examples that we could use as mock data

	return $schema->{ $self->example_key } # OpenAPI specific
		if $self->example_key && $schema->{ $self->example_key };

	return ();
}

sub _random_boolean {
	my ( $self,$schema ) = @_;

	return $self->_example_from_spec( $schema )
		if scalar $self->_example_from_spec( $schema );

	return rand > 0.5
		? Cpanel::JSON::XS::true
		: Cpanel::JSON::XS::false
}

sub _random_integer {
	my ( $self,$schema ) = @_;

	return $self->_example_from_spec( $schema )
		if scalar $self->_example_from_spec( $schema );

	my $min = $schema->{minimum};
	my $max = $schema->{maximum};
	my $mof = $schema->{multipleOf};

	# by default the min/max values are exclusive
	$min++ if defined $min && $schema->{exclusiveMinimum};
	$max-- if defined $max && $schema->{exclusiveMaximum};

	my @possible_values = defined $min && defined $max
		? $min .. $max
		: defined $min
			? $min .. $min + 1000
			: defined $max
				? 1 .. $max
				: defined $mof
					? $mof .. $mof
					: 1 .. 1000 # short range, prevent creation of a massive array
	;

	# if we have multipleOf just return the first value that fits. note that
	# there is a possible bug here and the JSON schema spec isn't clear about
	# it - it's possible to have a multipleOf that would never be possible
	# given certain minimum and maximum (e.g. 1 .. 3, multiple of 4)
	if ( $mof ) {
		shift( @possible_values ) until (
			! @possible_values
			|| $possible_values[0] % $mof == 0
		);
		return $possible_values[0];
	} else {
		return $self->_random_element( [ @possible_values ] );
	}
}

sub _random_number {
	my ( $self,$schema ) = @_;

	return $self->_example_from_spec( $schema )
		if scalar $self->_example_from_spec( $schema );

	return $self->_random_integer( $schema )
		if ( $schema->{multipleOf} );

	return $self->_random_integer( $schema ) + $self->_random_integer( $schema ) / 10;
}

sub _random_string {
	my ( $self,$schema ) = @_;

	return $self->_example_from_spec( $schema )
		if scalar $self->_example_from_spec( $schema );

	if ( my @enum = @{ $schema->{enum} // [] } ) {
		return $self->_random_element( [ @enum ] );
	}

	return $self->_str_rand->randregex( $schema->{pattern} )
		if $schema->{pattern};

	if ( my $format = $schema->{format} ) {
		return {
			"date-time" => DateTime->now->subtract(
				weeks => $self->_random_integer({ minimum => 1, maximum => 500 }),
				days => $self->_random_integer({ minimum => 1 }),
				hours => $self->_random_integer({ minimum => 1 }),
				minutes => $self->_random_integer({ minimum => 1 }),
				seconds => $self->_random_integer({ minimum => 1 }),
			)->iso8601 . '.000Z',
			"email"     =>
				$self->_random_string( { pattern => '[A-Za-z]{12}' } )
				. '@'
				. $self->_random_string( { pattern => '[A-Za-z]{12}' } )
				. '.com',
			"hostname"  => $self->_random_string( { pattern => '[A-Za-z]{12}' } ),
			"ipv4"      => join( '.',map {  $self->_random_integer({
				minimum => 1,
				maximum => 254,
			}) } 1 .. 4 ),
			"ipv6"      => '2001:0db8:0000:0000:0000:0000:1428:57ab',
			"uri"       => 'https://www.'
				. $self->_random_string( { pattern => '[a-z]{12}' } )
				. '.com',
			"uriref"    => 'https://www.'
				. $self->_random_string( { pattern => '[a-z]{12}' } )
				. '.com',
		}->{ $format };
	}

	my $min = $schema->{minLength}
		|| ( $schema->{maxLength} ? $schema->{maxLength} - 1 : 10 );

	my $max = $schema->{maxLength}
		|| ( $schema->{minLength} ? $schema->{minLength} + 1 : 50 );

	return $self->_str_rand->randpattern(
		'.' x $self->_random_integer( { minimum => $min, maximum => $max } ),
	);
}

sub _random_array {
	my ( $self,$schema ) = @_;

	my $unique = $schema->{uniqueItems};

	my $length = $self->_random_integer({
		minimum => $schema->{minItems}
			|| ( $schema->{maxItems} ? $schema->{maxItems} - 1 : 1 ),
		maximum => $schema->{maxItems}
			|| ( $schema->{minItems} ? $schema->{minItems} + 1 : 5 )
	});

	if ( $self->_depth >= $self->max_depth ) {
		warn __PACKAGE__
			. " hit max depth (@{[ $self->max_depth ]}) in _random_array";
		return [ 1 .. $length ];
	} else {
		$self->_depth( $self->_depth + 1 );
	}

	my @return_items;

	if ( my $items = $schema->{items} ) {

		$self->_depth( $self->_depth + 1 );

		if ( ref( $items ) eq 'ARRAY' ) {

			ADD_ITEM: foreach my $item ( @{ $items } ) {
				last ADD_ITEM if ( $self->_depth >= $self->max_depth );
				$self->_add_next_array_item( \@return_items,$item,$unique )
					|| redo ADD_ITEM; # possible halting problem
			}

		} else {

			ADD_ITEM: foreach my $i ( 1 .. $length ) {
				last ADD_ITEM if ( $self->_depth >= $self->max_depth );
				$self->_add_next_array_item( \@return_items,$items,$unique )
					|| redo ADD_ITEM; # possible halting problem
			}

		}

	} else {
		@return_items = 1 .. $length;
	}

	$self->_depth( $self->_depth - 1 ) if $self->_depth;
	return [ @return_items ];
}

sub _add_next_array_item {
	my ( $self,$array,$schema,$unique ) = @_;

	if ( $self->_depth >= $self->max_depth ) {
		warn __PACKAGE__
			. " hit max depth (@{[ $self->max_depth ]}) in _add_next_array_item";
		push( @{ $array },undef );
		return 1;
	}

	$self->_depth( $self->_depth + 1 );
	my ( $method,$sub_schema ) = $self->_guess_method( $schema );
	my $value = $self->$method( $sub_schema );
	$self->_depth( $self->_depth - 1 ) if $self->_depth;

	if ( ! $unique ) {
		push( @{ $array },$value );
		return 1;
	}

	# unique requires us to check all existing elements of the array and only
	# add the new value if it doesn't already exist
	my %existing = map { $_ => 1 } @{ $array };

	if ( ! $existing{$value} ) {
		push( @{ $array },$value );
		return 1;
	}

	return 0;
}

sub _random_object {
	my ( $self,$schema ) = @_;

	my $object = {};
	my $required;
	my %properties = map { $_ => 1 } keys( %{ $schema->{properties} } );

	if ( $required = $schema->{required} ) {
		# we have a list of required properties, just use those
		%properties = map { $_ => 1 } @{ $required };
	}

	# check max/min properties requirements
	my $min = $schema->{minProperties}
		|| ( $schema->{maxProperties} ? $schema->{maxProperties} - 1 : undef );

	my $max = $schema->{maxProperties}
		|| ( $schema->{minProperties} ? $schema->{minProperties} + 1 : undef );

	if ( ! $min && ! $max ) {
		# no min or max, just make use of all properties
		%properties = map { $_ => 1 } keys( %{ $schema->{properties} } );
	}

	if ( $min && scalar( keys( %properties ) ) < $min ) {
		# we have too few properties
		if ( $max ) {
			# add more properties until we have enough
			MAX_PROP: foreach my $property ( keys( %{ $schema->{properties} } ) ) {
				$properties{$property} = 1;
				last MAX_PROP if scalar( keys( %properties ) ) == $min;
			}
		} else {
			# no max, just make use of all properties
			%properties = map { $_ => 1 } keys( %{ $schema->{properties} } );
		}
	}

	if ( $max && scalar( keys( %properties ) ) > $max ) {
		# we have too many properties, delete some (except those required)
		# until we are below the max permitted amount
		MIN_PROP: foreach my $property ( keys( %{ $schema->{properties} } ) ) {

			delete( $properties{$property} ) if (
				# we can delete, we don't have any required properties
				! $required

				# or this property is not amongst the list of required properties
				|| ! grep { $_ eq $property } @{ $required }
			);

			last MIN_PROP if scalar( keys( %properties ) ) <= $max;
		}
	}

	if ( $self->_depth >= $self->max_depth ) {
		warn __PACKAGE__
			. " hit max depth (@{[ $self->max_depth ]}) in _random_object";
		return {};
	} else {
		$self->_depth( $self->_depth + 1 );
	}

	PROPERTY: foreach my $property ( keys %properties ) {

		$self->_depth( $self->_depth + 1 );

		last PROPERTY if ( $self->_depth >= $self->max_depth );

		my ( $method,$sub_schema )
			= $self->_guess_method( $schema->{properties}{$property} );

		$object->{$property} = $self->$method( $sub_schema );
	}

	$self->_depth( $self->_depth - 1 ) if $self->_depth;

	return $object;
}

sub _random_null { undef }

sub _random_enum {
	my ( $self,$schema ) = @_;
	return $self->_random_element( $schema->{'enum'} );
}

sub _guess_method {
	my ( $self,$schema ) = @_;

	if (
		$schema->{'type'}
		&& ref( $schema->{'type'} ) eq 'ARRAY'
	) {
		$schema->{'type'} = $self->_random_element( $schema->{'type'} );
	}

	# check for combining schemas
	if ( my $any_of = $schema->{'anyOf'} ) {

		# easy, pick a random sub schema
		my $sub_schema = $self->_random_element( $any_of );
		return $self->_guess_method( $sub_schema );

	} elsif ( my $all_of = $schema->{'allOf'} ) {

		# easy? mush these all together and assume the schema doesn't
		# contain any contradictory information. note the mushing
		# together needs to be a little bit smart to prevent stomping
		# on any duplicate keys (hence Hash::Merge)
		my $merged_schema = {};

		foreach my $sub_schema ( @{ $all_of } ) {
			$merged_schema = merge( $merged_schema,$sub_schema );
		}

		return $self->_guess_method( $merged_schema );

	} elsif ( my $one_of = $schema->{'oneOf'} ) {

		# difficult - we need to generate data that validates against
		# one and *only* one of the rules, so here we make a poor
		# attempt and just go by the first rule
		warn __PACKAGE__ . " encountered oneOf, see CAVEATS perldoc section";
		return $self->_guess_method( $one_of->[0] );

	} elsif ( my $not = $schema->{'not'} ) {

		if ( my $not_type = $not->{'type'} ) {

			my $type = {
				"string"  => "integer",
				"integer" => "string",
				"number"  => "string",
				"enum"    => "string",
				"boolean" => "string",
				"null"    => "integer",
				"object"  => "string",
				"array"   => "object",
			}->{ $not_type };

			return $self->_guess_method( { type => $type } );
		}

		# well i don't like this, because by implication it means
		# the data can be anything but the listed one so it seems
		# very handwavy in some cases.
		warn __PACKAGE__ . " encountered not, see CAVEATS perldoc section";
	}

	# danger danger! accessing private method from elsewhere
	my $schema_type = JSON::Validator::_guess_schema_type( $schema );

	$schema_type //= 'null';

	$self->_depth( $self->_depth - 1 ) if $self->_depth;
	return ( "_random_$schema_type",$schema );
}

sub _random_element {
	my ( $self,$list ) = @_;
	return $list->[ int( rand( scalar( @{ $list } ) ) ) ];
}

=encoding utf8

=head1 NAME

JSON::Schema::ToJSON - Generate example JSON structures from JSON Schema definitions

=head1 VERSION

0.11

=head1 SYNOPSIS

    use JSON::Schema::ToJSON;

    my $to_json  = JSON::Schema::ToJSON->new(
        example_key => undef, # set to a key to take example from
        max_depth   => 10,    # increase if you have very deep data structures
    );

    my $perl_string_hash_or_arrayref = $to_json->json_schema_to_json(
        schema     => $already_parsed_json_schema,  # either this
        schema_str => '{ "type" : "boolean" }',     # or this
    );

=head1 DESCRIPTION

L<JSON::Schema::ToJSON> is a class for generating "fake" or "example" JSON data
structures from JSON Schema structures.

=head1 CONSTRUCTOR ARGUMENTS

=head2 example_key

The key that will be used to find example data for use in the returned structure. In
the case of the following schema:

    {
        "type" : "object",
        "properties" : {
            "id" : {
                "type" : "string",
                "description" : "ID of the payment.",
                "x-example" : "123ABC"
            }
        }
    }

Setting example_key to C<x-example> will make the generator return the content of
the C<"x-example"> (123ABC) rather than a random string/int/etc. This is more so
for things like OpenAPI specifications.

You can set this to any key you like, although be careful as you could end up with
invalid data being used (for example an integer field and then using the description
key as the content would not be sensible or valid).

=head2 max_depth

To prevent deep recursion due to circular references in JSON schemas the module has
a default max depth set to a very conservative level of 10. If you need to go deeper
than this then pass a larger value at object construction.

=head1 METHODS

=head2 json_schema_to_json

    my $perl_string_hash_or_arrayref = $to_json->json_schema_to_json(
        schema     => $already_parsed_json_schema,  # either this
        schema_str => '{ "type" : "boolean" }',     # or this
    );

Returns a randomly generated representative data structure that corresponds to the
passed JSON schema. Can take either an already parsed JSON Schema or the raw JSON
Schema string.

=head1 CAVEATS

Caveats? The implementation is incomplete as using some of the more edge case JSON
schema validation options may not generate representative JSON so they will not
validate against the schema on a round trip. These include:

=over 4

=item * additionalItems

This is ignored

=item * additionalProperties and patternProperties

These are also ignored

=item * dependencies

This is *also* ignored, possible result of invalid JSON if used

=item * oneOf

Only the *first* schema from the oneOf list will be used (which means
that the data returned may be invalid against others in the list)

=item * not

Currently any not restrictions are ignored as these can be very hand wavy
but we will try a "best guess" in the case of "not" : { "type" : ... }

=back

In the case of oneOf and not the module will raise a warning to let you know that
potentially invalid JSON has been generated. If you're using this module then you
probably want to avoid oneOf and not in your schemas.

It is also entirely possible to pass a schema that could never be validated, but
will result in a generated structure anyway, example: an integer that has a "minimum"
value of 2, "maximum" value of 4, and must be a "multipleOf" 5 - a nonsensical
combination.

Note that the data generated is completely random, don't expect it to be the same
across runs or calls. The data is also meaningless in terms of what it represents
such that an object property of "name" that is a string will be generated as, for
example, "kj02@#fjs01je#$42wfjs" - The JSON generated is so you have a representative
B<structure>, not representative B<data>. Set example keys in your schema and then
set the C<example_key> in the constructor if you want this to be repeatable and/or
more representative.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/json-schema-tojson

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=cut

1;

# vim:noet:sw=4:ts=4
