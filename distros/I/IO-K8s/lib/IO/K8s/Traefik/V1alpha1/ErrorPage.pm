package IO::K8s::Traefik::V1alpha1::ErrorPage;
# ABSTRACT: ErrorPage holds the custom error middleware configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s errorRequestHeaders => [Str];
k8s query               => Str;
k8s service             => '+IO::K8s::Traefik::V1alpha1::Service';
k8s status              => [Str], { pattern => qr/^([1-5][0-9]{2}[,-]?)+$/ };
k8s statusRewrites      => { Str => 1 };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::ErrorPage - ErrorPage holds the custom error middleware configuration.

=head1 VERSION

version 1.108

=head2 errorRequestHeaders

ErrorRequestHeaders defines the list of request headers forwarded to the error page service.
When nil (not set), all original request headers are forwarded.
Set to an empty list to forward no headers, or list specific headers to forward only those.

=head2 query

Query defines the URL for the error page (hosted by service).
The {status} variable can be used in order to insert the status code in the URL.
The {originalStatus} variable can be used in order to insert the upstream status code in the URL.
The {url} variable can be used in order to insert the escaped request URL.

=head2 service

Service defines the reference to a Kubernetes Service that will serve the error page.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/middlewares/errorpages/#service

=head2 status

Status defines which status or range of statuses should result in an error page.
It can be either a status code as a number (500),
as multiple comma-separated numbers (500,502),
as ranges by separating two codes with a dash (500-599),
or a combination of the two (404,418,500-599).

=head2 statusRewrites

StatusRewrites defines a mapping of status codes that should be returned instead of the original error status codes.
For example: "418": 404 or "410-418": 404

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
