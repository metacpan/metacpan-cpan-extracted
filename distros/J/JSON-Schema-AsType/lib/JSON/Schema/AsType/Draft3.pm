package JSON::Schema::AsType::Draft3;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Role processing draft3 JSON Schema 
$JSON::Schema::AsType::Draft3::VERSION = '0.4.4';

use strict;
use warnings;

use Moose::Role;

use Type::Utils;
use Scalar::Util qw/ looks_like_number /;
use List::Util qw/ reduce pairmap pairs /;
use List::MoreUtils qw/ any all none uniq zip /;

use JSON::Schema::AsType;

use JSON;

use JSON::Schema::AsType::Draft3::Types '-all';
use Types::Standard 'Optional';

with 'JSON::Schema::AsType::Draft4' => {
    -excludes => [qw/ _keyword_properties _keyword_required _keyword_type /]
};

sub _keyword_properties {
    my( $self, $properties ) = @_;

    my @props = pairmap { {
        my $schema = $self->sub_schema($b);
        my $p = $schema->type;
        $p = Optional[$p] unless $b->{required};
        $a => $p
    }}  %$properties;

    return Properties[@props];
}

sub _keyword_disallow {
    Disallow[ $_[0]->_keyword_type($_[1]) ];
}


sub _keyword_extends {
    my( $self, $extends ) = @_;

    my @extends = ref $extends eq 'ARRAY' ? @$extends : ( $extends );

    return Extends[ map { $self->sub_schema($_)->type } @extends];
}

sub _keyword_type {
    my( $self, $struct_type ) = @_;

    my %type_map = map {
        lc $_->name => $_
    } Integer, Boolean, Number, String, Null, Object, Array;

    unless( $self->strict_string ) {
        $type_map{number} = LaxNumber;
        $type_map{integer} = LaxInteger;
        $type_map{string} = LaxString;
    }


    return if $struct_type eq 'any';

    return $type_map{$struct_type} if $type_map{$struct_type};

    if( my @types = eval { @$struct_type } ) {
        return reduce { $a | $b } map { ref $_ ? $self->sub_schema($_)->type : $self->_keyword_type($_) } @types;
    }

    die "unknown type '$struct_type'";
}

sub _keyword_divisibleBy {
    my( $self, $divisibleBy ) = @_;

    DivisibleBy[$divisibleBy];
}

sub _keyword_dependencies {
    my( $self, $dependencies ) = @_;

    return Dependencies[
        pairmap { $a => ref $b eq 'HASH' ? $self->sub_schema($b)->type : $b } %$dependencies
    ];

}

JSON::Schema::AsType->new(
    draft_version => '3',
    uri           => "http${_}://json-schema.org/draft-03/schema",
    schema        => from_json <<'END_JSON' )->type for '', 's';
{
    "$schema": "http://json-schema.org/draft-03/schema#",
    "id": "http://json-schema.org/draft-03/schema#",
    "type": "object",
    
    "properties": {
        "type": {
            "type": [ "string", "array" ],
            "items": {
                "type": [ "string", { "$ref": "#" } ]
            },
            "uniqueItems": true,
            "default": "any"
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
        
        "additionalProperties": {
            "type": [ { "$ref": "#" }, "boolean" ],
            "default": {}
        },
        
        "items": {
            "type": [ { "$ref": "#" }, "array" ],
            "items": { "$ref": "#" },
            "default": {}
        },
        
        "additionalItems": {
            "type": [ { "$ref": "#" }, "boolean" ],
            "default": {}
        },
        
        "required": {
            "type": "boolean",
            "default": false
        },
        
        "dependencies": {
            "type": "object",
            "additionalProperties": {
                "type": [ "string", "array", { "$ref": "#" } ],
                "items": {
                    "type": "string"
                }
            },
            "default": {}
        },
        
        "minimum": {
            "type": "number"
        },
        
        "maximum": {
            "type": "number"
        },
        
        "exclusiveMinimum": {
            "type": "boolean",
            "default": false
        },
        
        "exclusiveMaximum": {
            "type": "boolean",
            "default": false
        },
        
        "minItems": {
            "type": "integer",
            "minimum": 0,
            "default": 0
        },
        
        "maxItems": {
            "type": "integer",
            "minimum": 0
        },
        
        "uniqueItems": {
            "type": "boolean",
            "default": false
        },
        
        "pattern": {
            "type": "string",
            "format": "regex"
        },
        
        "minLength": {
            "type": "integer",
            "minimum": 0,
            "default": 0
        },
        
        "maxLength": {
            "type": "integer"
        },
        
        "enum": {
            "type": "array",
            "minItems": 1,
            "uniqueItems": true
        },
        
        "default": {
            "type": "any"
        },
        
        "title": {
            "type": "string"
        },
        
        "description": {
            "type": "string"
        },
        
        "format": {
            "type": "string"
        },
        
        "divisibleBy": {
            "type": "number",
            "minimum": 0,
            "exclusiveMinimum": true,
            "default": 1
        },
        
        "disallow": {
            "type": [ "string", "array" ],
            "items": {
                "type": [ "string", { "$ref": "#" } ]
            },
            "uniqueItems": true
        },
        
        "extends": {
            "type": [ { "$ref": "#" }, "array" ],
            "items": { "$ref": "#" },
            "default": {}
        },
        
        "id": {
            "type": "string",
            "format": "uri"
        },
        
        "$ref": {
            "type": "string",
            "format": "uri"
        },
        
        "$schema": {
            "type": "string",
            "format": "uri"
        }
    },
    
    "dependencies": {
        "exclusiveMinimum": "minimum",
        "exclusiveMaximum": "maximum"
    },
    
    "default": {}
}
END_JSON

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::AsType::Draft3 - Role processing draft3 JSON Schema 

=head1 VERSION

version 0.4.4

=head1 DESCRIPTION

This role is not intended to be used directly. It is used internally
by L<JSON::Schema::AsType> objects.

Importing this module auto-populate the Draft3 schema in the
L<JSON::Schema::AsType> schema cache.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
