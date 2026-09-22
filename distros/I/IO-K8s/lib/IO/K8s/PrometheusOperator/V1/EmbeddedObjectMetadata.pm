package IO::K8s::PrometheusOperator::V1::EmbeddedObjectMetadata;
# ABSTRACT: metadata defines EmbeddedMetadata contains metadata relevant to an EmbeddedResource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s annotations => { Str => 1 };
k8s labels      => { Str => 1 };
k8s name        => Str;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::EmbeddedObjectMetadata - metadata defines EmbeddedMetadata contains metadata relevant to an EmbeddedResource.

=head1 VERSION

version 1.108

=head2 annotations

annotations defines an unstructured key value map stored with a resource that may be
set by external tools to store and retrieve arbitrary metadata. They are not
queryable and should be preserved when modifying objects.
More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/

=head2 labels

labels define the map of string keys and values that can be used to organize and categorize
(scope and select) objects. May match selectors of replication controllers
and services.
More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/

=head2 name

name must be unique within a namespace. Is required when creating resources, although
some resources may allow a client to request the generation of an appropriate name
automatically. Name is primarily intended for creation idempotence and configuration
definition.
Cannot be updated.
More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/

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
