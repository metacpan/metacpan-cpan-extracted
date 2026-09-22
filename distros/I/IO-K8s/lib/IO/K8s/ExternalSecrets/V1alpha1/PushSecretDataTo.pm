package IO::K8s::ExternalSecrets::V1alpha1::PushSecretDataTo;
# ABSTRACT: PushSecretDataTo defines how to bulk-push secrets to providers without explicit per-key mappings.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conversionStrategy => Str, { enum => [qw(None ReverseUnicode)], default => 'None' };
k8s match              => '+IO::K8s::ExternalSecrets::V1alpha1::PushSecretDataToMatch';
k8s metadata           => Str, { preserve_unknown => 1 };
k8s remoteKey          => Str;
k8s rewrite            => ['+IO::K8s::ExternalSecrets::V1alpha1::PushSecretRewrite'];
k8s storeRef           => '+IO::K8s::ExternalSecrets::V1alpha1::PushSecretStoreRef';







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::PushSecretDataTo - PushSecretDataTo defines how to bulk-push secrets to providers without explicit per-key mappings.

=head1 VERSION

version 1.108

=head2 conversionStrategy

Used to define a conversion Strategy for the secret keys

=head2 match

Match pattern for selecting keys from the source Secret.
If not specified, all keys are selected.

=head2 metadata

Metadata is metadata attached to the secret.
The structure of metadata is provider specific, please look it up in the provider documentation.

=head2 remoteKey

RemoteKey is the name of the single provider secret that will receive ALL
matched keys bundled as a JSON object (e.g. {"DB_HOST":"...","DB_USER":"..."}).
When set, per-key expansion is skipped and a single push is performed.
The provider's store prefix (if any) is still prepended to this value.
When not set, each matched key is pushed as its own individual provider secret.

=head2 rewrite

Rewrite operations to transform keys before pushing to the provider.
Operations are applied sequentially.

=head2 storeRef

StoreRef specifies which SecretStore to push to. Required.

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
