package IO::K8s::ExternalSecrets::V1::NgrokProvider;
# ABSTRACT: Ngrok configures this store to sync secrets using the ngrok provider.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s apiUrl => Str, { default => 'https://api.ngrok.com' };
k8s auth   => '+IO::K8s::ExternalSecrets::V1::NgrokAuth', { required => 'schema' };
k8s vault  => '+IO::K8s::ExternalSecrets::V1::NgrokVault', { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::NgrokProvider - Ngrok configures this store to sync secrets using the ngrok provider.

=head1 VERSION

version 1.108

=head2 apiUrl

APIURL is the URL of the ngrok API.

=head2 auth

Auth configures how the ngrok provider authenticates with the ngrok API.

=head2 vault

Vault configures the ngrok vault to sync secrets with.

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
