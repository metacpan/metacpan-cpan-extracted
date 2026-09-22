package IO::K8s::ExternalSecrets::V1::AWSAuthSecretRef;
# ABSTRACT: AWSAuthSecretRef holds secret references for AWS credentials both AccessKeyID and SecretAccessKey must be defined in order to properly authenticate.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s accessKeyIDSecretRef     => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s secretAccessKeySecretRef => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s sessionTokenSecretRef    => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::AWSAuthSecretRef - AWSAuthSecretRef holds secret references for AWS credentials both AccessKeyID and SecretAccessKey must be defined in order to properly authenticate.

=head1 VERSION

version 1.108

=head2 accessKeyIDSecretRef

The AccessKeyID is used for authentication

=head2 secretAccessKeySecretRef

The SecretAccessKey is used for authentication

=head2 sessionTokenSecretRef

The SessionToken used for authentication
This must be defined if AccessKeyID and SecretAccessKey are temporary credentials
see: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_use-resources.html

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
