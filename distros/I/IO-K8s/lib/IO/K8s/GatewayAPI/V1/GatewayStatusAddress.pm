package IO::K8s::GatewayAPI::V1::GatewayStatusAddress;
# ABSTRACT: GatewayStatusAddress describes a network address that is bound to a Gateway.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s type  => Str, { pattern => '^Hostname|IPAddress|NamedAddress|[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*\\/[A-Za-z0-9\\/\\-._~%!$&\'()*+,;=:]+$', default => 'IPAddress' };
k8s value => Str, { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::GatewayStatusAddress - GatewayStatusAddress describes a network address that is bound to a Gateway.

=head1 VERSION

version 1.108

=head2 type

Type of the address.

=head2 value

Value of the address. The validity of the values will depend
on the type and support by the controller.

Examples: `1.2.3.4`, `128::1`, `my-ip-address`.

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
