package IO::K8s::GatewayAPI::V1::GRPCRouteMatch;
# ABSTRACT: GRPCRouteMatch defines the predicate used to match requests to a given action.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s headers => ['+IO::K8s::GatewayAPI::V1::GRPCHeaderMatch'];
k8s method  => '+IO::K8s::GatewayAPI::V1::GRPCMethodMatch';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::GRPCRouteMatch - GRPCRouteMatch defines the predicate used to match requests to a given action.

=head1 VERSION

version 1.108

=head2 headers

Headers specifies gRPC request header matchers. Multiple match values are
ANDed together, meaning, a request MUST match all the specified headers
to select the route.

=head2 method

Method specifies a gRPC request service/method matcher. If this field is
not specified, all services and methods will match.

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
