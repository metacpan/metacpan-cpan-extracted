package IO::K8s::Traefik::V1alpha1::Compress;
# ABSTRACT: Compress holds the compress middleware configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s defaultEncoding      => Str;
k8s encodings            => [Str];
k8s excludedContentTypes => [Str];
k8s includedContentTypes => [Str];
k8s minResponseBodyBytes => Int, { minimum => 0 };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::Compress - Compress holds the compress middleware configuration.

=head1 VERSION

version 1.108

=head2 defaultEncoding

DefaultEncoding specifies the default encoding if the `Accept-Encoding` header is not in the request or contains a wildcard (`*`).

=head2 encodings

Encodings defines the list of supported compression algorithms.

=head2 excludedContentTypes

ExcludedContentTypes defines the list of content types to compare the Content-Type header of the incoming requests and responses before compressing.
`application/grpc` is always excluded.

=head2 includedContentTypes

IncludedContentTypes defines the list of content types to compare the Content-Type header of the responses before compressing.

=head2 minResponseBodyBytes

MinResponseBodyBytes defines the minimum amount of bytes a response body must have to be compressed.
Default: 1024.

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
