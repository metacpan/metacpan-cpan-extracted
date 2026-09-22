package IO::K8s::ExternalSecrets::V1alpha1::SSHKeySpec;
# ABSTRACT: SSHKeySpec controls the behavior of the ssh key generator.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s comment => Str;
k8s keySize => Int, { minimum => 256, maximum => 8192 };
k8s keyType => Str, { enum => [qw(rsa ecdsa ed25519)], default => 'rsa' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::SSHKeySpec - SSHKeySpec controls the behavior of the ssh key generator.

=head1 VERSION

version 1.108

=head2 comment

Comment specifies an optional comment for the SSH key

=head2 keySize

KeySize specifies the key size for RSA keys (default: 2048) and ECDSA keys (default: 256).
For RSA keys: 2048, 3072, 4096
For ECDSA keys: 256, 384, 521
Ignored for ed25519 keys

=head2 keyType

KeyType specifies the SSH key type (rsa, ecdsa, ed25519)

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
