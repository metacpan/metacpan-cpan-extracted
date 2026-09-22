package IO::K8s::GatewayAPI::V1::HTTPURLRewriteFilter;
# ABSTRACT: URLRewrite defines a schema for a filter that modifies a request during forwarding.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s hostname => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s path     => '+IO::K8s::GatewayAPI::V1::HTTPPathModifier';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::HTTPURLRewriteFilter - URLRewrite defines a schema for a filter that modifies a request during forwarding.

=head1 VERSION

version 1.108

=head2 hostname

Hostname is the value to be used to replace the Host header value during
forwarding.

Support: Extended

=head2 path

Path defines a path rewrite.

Support: Extended

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
