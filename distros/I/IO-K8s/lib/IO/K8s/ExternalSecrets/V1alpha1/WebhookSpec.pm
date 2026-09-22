package IO::K8s::ExternalSecrets::V1alpha1::WebhookSpec;
# ABSTRACT: WebhookSpec controls the behavior of the external generator. Any body parameters should be passed to the server through the parameters field.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth       => '+IO::K8s::ExternalSecrets::V1::AuthorizationProtocol';
k8s body       => Str;
k8s caBundle   => Str;
k8s caProvider => '+IO::K8s::ExternalSecrets::V1::WebhookCAProvider';
k8s headers    => { Str => 1 };
k8s method     => Str;
k8s result     => '+IO::K8s::ExternalSecrets::V1::WebhookResult', { required => 'schema' };
k8s secrets    => ['+IO::K8s::ExternalSecrets::V1alpha1::WebhookSecret'];
k8s timeout    => Str;
k8s url        => Str, { required => 'schema' };











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::WebhookSpec - WebhookSpec controls the behavior of the external generator. Any body parameters should be passed to the server through the parameters field.

=head1 VERSION

version 1.108

=head2 auth

Auth specifies a authorization protocol. Only one protocol may be set.

=head2 body

Body

=head2 caBundle

PEM encoded CA bundle used to validate webhook server certificate. Only used
if the Server URL is using HTTPS protocol. This parameter is ignored for
plain HTTP protocol connection. If not set the system root certificates
are used to validate the TLS connection.

=head2 caProvider

The provider for the CA bundle to use to validate webhook server certificate.

=head2 headers

Headers

=head2 method

Webhook Method

=head2 result

Result formatting

=head2 secrets

Secrets to fill in templates
These secrets will be passed to the templating function as key value pairs under the given name

=head2 timeout

Timeout

=head2 url

Webhook url to call

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
