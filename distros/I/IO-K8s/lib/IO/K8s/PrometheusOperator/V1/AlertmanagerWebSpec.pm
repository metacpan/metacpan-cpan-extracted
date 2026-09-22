package IO::K8s::PrometheusOperator::V1::AlertmanagerWebSpec;
# ABSTRACT: web defines the web command line flags when starting Alertmanager.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s getConcurrency => Int, { minimum => 0 };
k8s httpConfig     => '+IO::K8s::PrometheusOperator::V1::WebHTTPConfig';
k8s timeout        => Int, { minimum => 0 };
k8s tlsConfig      => '+IO::K8s::PrometheusOperator::V1::WebTLSConfig';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::AlertmanagerWebSpec - web defines the web command line flags when starting Alertmanager.

=head1 VERSION

version 1.108

=head2 getConcurrency

getConcurrency defines the maximum number of GET requests processed concurrently. This corresponds to the
Alertmanager's `--web.get-concurrency` flag.

=head2 httpConfig

httpConfig defines HTTP parameters for web server.

=head2 timeout

timeout for HTTP requests. This corresponds to the Alertmanager's
`--web.timeout` flag.

=head2 tlsConfig

tlsConfig defines the TLS parameters for HTTPS.

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
