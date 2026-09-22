package IO::K8s::ExternalSecrets::V1::CRDProviderResource;
# ABSTRACT: Resource identifies the CRD by its API group, version and kind.
our $VERSION = '1.108';
use utf8;
use IO::K8s::Resource;

k8s group   => Str, { required => 'schema' };
k8s kind    => Str, { required => 'schema' };
k8s version => Str, { required => 'schema' };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::CRDProviderResource - Resource identifies the CRD by its API group, version and kind.

=head1 VERSION

version 1.108

=head2 group

Group is the API group of the resource. Use "" (empty string) for core
Kubernetes resources such as ConfigMap; use e.g. "config.example.io"
for a CRD. The field is required to be present in the manifest — write
`group: ""` explicitly for core resources so typos fail at admission
time rather than later at discovery.

=head2 kind

Kind is the Kubernetes resource kind (e.g. "MyCustomResource").

=head2 version

Version is the API version of the resource (e.g. "v1alpha1").

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
