package IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSON;
# ABSTRACT: JSON represents any valid JSON value. These types are supported: bool, int64, float64, string, []interface{}, map[string]interface{} and nil.
our $VERSION = '1.110';
use v5.10;
use Moo;
use JSON::MaybeXS ();


has value => (
    is => 'rw',
);


sub _build__json_encoder {
    return JSON::MaybeXS->new(utf8 => 1, canonical => 1, allow_nonref => 1);
}


sub FROM_STRUCT {
    my ($class, $struct, $k8s) = @_;
    # One level, not deeper (k169): the depth IO::K8s::_inflate_struct
    # copies an untyped value to (k54). _copy_one_level is the role's,
    # composed into this package by the `with` below and reached unqualified,
    # as IO::K8s::List does -- IO::K8s::_shallow_copy is the same rule but
    # would need IO::K8s loaded for a direct FROM_STRUCT call.
    return $class->new(value => _copy_one_level($struct));
}


sub TO_JSON {
    my ($self) = @_;
    # One level (k171), the output side of FROM_STRUCT's copy (k169);
    # _copy_one_level is the role's, as in FROM_STRUCT above.
    return _copy_one_level($self->value);
}

# The node a spec path walks into (IO::K8s::Role::SpecBuilder, k172): the
# value itself, the live container rather than TO_JSON's copy, so a write
# through the path lands in the object. Free JSON -- no attribute to check
# an element against.
sub _spec_path_node { return ($_[0]->value) }

with 'IO::K8s::Role::Resource';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSON - JSON represents any valid JSON value. These types are supported: bool, int64, float64, string, []interface{}, map[string]interface{} and nil.

=head1 VERSION

version 1.110

=head1 DESCRIPTION

C<apiextensions.k8s.io/v1.JSON> is a free-form value: whatever the CRD author
wrote for C<default>, C<example> or an C<enum> entry. It serializes as the bare
value, not as a wrapper object, so this class only carries the value through
inflation and back out again unchanged.

Inflation goes through L<IO::K8s/struct_to_object>, which hands any class
providing C<FROM_STRUCT> the raw structure instead of treating it as a hashref
of attributes.

    my $props = $k8s->struct_to_object(
        'Apiextensions::V1::JSONSchemaProps',
        { type => 'string', default => 'nginx' },
    );

    $props->default->value;    # 'nginx'
    $props->TO_JSON->{default} # 'nginx' — bare, not { value => 'nginx' }

The C<spec_*> methods of L<IO::K8s::Role::SpecBuilder> walk through a field
of this class into its value, the way the wire JSON reads: on a K3s
HelmChart, C<< spec_set('values.replicaCount', 3) >> serializes as
C<values: {"replicaCount": 3}>.

=head2 value

The wrapped value. Any Perl structure that survives JSON encoding: a plain
scalar, a hashref, an arrayref, a JSON boolean, or C<undef>.

=head2 FROM_STRUCT

    my $json = $class->FROM_STRUCT($struct, $k8s);

Inflation hook called by L<IO::K8s/struct_to_object>. Wraps C<$struct>
unchanged, except that a hash or an array is copied one level -- the rule
inflation applies to every array or hash of scalars. A key added
to or removed from the source hash, or an element pushed onto the source
array, after inflation does not reach the object. A container nested inside
the value is not copied and still shares its contents with the source. A
plain scalar, C<undef> or a JSON boolean is kept as given.

The same hook builds the value a field of this type is given through C<new>,
its setter or a C<spec_*> write of L<IO::K8s::Role::SpecBuilder>, whatever
its shape -- C<< values => [1, 2] >> on a K3s C<HelmChartSpec> as
readily as a hash; see L<IO::K8s::Resource/k8s>.

=head2 TO_JSON

Returns the wrapped value, a hash or an array copied one level -- the same
depth L</FROM_STRUCT> copies on the way in and L<IO::K8s::Role::Resource/TO_JSON>
copies an untyped container on the way out. A key added to or
removed from the returned hash, or an element pushed onto the returned
array, does not reach the object; a container nested inside the value is
still shared with it. A plain scalar, C<undef> or a JSON boolean is returned
as it is.

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
