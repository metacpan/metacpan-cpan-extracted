package IO::K8s::ExternalSecrets::V1::ExternalSecretSpec;
# ABSTRACT: ExternalSecretSpec defines the desired state of ExternalSecret.
our $VERSION = '1.108';
use utf8;
use IO::K8s::Resource;

k8s data            => ['+IO::K8s::ExternalSecrets::V1::ExternalSecretData'];
k8s dataFrom        => ['+IO::K8s::ExternalSecrets::V1::ExternalSecretDataFromRemoteRef'];
k8s refreshInterval => Str, { default => '1h0m0s' };
k8s refreshPolicy   => Str, { enum => [qw(CreatedOnce Periodic OnChange)] };
k8s secretStoreRef  => '+IO::K8s::ExternalSecrets::V1::SecretStoreRef';
k8s syncWindows     => '+IO::K8s::ExternalSecrets::V1::ExternalSecretSyncWindows';
k8s target          => '+IO::K8s::ExternalSecrets::V1::ExternalSecretTarget', { default => {'creationPolicy' => 'Owner','deletionPolicy' => 'Retain'} };









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ExternalSecretSpec - ExternalSecretSpec defines the desired state of ExternalSecret.

=head1 VERSION

version 1.108

=head2 data

Data defines the connection between the Kubernetes Secret keys and the Provider data

=head2 dataFrom

DataFrom is used to fetch all properties from a specific Provider data
If multiple entries are specified, the Secret keys are merged in the specified order

=head2 refreshInterval

RefreshInterval is the amount of time before the values are read again from the SecretStore provider,
specified as Golang Duration strings.
Valid time units are "ns", "us" (or "µs"), "ms", "s", "m", "h"
Example values: "1h0m0s", "2h30m0s", "10m0s"
May be set to "0s" to fetch and create it once. Defaults to 1h0m0s.

=head2 refreshPolicy

RefreshPolicy determines how the ExternalSecret should be refreshed:
- CreatedOnce: Creates the Secret only if it does not exist and does not update it thereafter
- Periodic: Synchronizes the Secret from the external source at regular intervals specified by refreshInterval.
  No periodic updates occur if refreshInterval is 0.
- OnChange: Only synchronizes the Secret when the ExternalSecret's metadata or specification changes

=head2 secretStoreRef

SecretStoreRef defines which SecretStore to fetch the ExternalSecret data.

=head2 syncWindows

SyncWindows optionally restricts when periodic refreshes may occur.
Evaluated in UTC, only for Periodic refresh policy (or when refreshPolicy is unset).

=head2 target

ExternalSecretTarget defines the Kubernetes Secret to be created,
there can be only one target per ExternalSecret.

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
