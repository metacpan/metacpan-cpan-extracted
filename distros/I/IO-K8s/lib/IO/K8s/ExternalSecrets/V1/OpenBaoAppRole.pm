package IO::K8s::ExternalSecrets::V1::OpenBaoAppRole;
# ABSTRACT: AppRole authenticates with OpenBao using the [App Role auth mechanism], with the role and secret stored in a Kubernetes Secret resource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s path      => Str, { required => 'schema', default => 'approle' };
k8s roleId    => Str;
k8s roleRef   => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s secretRef => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector', { required => 'schema' };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::OpenBaoAppRole - AppRole authenticates with OpenBao using the [App Role auth mechanism], with the role and secret stored in a Kubernetes Secret resource.

=head1 VERSION

version 1.108

=head2 path

Path where the App Role authentication backend is mounted
in OpenBao, e.g: "approle"

=head2 roleId

RoleID configured in the App Role authentication backend when setting
up the authentication backend in OpenBao.

=head2 roleRef

Reference to a key in a Secret that contains the App Role ID used
to authenticate with OpenBao.
The `key` field must be specified and denotes which entry within the Secret
resource is used as the app role id.

=head2 secretRef

Reference to a key in a Secret that contains the App Role secret used
to authenticate with OpenBao.
The `key` field must be specified and denotes which entry within the Secret
resource is used as the app role secret.

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
