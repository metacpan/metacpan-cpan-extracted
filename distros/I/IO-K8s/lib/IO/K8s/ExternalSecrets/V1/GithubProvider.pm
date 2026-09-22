package IO::K8s::ExternalSecrets::V1::GithubProvider;
# ABSTRACT: Github configures this store to push GitHub Actions or Dependabot secrets using the GitHub API provider.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s appID               => Int, { required => 'schema' };
k8s auth                => '+IO::K8s::ExternalSecrets::V1::GithubAppAuth', { required => 'schema' };
k8s environment         => Str;
k8s installationID      => Int, { required => 'schema' };
k8s orgSecretVisibility => Str, { enum => [qw(all private)] };
k8s organization        => Str, { required => 'schema' };
k8s repository          => Str;
k8s secretType          => Str, { enum => [qw(Actions Dependabot)], default => 'Actions' };
k8s uploadURL           => Str;
k8s url                 => Str, { default => 'https://github.com/' };











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::GithubProvider - Github configures this store to push GitHub Actions or Dependabot secrets using the GitHub API provider.

=head1 VERSION

version 1.108

=head2 appID

appID specifies the Github APP that will be used to authenticate the client

=head2 auth

auth configures how secret-manager authenticates with a Github instance.

=head2 environment

environment will be used to fetch secrets from a particular environment within a github repository

=head2 installationID

installationID specifies the Github APP installation that will be used to authenticate the client

=head2 orgSecretVisibility

orgSecretVisibility controls the visibility of organization secrets pushed via PushSecret.
Valid values are "all" or "private".
When unset, new secrets are created with visibility "all" and existing secrets preserve
whatever visibility they already have in GitHub.

=head2 organization

organization will be used to fetch secrets from the Github organization

=head2 repository

repository will be used to fetch secrets from the Github repository within an organization

=head2 secretType

secretType specifies which GitHub secret service to use.
Defaults to Actions for backwards compatibility.

=head2 uploadURL

Upload URL for enterprise instances. Default to URL.

=head2 url

URL configures the Github instance URL. Defaults to https://github.com/.

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
