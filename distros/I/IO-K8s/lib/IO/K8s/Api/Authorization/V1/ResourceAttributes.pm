package IO::K8s::Api::Authorization::V1::ResourceAttributes;
# ABSTRACT: ResourceAttributes includes the authorization attributes available for resource requests to the Authorizer interface
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s fieldSelector => 'Authorization::V1::FieldSelectorAttributes';


k8s group => Str;


k8s labelSelector => 'Authorization::V1::LabelSelectorAttributes';


k8s name => Str;


k8s namespace => Str;


k8s resource => Str;


k8s subresource => Str;


k8s verb => Str;


k8s version => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Authorization::V1::ResourceAttributes - ResourceAttributes includes the authorization attributes available for resource requests to the Authorizer interface

=head1 VERSION

version 1.100

=head2 fieldSelector

fieldSelector describes the limitation on access based on field.  It can only limit access, not broaden it.

This field  is alpha-level. To use this field, you must enable the `AuthorizeWithSelectors` feature gate (disabled by default).

=head2 group

Group is the API Group of the Resource.  "*" means all.

=head2 labelSelector

labelSelector describes the limitation on access based on labels.  It can only limit access, not broaden it.

This field  is alpha-level. To use this field, you must enable the `AuthorizeWithSelectors` feature gate (disabled by default).

=head2 name

Name is the name of the resource being requested for a "get" or deleted for a "delete". "" (empty) means all.

=head2 namespace

Namespace is the namespace of the action being requested.  Currently, there is no distinction between no namespace and all namespaces "" (empty) is defaulted for LocalSubjectAccessReviews "" (empty) is empty for cluster-scoped resources "" (empty) means "all" for namespace scoped resources from a SubjectAccessReview or SelfSubjectAccessReview

=head2 resource

Resource is one of the existing resource types.  "*" means all.

=head2 subresource

Subresource is one of the existing resource types.  "" means none.

=head2 verb

Verb is a kubernetes resource API verb, like: get, list, watch, create, update, delete, proxy.  "*" means all.

=head2 version

Version is the API Version of the Resource.  "*" means all.

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
