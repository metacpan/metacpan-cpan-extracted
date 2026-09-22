package IO::K8s::ExternalSecrets::V1::ExternalSecretTarget;
# ABSTRACT: ExternalSecretTarget defines the Kubernetes Secret to be created, there can be only one target per ExternalSecret.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s creationPolicy => Str, { enum => [qw(Owner Orphan Merge None CreateOrMerge)], default => 'Owner' };
k8s deletionPolicy => Str, { enum => [qw(Delete Merge Retain)], default => 'Retain' };
k8s immutable      => Bool;
k8s manifest       => 'Admissionregistration::V1::ParamKind';
k8s name           => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s template       => '+IO::K8s::ExternalSecrets::V1::ExternalSecretTemplate';







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ExternalSecretTarget - ExternalSecretTarget defines the Kubernetes Secret to be created, there can be only one target per ExternalSecret.

=head1 VERSION

version 1.108

=head2 creationPolicy

CreationPolicy defines rules on how to create the resulting Secret.
Defaults to "Owner"

=head2 deletionPolicy

DeletionPolicy defines rules on how to delete the resulting Secret.
Defaults to "Retain"

=head2 immutable

Immutable defines if the final secret will be immutable

=head2 manifest

Manifest defines a custom Kubernetes resource to create instead of a Secret.
When specified, ExternalSecret will create the resource type defined here
(e.g., ConfigMap, Custom Resource) instead of a Secret.
Warning: Using Generic target. Make sure access policies and encryption are properly configured.

=head2 name

The name of the Secret resource to be managed.
Defaults to the .metadata.name of the ExternalSecret resource

=head2 template

Template defines a blueprint for the created Secret resource.

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
