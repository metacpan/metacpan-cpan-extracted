package IO::K8s::Cilium::V2::CiliumLocalRedirectPolicySpec;
# ABSTRACT: Spec is the desired behavior of the local redirect policy.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s description             => Str;
k8s redirectBackend         => '+IO::K8s::Cilium::V2::RedirectBackend', { required => 'schema' };
k8s redirectFrontend        => '+IO::K8s::Cilium::V2::RedirectFrontend', { required => 'schema' };
k8s skipRedirectFromBackend => Bool, { default => 0 };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumLocalRedirectPolicySpec - Spec is the desired behavior of the local redirect policy.

=head1 VERSION

version 1.108

=head2 description

Description can be used by the creator of the policy to describe the
purpose of this policy.

=head2 redirectBackend

RedirectBackend specifies backend configuration to redirect traffic to.
It can not be empty.

=head2 redirectFrontend

RedirectFrontend specifies frontend configuration to redirect traffic from.
It can not be empty.

=head2 skipRedirectFromBackend

SkipRedirectFromBackend indicates whether traffic matching RedirectFrontend
from RedirectBackend should skip redirection, and hence the traffic will
be forwarded as-is.

The default is false which means traffic matching RedirectFrontend will
get redirected from all pods, including the RedirectBackend(s).

Example: If RedirectFrontend is configured to "169.254.169.254:80" as the traffic
that needs to be redirected to backends selected by RedirectBackend, if
SkipRedirectFromBackend is set to true, traffic going to "169.254.169.254:80"
from such backends will not be redirected back to the backends. Instead,
the matched traffic from the backends will be forwarded to the original
destination "169.254.169.254:80".

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
