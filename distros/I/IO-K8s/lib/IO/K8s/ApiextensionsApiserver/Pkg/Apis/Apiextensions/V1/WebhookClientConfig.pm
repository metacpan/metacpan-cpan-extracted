package IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::WebhookClientConfig;
# ABSTRACT: WebhookClientConfig contains the information to make a TLS connection with the webhook.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s caBundle => Str;


k8s service => 'Apiextensions::V1::ServiceReference';


k8s url => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::WebhookClientConfig - WebhookClientConfig contains the information to make a TLS connection with the webhook.

=head1 VERSION

version 1.100

=head2 caBundle

caBundle is a PEM encoded CA bundle which will be used to validate the webhook's server certificate. If unspecified, system trust roots on the apiserver are used.

=head2 service

service is a reference to the service for this webhook. Either service or url must be specified. If the webhook is running within the cluster, then you should use `service`.

=head2 url

url gives the location of the webhook, in standard URL form (`scheme://host:port/path`). Exactly one of `url` or `service` must be specified. The `host` should not refer to a service running in the cluster; use the `service` field instead. The host might be resolved via external DNS in some apiservers (e.g., `kube-apiserver` cannot resolve in-cluster DNS as that would be a layering violation). `host` may also be an IP address. Please note that using `localhost` or `127.0.0.1` as a `host` is risky unless you take great care to run this webhook on all hosts which run an apiserver which might need to make calls to this webhook. Such installs are likely to be non-portable, i.e., not easy to turn up in a new cluster. The scheme must be "https"; the URL must begin with "https://". A path is optional, and if present may be any string permissible in a URL. You may use the path to pass an arbitrary string to the webhook, for example, a cluster identifier. Attempting to use a user or basic auth e.g. "user:password@" is not allowed. Fragments ("#...") and query parameters ("?...") are not allowed, either.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
