package IO::K8s::Traefik::V1alpha1::ContentType;
# ABSTRACT: ContentType holds the content-type middleware configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s autoDetect => Bool;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::ContentType - ContentType holds the content-type middleware configuration.

=head1 VERSION

version 1.108

=head2 autoDetect

AutoDetect specifies whether to let the `Content-Type` header, if it has not been set by the backend,
be automatically set to a value derived from the contents of the response.

Deprecated: AutoDetect option is deprecated, Content-Type middleware is only meant to be used to enable the content-type detection, please remove any usage of this option.

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
