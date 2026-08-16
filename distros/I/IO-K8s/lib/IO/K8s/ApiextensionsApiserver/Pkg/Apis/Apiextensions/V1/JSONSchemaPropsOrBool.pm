package IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool;
# ABSTRACT: JSONSchemaPropsOrBool represents JSONSchemaProps or a boolean value. Defaults to true for the boolean property.
our $VERSION = '1.107';
use v5.10;
use Moo;
use Types::Standard qw( Bool InstanceOf Maybe );
use Scalar::Util qw( blessed reftype );
use JSON::MaybeXS ();

my $PROPS = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps';


has schema => (
    is  => 'rw',
    isa => Maybe[InstanceOf[$PROPS]],
);


has allows => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);


sub _build_json {
    return JSON::MaybeXS->new(utf8 => 1, canonical => 1, allow_nonref => 1);
}


sub is_schema {
    my ($self) = @_;
    return defined $self->schema ? 1 : 0;
}


sub FROM_STRUCT {
    my ($class, $struct, $k8s) = @_;

    if (ref $struct eq 'HASH' || (blessed($struct) && $struct->isa($PROPS))) {
        $k8s //= do { require IO::K8s; IO::K8s->new };
        return $class->new(schema => $k8s->struct_to_object($PROPS, $struct));
    }

    # Booleans arrive as JSON::PP::Boolean, \1 / \0, or plain scalars.
    my $bool = $struct;
    $bool = $$bool if ref($bool) && (reftype($bool) // '') eq 'SCALAR';

    return $class->new(allows => $bool ? 1 : 0);
}


sub TO_JSON {
    my ($self) = @_;
    my $schema = $self->schema;
    return $schema->TO_JSON if defined $schema;
    return $self->allows ? JSON::MaybeXS::true() : JSON::MaybeXS::false();
}

with 'IO::K8s::Role::Resource';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool - JSONSchemaPropsOrBool represents JSONSchemaProps or a boolean value. Defaults to true for the boolean property.

=head1 VERSION

version 1.107

=head1 DESCRIPTION

The union type behind C<additionalProperties> and C<additionalItems> in a CRD
schema. Upstream it serializes as the bare alternative, never as a tagged
wrapper:

    additionalProperties: false          # boolean -> allows
    additionalProperties: { type: str }  # schema  -> schema

Exactly one arm is populated, and which one it was survives a round trip:
C<false> stays C<false> and never collapses into an empty schema object.

    my $ap = $props->additionalProperties;
    if ($ap->is_schema) { ... $ap->schema ... }
    else                { ... $ap->allows ... }

=head2 schema

The schema arm: a
L<IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps>,
or C<undef> when the boolean arm is in use.

=head2 allows

The boolean arm, C<0> or C<1>. Defaults to C<1>, matching upstream. Only
consulted when C<schema> is C<undef>.

=head2 is_schema

True when the schema arm is in use, false when the boolean arm is.

=head2 FROM_STRUCT

    my $ap = $class->FROM_STRUCT($struct, $k8s);

Inflation hook called by L<IO::K8s/struct_to_object>. A HashRef (or an already
built C<JSONSchemaProps>) fills C<schema>; anything else is read as a boolean
into C<allows>. JSON booleans, C<\1> / C<\0> scalar refs and the plain scalars
YAML::PP produces are all accepted.

=head2 TO_JSON

Returns the bare arm: the serialized schema, or a JSON boolean.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
