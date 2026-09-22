package IO::K8s::ExternalSecrets::V1::AwsCredentialsConfig;
# ABSTRACT: awsSecurityCredentials is for configuring AWS region and credentials to use for obtaining the access token, when using the AWS metadata server is not an option.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s awsCredentialsSecretRef => 'Core::V1::SecretReference', { required => 'schema' };
k8s region                  => Str, { required => 'schema', pattern => qr/^[a-z0-9-]+$/ };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::AwsCredentialsConfig - awsSecurityCredentials is for configuring AWS region and credentials to use for obtaining the access token, when using the AWS metadata server is not an option.

=head1 VERSION

version 1.108

=head2 awsCredentialsSecretRef

awsCredentialsSecretRef is the reference to the secret which holds the AWS credentials.
Secret should be created with below names for keys
- aws_access_key_id: Access Key ID, which is the unique identifier for the AWS account or the IAM user.
- aws_secret_access_key: Secret Access Key, which is used to authenticate requests made to AWS services.
- aws_session_token: Session Token, is the short-lived token to authenticate requests made to AWS services.

=head2 region

region is for configuring the AWS region to be used.

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
