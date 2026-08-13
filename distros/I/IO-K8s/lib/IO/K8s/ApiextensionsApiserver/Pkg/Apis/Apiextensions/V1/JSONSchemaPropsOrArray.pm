package IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrArray;
# ABSTRACT: JSONSchemaPropsOrArray represents a value that can either be a JSONSchemaProps or an array of JSONSchemaProps. Mainly here for serialization purposes.
our $VERSION = '1.106';
use v5.10;
use Moo;
use Types::Standard qw( ArrayRef InstanceOf Maybe );
use JSON::MaybeXS ();

my $PROPS = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps';


has schema => (
    is  => 'rw',
    isa => Maybe[InstanceOf[$PROPS]],
);


has schemas => (
    is  => 'rw',
    isa => Maybe[ArrayRef[InstanceOf[$PROPS]]],
);


sub _build_json {
    return JSON::MaybeXS->new(utf8 => 1, canonical => 1, allow_nonref => 1);
}


sub is_schema {
    my ($self) = @_;
    return defined $self->schemas ? 0 : 1;
}


sub FROM_STRUCT {
    my ($class, $struct, $k8s) = @_;
    $k8s //= do { require IO::K8s; IO::K8s->new };

    return $class->new(
        schemas => [ map { $k8s->struct_to_object($PROPS, $_) } @$struct ],
    ) if ref $struct eq 'ARRAY';

    return $class->new(schema => $k8s->struct_to_object($PROPS, $struct));
}


sub TO_JSON {
    my ($self) = @_;
    my $schemas = $self->schemas;
    return [ map { $_->TO_JSON } @$schemas ] if defined $schemas;
    my $schema = $self->schema;
    return defined $schema ? $schema->TO_JSON : undef;
}

with 'IO::K8s::Role::Resource';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrArray - JSONSchemaPropsOrArray represents a value that can either be a JSONSchemaProps or an array of JSONSchemaProps. Mainly here for serialization purposes.

=head1 VERSION

version 1.106

=head1 DESCRIPTION

The union type behind C<items> in a CRD schema. Upstream it serializes as the
bare alternative, never as a tagged wrapper:

    items: { type: string }        # single schema  -> schema
    items: [ {...}, {...} ]        # tuple          -> schemas

Exactly one arm is populated, and which one it was survives a round trip: a
single schema never turns into a one-element array, and an array never
collapses into a single schema.

    my $items = $props->items;
    if ($items->is_schema) { ... $items->schema  ... }
    else                   { ... $items->schemas ... }

=head2 schema

The single-schema arm: a
L<IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps>,
or C<undef> when the array arm is in use.

=head2 schemas

The array arm: an ArrayRef of C<JSONSchemaProps>, or C<undef> when the single
schema arm is in use. An empty ArrayRef is a populated arm and serializes as
C<[]>.

=head2 is_schema

True when the single-schema arm is in use, false when the array arm is.

=head2 FROM_STRUCT

    my $items = $class->FROM_STRUCT($struct, $k8s);

Inflation hook called by L<IO::K8s/struct_to_object>. An ArrayRef fills
C<schemas>, anything else fills C<schema>.

=head2 TO_JSON

Returns the bare arm: an ArrayRef of serialized schemas, or the single
serialized schema.

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
