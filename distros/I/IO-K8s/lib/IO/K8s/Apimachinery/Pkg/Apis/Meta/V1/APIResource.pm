package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIResource;
# ABSTRACT: APIResource specifies the name of a resource and whether it is namespaced.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s categories => [Str];


k8s group => Str;


k8s kind => Str, 'required';


k8s name => Str, 'required';


k8s namespaced => Bool, 'required';


k8s shortNames => [Str];


k8s singularName => Str, 'required';


k8s storageVersionHash => Str;


k8s verbs => [Str], 'required';


k8s version => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIResource - APIResource specifies the name of a resource and whether it is namespaced.

=head1 VERSION

version 1.009

=head2 categories

categories is a list of the grouped resources this resource belongs to (e.g. 'all')

=head2 group

group is the preferred group of the resource.  Empty implies the group of the containing resource list. For subresources, this may have a different value, for example: Scale".

=head2 kind

kind is the kind for the resource (e.g. 'Foo' is the kind for a resource 'foo')

=head2 name

name is the plural name of the resource.

=head2 namespaced

namespaced indicates if a resource is namespaced or not.

=head2 shortNames

shortNames is a list of suggested short names of the resource.

=head2 singularName

singularName is the singular name of the resource.  This allows clients to handle plural and singular opaquely. The singularName is more correct for reporting status on a single item and both singular and plural are allowed from the kubectl CLI interface.

=head2 storageVersionHash

The hash value of the storage version, the version this resource is converted to when written to the data store. Value must be treated as opaque by clients. Only equality comparison on the value is valid. This is an alpha feature and may change or be removed in the future. The field is populated by the apiserver only if the StorageVersionHash feature gate is enabled. This field will remain optional even if it graduates.

=head2 verbs

verbs is a list of supported kube verbs (this includes get, list, watch, create, update, patch, delete, deletecollection, and proxy)

=head2 version

version is the preferred version of the resource.  Empty implies the version of the containing resource list For subresources, this may have a different value, for example: v1 (while inside a v1beta1 version of the core resource's group)".

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
