package IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSON;
# ABSTRACT: JSON represents any valid JSON value. These types are supported: bool, int64, float64, string, []interface{}, map[string]interface{} and nil.
our $VERSION = '1.107';
use v5.10;
use Moo;
use JSON::MaybeXS ();


has value => (
    is => 'rw',
);


sub _build_json {
    return JSON::MaybeXS->new(utf8 => 1, canonical => 1, allow_nonref => 1);
}


sub FROM_STRUCT {
    my ($class, $struct, $k8s) = @_;
    return $class->new(value => $struct);
}


sub TO_JSON {
    my ($self) = @_;
    return $self->value;
}

with 'IO::K8s::Role::Resource';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSON - JSON represents any valid JSON value. These types are supported: bool, int64, float64, string, []interface{}, map[string]interface{} and nil.

=head1 VERSION

version 1.107

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

=head2 value

The wrapped value. Any Perl structure that survives JSON encoding: a plain
scalar, a hashref, an arrayref, a JSON boolean, or C<undef>.

=head2 FROM_STRUCT

    my $json = $class->FROM_STRUCT($struct, $k8s);

Inflation hook called by L<IO::K8s/struct_to_object>. Wraps C<$struct> verbatim.

=head2 TO_JSON

Returns the wrapped value unchanged.

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
