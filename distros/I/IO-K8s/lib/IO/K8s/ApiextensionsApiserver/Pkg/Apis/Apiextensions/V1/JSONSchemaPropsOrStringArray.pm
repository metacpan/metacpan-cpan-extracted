package IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrStringArray;
# ABSTRACT: JSONSchemaPropsOrStringArray represents a JSONSchemaProps or a string array.
our $VERSION = '1.107';
use v5.10;
use Moo;
use Types::Standard qw( ArrayRef InstanceOf Maybe Str );
use JSON::MaybeXS ();

my $PROPS = 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps';


has schema => (
    is  => 'rw',
    isa => Maybe[InstanceOf[$PROPS]],
);


has property => (
    is  => 'rw',
    isa => Maybe[ArrayRef[Str]],
);


sub _build_json {
    return JSON::MaybeXS->new(utf8 => 1, canonical => 1, allow_nonref => 1);
}


sub is_schema {
    my ($self) = @_;
    return defined $self->property ? 0 : 1;
}


sub FROM_STRUCT {
    my ($class, $struct, $k8s) = @_;

    # Stringify so the arm always serializes as JSON strings; undef is left
    # alone so the ArrayRef[Str] constraint reports it instead of quietly
    # turning it into an empty string.
    return $class->new(property => [ map { defined($_) ? "$_" : undef } @$struct ])
        if ref $struct eq 'ARRAY';

    $k8s //= do { require IO::K8s; IO::K8s->new };
    return $class->new(schema => $k8s->struct_to_object($PROPS, $struct));
}


sub TO_JSON {
    my ($self) = @_;
    my $property = $self->property;
    return [ @$property ] if defined $property;
    my $schema = $self->schema;
    return defined $schema ? $schema->TO_JSON : undef;
}

with 'IO::K8s::Role::Resource';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrStringArray - JSONSchemaPropsOrStringArray represents a JSONSchemaProps or a string array.

=head1 VERSION

version 1.107

=head1 DESCRIPTION

The union type behind the values of C<dependencies> in a CRD schema. Upstream
it serializes as the bare alternative, never as a tagged wrapper:

    dependencies:
      creditCard: [ billingAddress ]   # string array -> property
      shipping:   { type: object }     # schema       -> schema

Exactly one arm is populated, and which one it was survives a round trip.

    my $dep = $props->dependencies->{creditCard};
    if ($dep->is_schema) { ... $dep->schema   ... }
    else                 { ... $dep->property ... }

=head2 schema

The schema arm: a
L<IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps>,
or C<undef> when the string array arm is in use.

=head2 property

The string array arm: an ArrayRef of property names, or C<undef> when the
schema arm is in use. An empty ArrayRef is a populated arm and serializes as
C<[]>.

=head2 is_schema

True when the schema arm is in use, false when the string array arm is.

=head2 FROM_STRUCT

    my $dep = $class->FROM_STRUCT($struct, $k8s);

Inflation hook called by L<IO::K8s/struct_to_object>. An ArrayRef fills
C<property>, anything else fills C<schema>.

=head2 TO_JSON

Returns the bare arm: an ArrayRef of property names, or the serialized schema.

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
