package IO::K8s::ExternalSecrets::V1::CRDProviderWhitelistRule;
# ABSTRACT: CRDProviderWhitelistRule defines a single allow rule for CRD reads.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s name       => Str;
k8s namespace  => Str;
k8s properties => [Str];




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::CRDProviderWhitelistRule - CRDProviderWhitelistRule defines a single allow rule for CRD reads.

=head1 VERSION

version 1.108

=head2 name

Name is an optional regular expression matched against the bare object name.
For both SecretStore and ClusterSecretStore this is always the object name
without any namespace prefix (e.g. "my-db-spec", not "prod/my-db-spec").

=head2 namespace

Namespace is an optional regular expression matched against the namespace of
the object. Applies only when a ClusterSecretStore is used; it is ignored
for SecretStore (where the namespace is fixed to the store namespace).

=head2 properties

Properties is an optional list of regular expressions matched against
requested property keys (for example: "spec.secretValue").

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
