package IO::K8s::GatewayAPI::V1beta1::GatewaySpecAddress;
# ABSTRACT: GatewaySpecAddress describes an address that can be bound to a Gateway.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s type  => Str, { pattern => '^Hostname|IPAddress|NamedAddress|[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*\\/[A-Za-z0-9\\/\\-._~%!$&\'()*+,;=:]+$', default => 'IPAddress' };
k8s value => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::GatewaySpecAddress - GatewaySpecAddress describes an address that can be bound to a Gateway.

=head1 VERSION

version 1.108

=head2 type

Type of the address.

=head2 value

When a value is unspecified, an implementation SHOULD automatically
assign an address matching the requested type if possible.

If an implementation does not support an empty value, they MUST set the
"Programmed" condition in status to False with a reason of "AddressNotAssigned".

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
