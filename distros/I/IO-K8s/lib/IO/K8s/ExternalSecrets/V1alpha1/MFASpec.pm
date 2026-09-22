package IO::K8s::ExternalSecrets::V1alpha1::MFASpec;
# ABSTRACT: MFASpec controls the behavior of the mfa generator.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s algorithm  => Str;
k8s length     => Int;
k8s secret     => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector', { required => 'schema' };
k8s timePeriod => Int;
k8s when       => Time;






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::MFASpec - MFASpec controls the behavior of the mfa generator.

=head1 VERSION

version 1.108

=head2 algorithm

Algorithm to use for encoding. Defaults to SHA1 as per the RFC.

=head2 length

Length defines the token length. Defaults to 6 characters.

=head2 secret

Secret is a secret selector to a secret containing the seed secret to generate the TOTP value from.

=head2 timePeriod

TimePeriod defines how long the token can be active. Defaults to 30 seconds.

=head2 when

When defines a time parameter that can be used to pin the origin time of the generated token.

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
