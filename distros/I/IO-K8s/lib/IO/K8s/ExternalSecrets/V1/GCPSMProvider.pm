package IO::K8s::ExternalSecrets::V1::GCPSMProvider;
# ABSTRACT: GCPSM configures this store to sync secrets using Google Cloud Platform Secret Manager provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth                         => '+IO::K8s::ExternalSecrets::V1::GCPSMAuth';
k8s location                     => Str;
k8s projectID                    => Str;
k8s secretVersionSelectionPolicy => Str, { default => 'LatestOrFail' };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::GCPSMProvider - GCPSM configures this store to sync secrets using Google Cloud Platform Secret Manager provider

=head1 VERSION

version 1.108

=head2 auth

Auth defines the information necessary to authenticate against GCP

=head2 location

Location optionally defines a location for a secret

=head2 projectID

ProjectID project where secret is located

=head2 secretVersionSelectionPolicy

SecretVersionSelectionPolicy specifies how the provider selects a secret version
when "latest" is disabled or destroyed.
Possible values are:
- LatestOrFail: the provider always uses "latest", or fails if that version is disabled/destroyed.
- LatestOrFetch: the provider falls back to fetching the latest version if the version is DESTROYED or DISABLED

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
