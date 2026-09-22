package IO::K8s::Traefik::V1alpha1::Cookie;
# ABSTRACT: Cookie defines the sticky cookie configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s domain   => Str;
k8s httpOnly => Bool;
k8s maxAge   => Int;
k8s name     => Str;
k8s path     => Str;
k8s sameSite => Str, { enum => [qw(none lax strict None Lax Strict)] };
k8s secure   => Bool;








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::Cookie - Cookie defines the sticky cookie configuration.

=head1 VERSION

version 1.108

=head2 domain

Domain defines the host to which the cookie will be sent.
More info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#domaindomain-value

=head2 httpOnly

HTTPOnly defines whether the cookie can be accessed by client-side APIs, such as JavaScript.

=head2 maxAge

MaxAge defines the number of seconds until the cookie expires.
When set to a negative number, the cookie expires immediately.
When set to zero, the cookie never expires.

=head2 name

Name defines the Cookie name.

=head2 path

Path defines the path that must exist in the requested URL for the browser to send the Cookie header.
When not provided the cookie will be sent on every request to the domain.
More info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#pathpath-value

=head2 sameSite

SameSite defines the same site policy.
More info: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite

=head2 secure

Secure defines whether the cookie can only be transmitted over an encrypted connection (i.e. HTTPS).

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
