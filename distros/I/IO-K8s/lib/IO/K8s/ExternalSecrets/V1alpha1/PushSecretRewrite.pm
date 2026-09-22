package IO::K8s::ExternalSecrets::V1alpha1::PushSecretRewrite;
# ABSTRACT: PushSecretRewrite defines how to transform secret keys before pushing.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s regexp    => '+IO::K8s::ExternalSecrets::V1alpha1::ExternalSecretRewriteRegexp';
k8s transform => '+IO::K8s::ExternalSecrets::V1alpha1::ExternalSecretRewriteTransform';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::PushSecretRewrite - PushSecretRewrite defines how to transform secret keys before pushing.

=head1 VERSION

version 1.108

=head2 regexp

Used to rewrite with regular expressions.

=head2 transform

Used to apply string transformation on the secrets.

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
