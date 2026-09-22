package IO::K8s::ExternalSecrets::V1alpha1::GitlabDeployTokenSpec;
# ABSTRACT: GitlabDeployTokenSpec defines the desired state to generate a GitLab deploy token.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth      => '+IO::K8s::ExternalSecrets::V1alpha1::GitlabTokenAuth', { required => 'schema' };
k8s expiresAt => Time;
k8s groupID   => Str;
k8s name      => Str, { required => 'schema' };
k8s projectID => Str;
k8s scopes    => [Str], { required => 'schema', enum => [qw(read_repository read_registry write_registry read_package_registry write_package_registry read_virtual_registry write_virtual_registry)] };
k8s url       => Str;
k8s username  => Str;









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::GitlabDeployTokenSpec - GitlabDeployTokenSpec defines the desired state to generate a GitLab deploy token.

=head1 VERSION

version 1.108

=head2 auth

Auth configures how ESO authenticates with the GitLab API.

=head2 expiresAt

ExpiresAt is an optional expiry for the deploy token. If omitted the token does
not expire on the GitLab side and is revoked only when the generator state is
cleaned up (on regeneration or when the consuming ExternalSecret is deleted).

=head2 groupID

GroupID is the numeric ID or unescaped path (e.g. parent/group) of the group to
create the deploy token in. The generator URL-escapes paths before calling the
GitLab API, so do not pre-encode. Mutually exclusive with projectID.

=head2 name

Name of the deploy token.

=head2 projectID

ProjectID is the numeric ID or unescaped path (e.g. group/project) of the
project to create the deploy token in. The generator URL-escapes paths before
calling the GitLab API, so do not pre-encode. Mutually exclusive with groupID.

=head2 scopes

Scopes granted to the deploy token. At least one scope is required.

=head2 url

URL configures the GitLab instance URL. Defaults to https://gitlab.com.

=head2 username

Username is an optional username for the deploy token. GitLab defaults it to
gitlab+deploy-token-{n} when omitted.

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
