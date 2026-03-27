package IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionSpec;
# ABSTRACT: CustomResourceDefinitionSpec describes how a user wants their resource to appear
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s conversion => 'Apiextensions::V1::CustomResourceConversion';


k8s group => Str, 'required';


k8s names => 'Apiextensions::V1::CustomResourceDefinitionNames', 'required';


k8s preserveUnknownFields => Bool;


k8s scope => Str, 'required';


k8s versions => ['Apiextensions::V1::CustomResourceDefinitionVersion'], 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionSpec - CustomResourceDefinitionSpec describes how a user wants their resource to appear

=head1 VERSION

version 1.100

=head2 conversion

conversion defines conversion settings for the CRD.

=head2 group

group is the API group of the defined custom resource. The custom resources are served under `/apis/<group>/...`. Must match the name of the CustomResourceDefinition (in the form `<names.plural>.<group>`).

=head2 names

names specify the resource and kind names for the custom resource.

=head2 preserveUnknownFields

preserveUnknownFields indicates that object fields which are not specified in the OpenAPI schema should be preserved when persisting to storage. apiVersion, kind, metadata and known fields inside metadata are always preserved. This field is deprecated in favor of setting `x-preserve-unknown-fields` to true in `spec.versions[*].schema.openAPIV3Schema`. See https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#field-pruning for details.

=head2 scope

scope indicates whether the defined custom resource is cluster- or namespace-scoped. Allowed values are `Cluster` and `Namespaced`.

=head2 versions

versions is the list of all API versions of the defined custom resource. Version names are used to compute the order in which served versions are listed in API discovery. If the version string is "kube-like", it will sort above non "kube-like" version strings, which are ordered lexicographically. "Kube-like" versions start with a "v", then are followed by a number (the major version), then optionally the string "alpha" or "beta" and another number (the minor version). These are sorted first by GA > beta > alpha (where GA is a version with no suffix such as beta or alpha), and then by comparing major version, then minor version. An example sorted list of versions: v10, v2, v1, v11beta2, v10beta3, v3beta1, v12alpha1, v11alpha2, foo1, foo10.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
