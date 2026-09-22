package IO::K8s::PrometheusOperator::V1::AlertmanagerConfiguration;
# ABSTRACT: alertmanagerConfiguration defines the configuration of Alertmanager.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s global    => '+IO::K8s::PrometheusOperator::V1::AlertmanagerGlobalConfig';
k8s name      => Str;
k8s templates => ['+IO::K8s::PrometheusOperator::V1::SecretOrConfigMap'];




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::AlertmanagerConfiguration - alertmanagerConfiguration defines the configuration of Alertmanager.

=head1 VERSION

version 1.108

=head2 global

global defines the global parameters of the Alertmanager configuration.

=head2 name

name defines the name of the AlertmanagerConfig custom resource which is used to generate the Alertmanager configuration.
It must be defined in the same namespace as the Alertmanager object.
The operator will not enforce a `namespace` label for routes and inhibition rules.

=head2 templates

templates defines the custom notification templates.

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
