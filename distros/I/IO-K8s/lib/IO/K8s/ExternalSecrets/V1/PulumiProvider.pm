package IO::K8s::ExternalSecrets::V1::PulumiProvider;
# ABSTRACT: Pulumi configures this store to sync secrets using the Pulumi provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s accessToken  => '+IO::K8s::ExternalSecrets::V1::PulumiProviderSecretRef';
k8s apiUrl       => Str, { default => 'https://api.pulumi.com/api/esc' };
k8s auth         => '+IO::K8s::ExternalSecrets::V1::PulumiAuth';
k8s environment  => Str, { required => 'schema' };
k8s organization => Str, { required => 'schema' };
k8s project      => Str, { required => 'schema' };







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::PulumiProvider - Pulumi configures this store to sync secrets using the Pulumi provider

=head1 VERSION

version 1.108

=head2 accessToken

AccessToken is the access tokens to sign in to the Pulumi Cloud Console.

Deprecated: Use auth.accessToken instead.

=head2 apiUrl

APIURL is the URL of the Pulumi API.

=head2 auth

Auth configures how the Operator authenticates with the Pulumi API.
Either auth or the deprecated accessToken field must be specified.

=head2 environment

Environment are YAML documents composed of static key-value pairs, programmatic expressions,
dynamically retrieved values from supported providers including all major clouds,
and other Pulumi ESC environments.
To create a new environment, visit https://www.pulumi.com/docs/esc/environments/ for more information.

=head2 organization

Organization are a space to collaborate on shared projects and stacks.
To create a new organization, visit https://app.pulumi.com/ and click "New Organization".

=head2 project

Project is the name of the Pulumi ESC project the environment belongs to.

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
