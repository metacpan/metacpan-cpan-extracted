package IO::K8s::ExternalSecrets::V1::MachineIdentityScopeInWorkspace;
# ABSTRACT: SecretsScope defines the scope of the secrets within the workspace
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s environmentSlug        => Str, { required => 'schema' };
k8s expandSecretReferences => Bool, { default => 1 };
k8s organizationSlug       => Str;
k8s projectSlug            => Str, { required => 'schema' };
k8s recursive              => Bool, { default => 0 };
k8s secretsPath            => Str, { default => '/' };







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::MachineIdentityScopeInWorkspace - SecretsScope defines the scope of the secrets within the workspace

=head1 VERSION

version 1.108

=head2 environmentSlug

EnvironmentSlug is the required slug identifier for the environment.

=head2 expandSecretReferences

ExpandSecretReferences indicates whether secret references should be expanded. Defaults to true if not provided.

=head2 organizationSlug

OrganizationSlug is the optional slug that identifies the organization that will be used
during authentication. Useful for sub-organization setups

=head2 projectSlug

ProjectSlug is the required slug identifier for the project.

=head2 recursive

Recursive indicates whether the secrets should be fetched recursively. Defaults to false if not provided.

=head2 secretsPath

SecretsPath specifies the path to the secrets within the workspace. Defaults to "/" if not provided.

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
