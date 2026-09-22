package IO::K8s::ExternalSecrets::V1alpha1::STSSessionTokenSpec;
# ABSTRACT: STSSessionTokenSpec defines the desired state to generate an AWS STS session token.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth              => '+IO::K8s::ExternalSecrets::V1::AWSAuth';
k8s region            => Str, { required => 'schema' };
k8s requestParameters => '+IO::K8s::ExternalSecrets::V1alpha1::STSSessionTokenRequestParameters';
k8s role              => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::STSSessionTokenSpec - STSSessionTokenSpec defines the desired state to generate an AWS STS session token.

=head1 VERSION

version 1.108

=head2 auth

Auth defines how to authenticate with AWS

=head2 region

Region specifies the region to operate in.

=head2 requestParameters

RequestParameters contains parameters that can be passed to the STS service.

=head2 role

You can assume a role before making calls to the
desired AWS service.

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
