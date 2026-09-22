package IO::K8s::ExternalSecrets::V1alpha1::PushSecretData;
# ABSTRACT: PushSecretData defines data to be pushed to the provider and associated metadata.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conversionStrategy => Str, { enum => [qw(None ReverseUnicode)], default => 'None' };
k8s match              => '+IO::K8s::ExternalSecrets::V1alpha1::PushSecretMatch', { required => 'schema' };
k8s metadata           => Str, { preserve_unknown => 1 };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::PushSecretData - PushSecretData defines data to be pushed to the provider and associated metadata.

=head1 VERSION

version 1.108

=head2 conversionStrategy

Used to define a conversion Strategy for the secret keys

=head2 match

Match a given Secret Key to be pushed to the provider.

=head2 metadata

Metadata is metadata attached to the secret.
The structure of metadata is provider specific, please look it up in the provider documentation.

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
