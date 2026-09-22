package IO::K8s::ExternalSecrets::V1::SecretsManager;
# ABSTRACT: SecretsManager defines how the provider behaves when interacting with AWS SecretsManager
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s forceDeleteWithoutRecovery => Bool;
k8s recoveryWindowInDays       => Int;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::SecretsManager - SecretsManager defines how the provider behaves when interacting with AWS SecretsManager

=head1 VERSION

version 1.108

=head2 forceDeleteWithoutRecovery

Specifies whether to delete the secret without any recovery window. You
can't use both this parameter and RecoveryWindowInDays in the same call.
If you don't use either, then by default Secrets Manager uses a 30 day
recovery window.
see: https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_DeleteSecret.html#SecretsManager-DeleteSecret-request-ForceDeleteWithoutRecovery

=head2 recoveryWindowInDays

The number of days from 7 to 30 that Secrets Manager waits before
permanently deleting the secret. You can't use both this parameter and
ForceDeleteWithoutRecovery in the same call. If you don't use either,
then by default Secrets Manager uses a 30-day recovery window.
see: https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_DeleteSecret.html#SecretsManager-DeleteSecret-request-RecoveryWindowInDays

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
