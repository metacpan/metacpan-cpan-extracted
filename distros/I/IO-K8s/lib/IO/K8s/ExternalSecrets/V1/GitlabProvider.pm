package IO::K8s::ExternalSecrets::V1::GitlabProvider;
# ABSTRACT: GitLab configures this store to sync secrets using GitLab Variables provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth              => '+IO::K8s::ExternalSecrets::V1::GitlabAuth', { required => 'schema' };
k8s caBundle          => Str;
k8s caProvider        => '+IO::K8s::ExternalSecrets::V1::CAProvider';
k8s environment       => Str;
k8s groupIDs          => [Str];
k8s inheritFromGroups => Bool;
k8s projectID         => Str;
k8s url               => Str;









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::GitlabProvider - GitLab configures this store to sync secrets using GitLab Variables provider

=head1 VERSION

version 1.108

=head2 auth

Auth configures how secret-manager authenticates with a GitLab instance.

=head2 caBundle

Base64 encoded certificate for the GitLab server sdk. The sdk MUST run with HTTPS to make sure no MITM attack
can be performed.

=head2 caProvider

see: https://external-secrets.io/latest/spec/#external-secrets.io/v1alpha1.CAProvider

=head2 environment

Environment environment_scope of gitlab CI/CD variables (Please see https://docs.gitlab.com/ee/ci/environments/#create-a-static-environment on how to create environments)

=head2 groupIDs

GroupIDs specify, which gitlab groups to pull secrets from. Group secrets are read from left to right followed by the project variables.

=head2 inheritFromGroups

InheritFromGroups specifies whether parent groups should be discovered and checked for secrets.

=head2 projectID

ProjectID specifies a project where secrets are located.

=head2 url

URL configures the GitLab instance URL. Defaults to https://gitlab.com/.

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
