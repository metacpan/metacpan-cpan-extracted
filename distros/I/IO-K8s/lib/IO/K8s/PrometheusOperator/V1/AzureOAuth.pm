package IO::K8s::PrometheusOperator::V1::AzureOAuth;
# ABSTRACT: oauth defines the oauth config that is being used to authenticate.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s clientId     => Str, { required => 'schema' };
k8s clientSecret => 'Core::V1::ConfigMapKeySelector', { required => 'schema' };
k8s tenantId     => Str, { required => 'schema', pattern => qr/^[0-9a-zA-Z-.]+$/ };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::AzureOAuth - oauth defines the oauth config that is being used to authenticate.

=head1 VERSION

version 1.108

=head2 clientId

clientId defines the clientId of the Azure Active Directory application that is being used to authenticate.

=head2 clientSecret

clientSecret specifies a key of a Secret containing the client secret of the Azure Active Directory application that is being used to authenticate.

=head2 tenantId

tenantId is the tenant ID of the Azure Active Directory application that is being used to authenticate.

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
