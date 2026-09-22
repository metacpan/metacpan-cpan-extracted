package IO::K8s::ExternalSecrets::V1::DVLSProvider;
# ABSTRACT: DVLS configures this store to sync secrets using Devolutions Server provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth      => '+IO::K8s::ExternalSecrets::V1::DVLSAuth', { required => 'schema' };
k8s insecure  => Bool;
k8s serverUrl => Str, { required => 'schema' };
k8s vault     => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::DVLSProvider - DVLS configures this store to sync secrets using Devolutions Server provider

=head1 VERSION

version 1.108

=head2 auth

Auth defines the authentication method to use.

=head2 insecure

Insecure allows connecting to DVLS over plain HTTP.
This is NOT RECOMMENDED for production use.
Set to true only if you understand the security implications.

=head2 serverUrl

ServerURL is the DVLS instance URL (e.g., https://dvls.example.com).

=head2 vault

Vault is the name or UUID of the vault to fetch secrets from.
When omitted, the vault must be specified in the secret key using the legacy format "<vault-id>/<entry-id>".

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
