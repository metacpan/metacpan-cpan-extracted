package IO::K8s::Traefik::V1alpha1::Route;
# ABSTRACT: Route holds the HTTP route configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s kind          => Str, { enum => [qw(Rule)] };
k8s match         => Str, { required => 'schema' };
k8s middlewares   => ['Core::V1::SecretReference'];
k8s observability => '+IO::K8s::Traefik::V1alpha1::RouterObservabilityConfig';
k8s priority      => Int, { maximum => '9223372036854775000' };
k8s services      => ['+IO::K8s::Traefik::V1alpha1::Service'];
k8s syntax        => Str;








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::Route - Route holds the HTTP route configuration.

=head1 VERSION

version 1.108

=head2 kind

Kind defines the kind of the route.
Rule is the only supported kind.
If not defined, defaults to Rule.

=head2 match

Match defines the router's rule.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/routing/rules-and-priority/

=head2 middlewares

Middlewares defines the list of references to Middleware resources.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/kubernetes/crd/http/middleware/

=head2 observability

Observability defines the observability configuration for a router.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/routing/observability/

=head2 priority

Priority defines the router's priority.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/routing/rules-and-priority/#priority

=head2 services

Services defines the list of Service.
It can contain any combination of TraefikService and/or reference to a Kubernetes Service.

=head2 syntax

Syntax defines the router's rule syntax.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/routing/rules-and-priority/#rulesyntax

Deprecated: Please do not use this field and rewrite the router rules to use the v3 syntax.

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
