package IO::K8s::ExternalSecrets::V1alpha1::PushSecretSpec;
# ABSTRACT: PushSecretSpec configures the behavior of the PushSecret.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s data            => ['+IO::K8s::ExternalSecrets::V1alpha1::PushSecretData'];
k8s dataTo          => ['+IO::K8s::ExternalSecrets::V1alpha1::PushSecretDataTo'];
k8s deletionPolicy  => Str, { enum => [qw(Delete None)], default => 'None' };
k8s refreshInterval => Str, { default => '1h0m0s' };
k8s secretStoreRefs => ['+IO::K8s::ExternalSecrets::V1alpha1::PushSecretStoreRef'], { required => 'schema' };
k8s selector        => '+IO::K8s::ExternalSecrets::V1alpha1::PushSecretSelector', { required => 'schema' };
k8s template        => '+IO::K8s::ExternalSecrets::V1alpha1::ExternalSecretTemplate';
k8s updatePolicy    => Str, { enum => [qw(Replace IfNotExists)], default => 'Replace' };









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::PushSecretSpec - PushSecretSpec configures the behavior of the PushSecret.

=head1 VERSION

version 1.108

=head2 data

Secret Data that should be pushed to providers

=head2 dataTo

DataTo defines bulk push rules that expand source Secret keys into provider entries.

=head2 deletionPolicy

Deletion Policy to handle Secrets in the provider.

=head2 refreshInterval

The Interval to which External Secrets will try to push a secret definition

=head2 secretStoreRefs

No description in the upstream schema.

=head2 selector

The Secret Selector (k8s source) for the Push Secret

=head2 template

Template defines a blueprint for the created Secret resource.

=head2 updatePolicy

UpdatePolicy to handle Secrets in the provider.

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
