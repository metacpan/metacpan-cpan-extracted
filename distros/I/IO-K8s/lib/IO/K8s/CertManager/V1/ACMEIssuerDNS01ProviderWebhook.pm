package IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderWebhook;
# ABSTRACT: Configure an external webhook based DNS01 challenge solver to manage DNS01 challenge records.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s config     => Str, { preserve_unknown => 1 };
k8s groupName  => Str, { required => 'schema' };
k8s solverName => Str, { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderWebhook - Configure an external webhook based DNS01 challenge solver to manage DNS01 challenge records.

=head1 VERSION

version 1.108

=head2 config

Additional configuration that should be passed to the webhook apiserver
when challenges are processed.
This can contain arbitrary JSON data.
Secret values should not be specified in this stanza.
If secret values are needed (e.g., credentials for a DNS service), you
should use a SecretKeySelector to reference a Secret resource.
For details on the schema of this field, consult the webhook provider
implementation's documentation.

=head2 groupName

The API group name that should be used when POSTing ChallengePayload
resources to the webhook apiserver.
This should be the same as the GroupName specified in the webhook
provider implementation.

=head2 solverName

The name of the solver to use, as defined in the webhook provider
implementation.
This will typically be the name of the provider, e.g., 'cloudflare'.

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
