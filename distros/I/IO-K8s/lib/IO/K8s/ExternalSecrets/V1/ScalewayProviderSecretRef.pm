package IO::K8s::ExternalSecrets::V1::ScalewayProviderSecretRef;
# ABSTRACT: SecretKey is the non-secret part of the api key.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s secretRef => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s value     => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ScalewayProviderSecretRef - SecretKey is the non-secret part of the api key.

=head1 VERSION

version 1.108

=head2 secretRef

SecretRef references a key in a secret that will be used as value.

=head2 value

Value can be specified directly to set a value without using a secret.

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
