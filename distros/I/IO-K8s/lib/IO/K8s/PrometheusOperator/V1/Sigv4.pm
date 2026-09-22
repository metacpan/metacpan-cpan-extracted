package IO::K8s::PrometheusOperator::V1::Sigv4;
# ABSTRACT: sigv4 defines AWS's Signature Verification 4 for the URL.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s accessKey          => 'Core::V1::ConfigMapKeySelector';
k8s externalId         => Str;
k8s profile            => Str;
k8s region             => Str;
k8s roleArn            => Str;
k8s secretKey          => 'Core::V1::ConfigMapKeySelector';
k8s useFIPSSTSEndpoint => Bool;








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::Sigv4 - sigv4 defines AWS's Signature Verification 4 for the URL.

=head1 VERSION

version 1.108

=head2 accessKey

accessKey defines the AWS API key. If not specified, the environment variable
`AWS_ACCESS_KEY_ID` is used.

=head2 externalId

externalId defines the external ID used when assuming an AWS role. Can only be used with roleArn.
It requires Prometheus >= v3.11.0 or Alertmanager >= v0.33.0. Currently not supported by Thanos.

=head2 profile

profile defines the named AWS profile used to authenticate.

=head2 region

region defines the AWS region. If blank, the region from the default credentials chain used.

=head2 roleArn

roleArn defines the named AWS profile used to authenticate.

=head2 secretKey

secretKey defines the AWS API secret. If not specified, the environment
variable `AWS_SECRET_ACCESS_KEY` is used.

=head2 useFIPSSTSEndpoint

useFIPSSTSEndpoint defines the FIPS mode for the AWS STS endpoint.
It requires Prometheus >= v2.54.0.

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
