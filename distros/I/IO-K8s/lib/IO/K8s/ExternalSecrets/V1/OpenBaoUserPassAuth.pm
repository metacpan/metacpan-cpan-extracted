package IO::K8s::ExternalSecrets::V1::OpenBaoUserPassAuth;
# ABSTRACT: UserPass authenticates with OpenBao by passing a username/password pair
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s path      => Str, { required => 'schema', default => 'userpass' };
k8s secretRef => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s username  => Str, { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::OpenBaoUserPassAuth - UserPass authenticates with OpenBao by passing a username/password pair

=head1 VERSION

version 1.108

=head2 path

Path where the UserPassword authentication backend is mounted
in OpenBao, e.g: "userpass"

=head2 secretRef

SecretRef to a key in a Secret resource containing password for the user
used to authenticate with OpenBao using the [UserPass authentication
method]

[UserPass authentication method]: https://openbao.org/docs/auth/userpass/

=head2 username

Username is a username used to authenticate using the [UserPass
authentication method]

[UserPass authentication method]: https://openbao.org/docs/auth/userpass/

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
