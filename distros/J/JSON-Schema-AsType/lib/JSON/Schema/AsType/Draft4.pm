package JSON::Schema::AsType::Draft4;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Role processing draft4 JSON Schema 
$JSON::Schema::AsType::Draft4::VERSION = '0.4.4';

use strict;
use warnings;

use Moose::Role;

use Type::Utils;
use Scalar::Util qw/ looks_like_number /;
use List::Util qw/ reduce pairmap pairs /;
use List::MoreUtils qw/ any all none uniq zip /;
use Types::Standard qw/InstanceOf HashRef StrictNum Any Str ArrayRef Int slurpy Dict Optional slurpy /; 

use JSON;

use JSON::Schema::AsType;

use JSON::Schema::AsType::Draft4::Types '-all';

override all_keywords => sub {
    my $self = shift;
    
    # $ref trumps all
    return '$ref' if $self->schema->{'$ref'};

    return uniq 'id', super();
};

__PACKAGE__->meta->add_method( '_keyword_$ref' => sub {
        my( $self, $ref ) = @_;

        return Type::Tiny->new(
            name => 'Ref',
            display_name => "Ref($ref)",
            constraint => sub {
                
                my $r = $self->resolve_reference($ref);

                $r->check($_);
            },
            message => sub { 
                my $schema = $self->resolve_reference($ref);

                join "\n", "ref schema is " . to_json($schema->schema, { allow_nonref => 1 }), @{$schema->validate_explain($_)} 
            }
        );
} );

sub _keyword_id {
    my( $self, $id ) = @_;

    unless( $self->uri ) {
        my $id = $self->absolute_id($id);
        $self->uri($id);
    }

    return;
}

sub _keyword_definitions {
    my( $self, $defs ) = @_;

    $self->sub_schema( $_ ) for values %$defs;

    return;
};

sub _keyword_pattern {
    my( $self, $pattern ) = @_;

    Pattern[$pattern];
}

sub _keyword_enum {
    my( $self, $enum ) = @_;
 
    Enum[@$enum];
}

sub _keyword_uniqueItems {
    my( $self, $unique ) = @_;

    return unless $unique;  # unique false? all is good

    return UniqueItems;
}

sub _keyword_dependencies {
    my( $self, $dependencies ) = @_;

    return Dependencies[
        pairmap { $a => ref $b eq 'HASH' ? $self->sub_schema($b) : $b } %$dependencies
    ];

}

sub _keyword_additionalProperties {
    my( $self, $addi ) = @_;

    my $add_schema;
    $add_schema = $self->sub_schema($addi) if ref $addi eq 'HASH';

    my @known_keys = (
        eval { keys %{ $self->schema->{properties} } },
        map { qr/$_/ } eval { keys %{ $self->schema->{patternProperties} } } );

    return AdditionalProperties[ \@known_keys, $add_schema ? $add_schema->type : $addi ];
}

sub _keyword_patternProperties {
    my( $self, $properties ) = @_;

    my %prop_schemas = pairmap {
        $a => $self->sub_schema($b)->type
    } %$properties;

    return PatternProperties[ %prop_schemas ];
}

sub _keyword_properties {
    my( $self, $properties ) = @_;

    Properties[
        pairmap { 
            my $schema = $self->sub_schema($b);
            $a => $schema->type;
        }  %$properties
    ];

}

sub _keyword_maxProperties {
    my( $self, $max ) = @_;

    MaxProperties[ $max ];
}

sub _keyword_minProperties {
    my( $self, $min ) = @_;

    MinProperties[ $min ];
}

sub _keyword_required {
    my( $self, $required ) = @_;

    Required[@$required];
}

sub _keyword_not {
    my( $self, $schema ) = @_;
    Not[ $self->sub_schema($schema) ];
}

sub _keyword_oneOf {
    my( $self, $options ) = @_;

    OneOf[ map { $self->sub_schema( $_ ) } @$options ];
}


sub _keyword_anyOf {
    my( $self, $options ) = @_;

    AnyOf[ map { $self->sub_schema($_)->type } @$options ];
}

sub _keyword_allOf {
    my( $self, $options ) = @_;

    AllOf[ map { $self->sub_schema($_)->type } @$options ];
}

sub _keyword_type {
    my( $self, $struct_type ) = @_;

    my %keyword_map = map {
        lc $_->name => $_
    } Integer, Number, String, Object, Array, Boolean, Null;

    unless( $self->strict_string ) {
        $keyword_map{number} = LaxNumber;
        $keyword_map{integer} = LaxInteger;
        $keyword_map{string} = LaxString;
    }


    return $keyword_map{$struct_type}
        if $keyword_map{$struct_type};

    if( ref $struct_type eq 'ARRAY' ) {
        return AnyOf[map { $self->_keyword_type($_) } @$struct_type];
    }

    return;
}

sub _keyword_multipleOf {
    my( $self, $num ) = @_;

    MultipleOf[$num];
};

sub _keyword_maxItems {
    my( $self, $max ) = @_;

    MaxItems[$max];
}

sub _keyword_minItems {
    my( $self, $min ) = @_;

    MinItems[$min];
}

sub _keyword_maxLength {
    my( $self, $max ) = @_;

    MaxLength[$max];
}

sub _keyword_minLength {
    my( $self, $min ) = @_;

    return MinLength[$min];
}

sub _keyword_maximum {
    my( $self, $maximum ) = @_;

    return $self->schema->{exclusiveMaximum}
        ? ExclusiveMaximum[$maximum]
        : Maximum[$maximum];

}

sub _keyword_minimum {
    my( $self, $minimum ) = @_;

    if ( $self->schema->{exclusiveMinimum} ) {
        return ExclusiveMinimum[$minimum];
    }

    return Minimum[$minimum];
}

sub _keyword_additionalItems {
    my( $self, $s ) = @_;

    unless($s) {
        my $items = $self->schema->{items} or return;
        return if ref $items eq 'HASH';  # it's a schema, nevermind
        my $size = @$items;

        return AdditionalItems[$size];
    }

    my $schema = $self->sub_schema($s);

    my $to_skip  = @{ $self->schema->{items} };

    return AdditionalItems[$to_skip,$schema];

}

sub _keyword_items {
    my( $self, $items ) = @_;

    if ( Boolean->check($items) ) {
        return Items[$items];
    }

    if( ref $items eq 'HASH' ) {
        my $type = $self->sub_schema($items)->type;

        return Items[$type];
    }

    # TODO forward declaration not workie
    my @types;
    for ( @$items ) {
        push @types, $self->sub_schema($_)->type;
    }

    return Items[\@types];
}

JSON::Schema::AsType->new(
        specification => 'draft4',
        uri           => "http${_}://json-schema.org/draft-04/schema",
        schema        => from_json <<'END_JSON' )->type for '', 's';
{
    "id": "http://json-schema.org/draft-04/schema#",
    "$schema": "http://json-schema.org/draft-04/schema#",
    "description": "Core schema meta-schema",
    "definitions": {
        "schemaArray": {
            "type": "array",
            "minItems": 1,
            "items": { "$ref": "#" }
        },
        "positiveInteger": {
            "type": "integer",
            "minimum": 0
        },
        "positiveIntegerDefault0": {
            "allOf": [ { "$ref": "#/definitions/positiveInteger" }, { "default": 0 } ]
        },
        "simpleTypes": {
            "enum": [ "array", "boolean", "integer", "null", "number", "object", "string" ]
        },
        "stringArray": {
            "type": "array",
            "items": { "type": "string" },
            "minItems": 1,
            "uniqueItems": true
        }
    },
    "type": "object",
    "properties": {
        "id": {
            "type": "string",
            "format": "uri"
        },
        "$schema": {
            "type": "string",
            "format": "uri"
        },
        "title": {
            "type": "string"
        },
        "description": {
            "type": "string"
        },
        "default": {},
        "multipleOf": {
            "type": "number",
            "minimum": 0,
            "exclusiveMinimum": true
        },
        "maximum": {
            "type": "number"
        },
        "exclusiveMaximum": {
            "type": "boolean",
            "default": false
        },
        "minimum": {
            "type": "number"
        },
        "exclusiveMinimum": {
            "type": "boolean",
            "default": false
        },
        "maxLength": { "$ref": "#/definitions/positiveInteger" },
        "minLength": { "$ref": "#/definitions/positiveIntegerDefault0" },
        "pattern": {
            "type": "string",
            "format": "regex"
        },
        "additionalItems": {
            "anyOf": [
                { "type": "boolean" },
                { "$ref": "#" }
            ],
            "default": {}
        },
        "items": {
            "anyOf": [
                { "$ref": "#" },
                { "$ref": "#/definitions/schemaArray" }
            ],
            "default": {}
        },
        "maxItems": { "$ref": "#/definitions/positiveInteger" },
        "minItems": { "$ref": "#/definitions/positiveIntegerDefault0" },
        "uniqueItems": {
            "type": "boolean",
            "default": false
        },
        "maxProperties": { "$ref": "#/definitions/positiveInteger" },
        "minProperties": { "$ref": "#/definitions/positiveIntegerDefault0" },
        "required": { "$ref": "#/definitions/stringArray" },
        "additionalProperties": {
            "anyOf": [
                { "type": "boolean" },
                { "$ref": "#" }
            ],
            "default": {}
        },
        "definitions": {
            "type": "object",
            "additionalProperties": { "$ref": "#" },
            "default": {}
        },
        "properties": {
            "type": "object",
            "additionalProperties": { "$ref": "#" },
            "default": {}
        },
        "patternProperties": {
            "type": "object",
            "additionalProperties": { "$ref": "#" },
            "default": {}
        },
        "dependencies": {
            "type": "object",
            "additionalProperties": {
                "anyOf": [
                    { "$ref": "#" },
                    { "$ref": "#/definitions/stringArray" }
                ]
            }
        },
        "enum": {
            "type": "array",
            "minItems": 1,
            "uniqueItems": true
        },
        "type": {
            "anyOf": [
                { "$ref": "#/definitions/simpleTypes" },
                {
                    "type": "array",
                    "items": { "$ref": "#/definitions/simpleTypes" },
                    "minItems": 1,
                    "uniqueItems": true
                }
            ]
        },
        "allOf": { "$ref": "#/definitions/schemaArray" },
        "anyOf": { "$ref": "#/definitions/schemaArray" },
        "oneOf": { "$ref": "#/definitions/schemaArray" },
        "not": { "$ref": "#" }
    },
    "dependencies": {
        "exclusiveMaximum": [ "maximum" ],
        "exclusiveMinimum": [ "minimum" ]
    },
    "default": {}
}
END_JSON

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft4 - Role processing draft4 JSON Schema 

=head1 VERSION

version 0.4.4

=head1 DESCRIPTION

This role is not intended to be used directly. It is used internally
by L<JSON::Schema::AsType> objects.

Importing this module auto-populate the Draft4 schema in the
L<JSON::Schema::AsType> schema cache.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
