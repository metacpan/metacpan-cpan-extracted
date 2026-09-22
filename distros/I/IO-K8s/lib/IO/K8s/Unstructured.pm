package IO::K8s::Unstructured;
# ABSTRACT: Untyped Kubernetes object for a Kind nothing else resolves
our $VERSION = '1.108';
use IO::K8s::Resource;


k8s apiVersion => Str;


k8s kind => Str;


k8s metadata => 'Meta::V1::ObjectMeta';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Unstructured - Untyped Kubernetes object for a Kind nothing else resolves

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    use IO::K8s::Unstructured;

    my $obj = IO::K8s::Unstructured->FROM_HASH({
        apiVersion => 'example.com/v1',
        kind       => 'Widget',
        metadata   => { name => 'my-widget' },
        spec       => { color => 'blue' },
    });

    $obj->apiVersion;      # 'example.com/v1'
    $obj->kind;            # 'Widget'
    $obj->metadata->name;  # 'my-widget'
    $obj->TO_JSON;         # retains the 'spec' value for re-emission

    # Opt-in fallback for a Kind no shipped or AutoGen'd class resolves:
    my $k8s = IO::K8s->new(unknown_kinds => 'unstructured');
    my $obj = $k8s->inflate($document);  # an Unstructured instead of a die

=head1 DESCRIPTION

C<apiVersion>, C<kind> and C<metadata> are ordinary C<k8s>-declared
attributes here, not the fixed identity L<IO::K8s::Role::APIObject> gives a
built-in or CRD class -- there is no C<api_version()>/C<kind()> method pair
to disagree with the document, because this class has no opinion of its own
about what Kind it holds. Every other field on the wire -- C<spec>,
C<status>, or anything else a document happens to carry -- rides in the
L<IO::K8s::Role::Resource/UNKNOWN FIELDS> bag exactly the way an
undeclared field does on any typed class: C<FROM_HASH> keeps it and
C<TO_JSON> re-emits the same Perl value, so an arbitrary custom resource
round-trips semantically with no schema of its own. It does not preserve the
original JSON or YAML bytes, whitespace or key order; C<to_json> emits the
normal canonical JSON encoding.

This is the class L<IO::K8s/inflate> and L<IO::K8s/new_object> build when
the instance was constructed with C<< unknown_kinds => 'unstructured' >>
and the document's C<apiVersion>/C<kind> resolves to no registered class
(built-in, CRD-registered, or AutoGen'd from an C<openapi_spec>) -- see
L<IO::K8s/unknown_kinds>. Bare C<IO::K8s> keeps failing closed by default;
this class is never built without the caller opting in.

C<< strict => 1 >> is exempted for this fallback specifically: L<IO::K8s>
localizes C<$IO::K8s::Resource::STRICT> for the whole C<inflate>/
C<new_object> call, but this class has nothing else declared to check a
field against -- every field beyond C<apiVersion>/C<kind>/C<metadata> is
precisely what it exists to preserve, so C<strict> would otherwise make it
die on the very data it is supposed to keep. A registered Kind with an
unexpected field still dies under C<strict> as normal; only the
already-unresolvable-Kind fallback this class represents is exempt.

=head2 apiVersion

The document's C<apiVersion>, taken verbatim -- ordinary data, not a fixed
identity method.

=head2 kind

The document's C<kind>, taken verbatim -- ordinary data, not a fixed
identity method.

=head2 metadata

Typed the same way every top-level Kubernetes object types it: an
L<IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta>.

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
