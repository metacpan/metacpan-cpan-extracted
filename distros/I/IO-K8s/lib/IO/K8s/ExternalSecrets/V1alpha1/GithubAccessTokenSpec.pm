package IO::K8s::ExternalSecrets::V1alpha1::GithubAccessTokenSpec;
# ABSTRACT: GithubAccessTokenSpec defines the desired state to generate a GitHub access token.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s appID        => Str, { required => 'schema' };
k8s auth         => '+IO::K8s::ExternalSecrets::V1alpha1::GithubAuth', { required => 'schema' };
k8s installID    => Str, { required => 'schema' };
k8s permissions  => { Str => 1 };
k8s repositories => [Str];
k8s url          => Str;







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::GithubAccessTokenSpec - GithubAccessTokenSpec defines the desired state to generate a GitHub access token.

=head1 VERSION

version 1.108

=head2 appID

No description in the upstream schema.

=head2 auth

Auth configures how ESO authenticates with a Github instance.

=head2 installID

No description in the upstream schema.

=head2 permissions

Map of permissions the token will have. If omitted, defaults to all permissions the GitHub App has.

=head2 repositories

List of repositories the token will have access to. If omitted, defaults to all repositories the GitHub App
is installed to.

=head2 url

URL configures the GitHub instance URL. Defaults to https://github.com/.

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
