package IO::K8s::K3s::V1::SecretSpec;
# ABSTRACT: SecretSpec describes a key in a secret to load chart values from.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s ignoreUpdates => Bool;
k8s keys          => [Str];
k8s name          => Str;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::K3s::V1::SecretSpec - SecretSpec describes a key in a secret to load chart values from.

=head1 VERSION

version 1.108

=head2 ignoreUpdates

Ignore changes to the secret, and mark the secret as optional.
By default, the secret must exist, and changes to the secret will trigger an upgrade of the chart to apply the updated values.
If `ignoreUpdates` is true, the secret is optional, and changes to the secret will not trigger an upgrade of the chart.

=head2 keys

Keys to read values content from. If no keys are specified, the secret is not used.

=head2 name

Name of the secret. Must be in the same namespace as the HelmChart resource.

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
