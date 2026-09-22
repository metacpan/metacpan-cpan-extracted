package IO::K8s::PrometheusOperator::V1::WebHTTPHeaders;
# ABSTRACT: headers defines a list of headers that can be added to HTTP responses.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s contentSecurityPolicy   => Str;
k8s strictTransportSecurity => Str;
k8s xContentTypeOptions     => Str, { enum => ['','NoSniff'] };
k8s xFrameOptions           => Str, { enum => ['','Deny','SameOrigin'] };
k8s xXSSProtection          => Str;






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::WebHTTPHeaders - headers defines a list of headers that can be added to HTTP responses.

=head1 VERSION

version 1.108

=head2 contentSecurityPolicy

contentSecurityPolicy defines the Content-Security-Policy header to HTTP responses.
Unset if blank.

=head2 strictTransportSecurity

strictTransportSecurity defines the Strict-Transport-Security header to HTTP responses.
Unset if blank.
Please make sure that you use this with care as this header might force
browsers to load Prometheus and the other applications hosted on the same
domain and subdomains over HTTPS.
https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security

=head2 xContentTypeOptions

xContentTypeOptions defines the X-Content-Type-Options header to HTTP responses.
Unset if blank. Accepted value is nosniff.
https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Content-Type-Options

=head2 xFrameOptions

xFrameOptions defines the X-Frame-Options header to HTTP responses.
Unset if blank. Accepted values are deny and sameorigin.
https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options

=head2 xXSSProtection

xXSSProtection defines the X-XSS-Protection header to all responses.
Unset if blank.
https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-XSS-Protection

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
