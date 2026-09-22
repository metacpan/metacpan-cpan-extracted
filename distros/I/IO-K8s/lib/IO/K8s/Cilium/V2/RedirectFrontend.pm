package IO::K8s::Cilium::V2::RedirectFrontend;
# ABSTRACT: RedirectFrontend specifies frontend configuration to redirect traffic from.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s addressMatcher => '+IO::K8s::Cilium::V2::Frontend';
k8s serviceMatcher => '+IO::K8s::Cilium::V2::ServiceInfo';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::RedirectFrontend - RedirectFrontend specifies frontend configuration to redirect traffic from.

=head1 VERSION

version 1.108

=head2 addressMatcher

AddressMatcher is a tuple {IP, port, protocol} that matches traffic to be
redirected.

=head2 serviceMatcher

ServiceMatcher specifies Kubernetes service and port that matches
traffic to be redirected.

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
