package IO::K8s::PrometheusOperator::V1alpha1::NamespaceDiscovery;
# ABSTRACT: namespaces defines the namespace discovery.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s names        => [Str];
k8s ownNamespace => Bool;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::NamespaceDiscovery - namespaces defines the namespace discovery.

=head1 VERSION

version 1.108

=head2 names

names defines a list of namespaces where to watch for resources.
If empty and `ownNamespace` isn't true, Prometheus watches for resources in all namespaces.

=head2 ownNamespace

ownNamespace includes the namespace in which the Prometheus pod runs to the list of watched namespaces.

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
