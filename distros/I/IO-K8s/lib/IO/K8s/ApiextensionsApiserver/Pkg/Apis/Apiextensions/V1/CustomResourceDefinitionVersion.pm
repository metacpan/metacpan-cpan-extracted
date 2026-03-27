package IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionVersion;
# ABSTRACT: CustomResourceDefinitionVersion describes a version for CRD.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s additionalPrinterColumns => ['Apiextensions::V1::CustomResourceColumnDefinition'];


k8s deprecated => Bool;


k8s deprecationWarning => Str;


k8s name => Str, 'required';


k8s schema => 'Apiextensions::V1::CustomResourceValidation';


k8s selectableFields => ['Apiextensions::V1::SelectableField'];


k8s served => Bool, 'required';


k8s storage => Bool, 'required';


k8s subresources => 'Apiextensions::V1::CustomResourceSubresources';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionVersion - CustomResourceDefinitionVersion describes a version for CRD.

=head1 VERSION

version 1.100

=head2 additionalPrinterColumns

additionalPrinterColumns specifies additional columns returned in Table output. See https://kubernetes.io/docs/reference/using-api/api-concepts/#receiving-resources-as-tables for details. If no columns are specified, a single column displaying the age of the custom resource is used.

=head2 deprecated

deprecated indicates this version of the custom resource API is deprecated. When set to true, API requests to this version receive a warning header in the server response. Defaults to false.

=head2 deprecationWarning

deprecationWarning overrides the default warning returned to API clients. May only be set when `deprecated` is true. The default warning indicates this version is deprecated and recommends use of the newest served version of equal or greater stability, if one exists.

=head2 name

name is the version name, e.g. "v1", "v2beta1", etc. The custom resources are served under this version at `/apis/<group>/<version>/...` if `served` is true.

=head2 schema

schema describes the schema used for validation, pruning, and defaulting of this version of the custom resource.

=head2 selectableFields

selectableFields specifies paths to fields that may be used as field selectors. A maximum of 8 selectable fields are allowed. See https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors

=head2 served

served is a flag enabling/disabling this version from being served via REST APIs

=head2 storage

storage indicates this version should be used when persisting custom resources to storage. There must be exactly one version with storage=true.

=head2 subresources

subresources specify what subresources this version of the defined custom resource have.

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
