package IO::K8s::GatewayAPI::V1::GRPCMethodMatch;
# ABSTRACT: Method specifies a gRPC request service/method matcher.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s method  => Str;
k8s service => Str;
k8s type    => Str, { enum => [qw(Exact RegularExpression)], default => 'Exact' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::GRPCMethodMatch - Method specifies a gRPC request service/method matcher.

=head1 VERSION

version 1.108

=head2 method

Value of the method to match against. If left empty or omitted, will
match all services.

At least one of Service and Method MUST be a non-empty string.

=head2 service

Value of the service to match against. If left empty or omitted, will
match any service.

At least one of Service and Method MUST be a non-empty string.

=head2 type

Type specifies how to match against the service and/or method.
Support: Core (Exact with service and method specified)

Support: Implementation-specific (Exact with method specified but no service specified)

Support: Implementation-specific (RegularExpression)

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
