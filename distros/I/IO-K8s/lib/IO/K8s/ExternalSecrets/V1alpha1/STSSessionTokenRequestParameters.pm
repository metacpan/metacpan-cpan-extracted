package IO::K8s::ExternalSecrets::V1alpha1::STSSessionTokenRequestParameters;
# ABSTRACT: RequestParameters contains parameters that can be passed to the STS service.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s serialNumber    => Str;
k8s sessionDuration => Int;
k8s tokenCode       => Str;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::STSSessionTokenRequestParameters - RequestParameters contains parameters that can be passed to the STS service.

=head1 VERSION

version 1.108

=head2 serialNumber

SerialNumber is the identification number of the MFA device that is associated with the IAM user who is making
the GetSessionToken call.
Possible values: hardware device (such as GAHT12345678) or an Amazon Resource Name (ARN) for a virtual device
(such as arn:aws:iam::123456789012:mfa/user)

=head2 sessionDuration

No description in the upstream schema.

=head2 tokenCode

TokenCode is the value provided by the MFA device, if MFA is required.

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
