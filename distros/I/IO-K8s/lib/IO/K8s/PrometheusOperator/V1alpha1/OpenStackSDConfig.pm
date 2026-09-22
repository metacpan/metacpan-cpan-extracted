package IO::K8s::PrometheusOperator::V1alpha1::OpenStackSDConfig;
# ABSTRACT: OpenStackSDConfig allow retrieving scrape targets from OpenStack Nova instances.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s allTenants                  => Bool;
k8s applicationCredentialId     => Str;
k8s applicationCredentialName   => Str;
k8s applicationCredentialSecret => 'Core::V1::ConfigMapKeySelector';
k8s availability                => Str, { enum => [qw(Public public Admin admin Internal internal)] };
k8s domainID                    => Str;
k8s domainName                  => Str;
k8s identityEndpoint            => Str, { pattern => qr/^https?:\/\/.+$/ };
k8s password                    => 'Core::V1::ConfigMapKeySelector';
k8s port                        => Int, { minimum => 0, maximum => 65535 };
k8s projectID                   => Str;
k8s projectName                 => Str;
k8s refreshInterval             => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s region                      => Str, { required => 'schema' };
k8s role                        => Str, { required => 'schema', enum => [qw(Instance Hypervisor LoadBalancer)] };
k8s tlsConfig                   => '+IO::K8s::PrometheusOperator::V1alpha1::SafeTLSConfig';
k8s userid                      => Str;
k8s username                    => Str;



















1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::OpenStackSDConfig - OpenStackSDConfig allow retrieving scrape targets from OpenStack Nova instances.

=head1 VERSION

version 1.108

=head2 allTenants

allTenants defines whether the service discovery should list all instances for all projects.
It is only relevant for the 'instance' role and usually requires admin permissions.

=head2 applicationCredentialId

applicationCredentialId defines the OpenStack applicationCredentialId.

=head2 applicationCredentialName

applicationCredentialName defines the ApplicationCredentialID or ApplicationCredentialName fields are
required if using an application credential to authenticate. Some providers
allow you to create an application credential to authenticate rather than a
password.

=head2 applicationCredentialSecret

applicationCredentialSecret defines the required field if using an application
credential to authenticate.

=head2 availability

availability defines the availability of the endpoint to connect to.

=head2 domainID

domainID defines The OpenStack domainID.

=head2 domainName

domainName defines at most one of domainId and domainName that must be provided if using username
with Identity V3. Otherwise, either are optional.

=head2 identityEndpoint

identityEndpoint defines the HTTP endpoint that is required to work with
the Identity API of the appropriate version.

=head2 password

password defines the password for the Identity V2 and V3 APIs. Consult with your provider's
control panel to discover your account's preferred method of authentication.

=head2 port

port defines the port to scrape metrics from. If using the public IP address, this must
instead be specified in the relabeling rule.

=head2 projectID

projectID defines the OpenStack projectID.

=head2 projectName

projectName defines an optional field for the Identity V2 API.
Some providers allow you to specify a ProjectName instead of the ProjectId.
Some require both. Your provider's authentication policies will determine
how these fields influence authentication.

=head2 refreshInterval

refreshInterval defines the time after which the provided names are refreshed.
If not set, Prometheus uses its default value.

=head2 region

region defines the OpenStack Region.

=head2 role

role defines the OpenStack role of entities that should be discovered.

Note: The `LoadBalancer` role requires Prometheus >= v3.2.0.

=head2 tlsConfig

tlsConfig defines the TLS configuration applying to the target HTTP endpoint.

=head2 userid

userid defines the OpenStack userid.

=head2 username

username defines the username required if using Identity V2 API. Consult with your provider's
control panel to discover your account's username.
In Identity V3, either userid or a combination of username
and domainId or domainName are needed

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
