package JSON::Schema::Shorthand;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Alternative, condensed format for JSON Schemas
$JSON::Schema::Shorthand::VERSION = '0.0.2';
use strict;
use warnings;

use 5.20.0;

use experimental 'postderef';

use parent 'Exporter::Tiny';

our @EXPORT = ( 'js_shorthand' );

use Clone qw/ clone /;

sub js_shorthand {
    my $object = clone( shift );

    unless( ref $object ) {
        $object = { ( ( '#' eq substr $object, 0, 1 ) ? '$ref' : 'type' ) => $object };
    }

    if ( my $array = delete $object->{array} ) {
        $object->{type} = 'array';
        $object->{items} = ref $array eq 'ARRAY'
            ? [ map { js_shorthand($_) } @$array ]
            : js_shorthand( $array )
            ;
    }

    if( my $props = delete $object->{object} ) {
        $object->{type} = 'object';
        $object->{properties} = $props;
    }

    # foo => { bar => $schema }
    for my $keyword ( qw/ definitions properties / ) {
        next unless $object->{$keyword};
        $_ = js_shorthand($_) for values %{ $object->{$keyword} };
    }

    # foo => [ @schemas ]
    for my $keyword ( qw/ anyOf allOf oneOf / ) {
        next unless $object->{$keyword};
        $object->{$keyword} = [
            map { js_shorthand($_) } $object->{$keyword}->@*
        ];
    }

    # foo => $schemas
    for my $keyword ( qw/ not / ) {
        next unless $object->{$keyword};
        $object->{$keyword} = js_shorthand($object->{$keyword});
    }

    # required attribute
    if ( $object->{properties} ) {
        my @required = grep { 
            delete $object->{properties}{$_}{required} 
        } keys $object->{properties}->%*;

        $object->{required} = [
            eval { $object->{required}->@* },
            @required
        ] if @required;
    }

    return $object;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::Shorthand - Alternative, condensed format for JSON Schemas

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use JSON::Schema::Shorthand;

    my $schema = js_shorthand({
        object => { foo => 'number', bar => { type => 'string', required => 1 }         
    });

    # $schema is 
    # { 
    #   type => 'object',
    #   properties => {
    #       foo => { type => 'number' },
    #       bar => { type => string },
    #  }
    #  required => [ 'bar' ],
    # }

=head1 DESCRIPTION

JSON Schema 
is a useful beast, 
but its schema definition can be a little bit more long-winded
than necessary. This module allows to use a few shortcuts that
will be expanded into their canonical form.

B<CAVEAT>: the module is still very young, and there are plenty of
properties this module should expand and does not. So don't trust it
blindly. If you  hit such a case, raise a ticket and I'll refine the process.

=head2 js_shorthand

    my $schema = js_shorthand $shorthand;

The module exports a single function, C<js_shorthand>, that takes in 
a JSON schema in shorthand notation and returns the expanded, canonical schema
form.

If you don't like the name C<js_shorthand>, you can always import it
under a different name in your namespace.

    use JSON::Schema::Shorthand 'js_shorthand' => { -as => 'expand_json_schema' };

    ...;

    my $schema = expand_json_schema $shorthand;

=head2Shorthands

=head3 Types as string

If a string C<type> is encountered where a property definition is 
expected, the string is expanded to the object C<{ "type": type }>.

    {
        "foo": "number",
        "bar": "string"
    }

expands to

    {
        "foo": { "type": "number" },
        "bar": { "type": "string" }
    }

If the string begins with a C<#>, the type is assumed to be a reference and
C<#type> is expanded to C<{ "$ref": type }>.

    { "foo": "#/definitions/bar" } 

becomes

    { "foo": { "$ref": "#/definitions/bar" } }

=head3 C<object> property

C<{ object: properties }> expands to C<{ type: "object", properties }>.

    shorthand                              expanded
    ------------------------               ---------------------------
    foo: {                                  foo: {
        object: {                               type: "object",
            bar: { }                            properties: {
        }                                           bar: { }
    }                                           }
                                            }

=head3 C<array> property

C<{ array: items }> expands to C<{ type: "array", items }>.

    shorthand                              expanded
    ------------------------               ---------------------------
    foo: {                                  foo: {
        array: 'number'                         type: "array",
    }                                           items: {
                                                    type: 'number' 
                                                }
                                            }

=head3 C<required> property

If the C<required> attribute is set to C<true> for a property, it is bubbled
up to the C<required> attribute of its parent object.

    shorthand                              expanded
    ------------------------               ---------------------------

    foo: {                                  foo: {
        properties: {                           required: [ 'bar' ],
          bar: { required: true },              properties: { 
          baz: { }                                bar: {},
        }                                         baz: {}
    }                                       }

=head1 SEE ALSO

* JSON Schema specs - L<http://json-schema.org/>

* JavaScript version of this module - L<http://github.com/yanick/json-shema-shorthand>

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
