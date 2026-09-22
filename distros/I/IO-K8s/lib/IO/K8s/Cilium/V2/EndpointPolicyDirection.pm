package IO::K8s::Cilium::V2::EndpointPolicyDirection;
# ABSTRACT: EndpointPolicyDirection is the list of allowed identities per direction.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s adding    => ['+IO::K8s::Cilium::V2::IdentityTuple'];
k8s allowed   => ['+IO::K8s::Cilium::V2::IdentityTuple'];
k8s denied    => ['+IO::K8s::Cilium::V2::IdentityTuple'];
k8s enforcing => Bool, { required => 'schema' };
k8s removing  => ['+IO::K8s::Cilium::V2::IdentityTuple'];
k8s state     => Str;







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::EndpointPolicyDirection - EndpointPolicyDirection is the list of allowed identities per direction.

=head1 VERSION

version 1.108

=head2 adding

Deprecated

=head2 allowed

AllowedIdentityList is a list of IdentityTuples that species peers that are
allowed.

=head2 denied

DenyIdentityList is a list of IdentityTuples that species peers that are
denied.

=head2 enforcing

No description in the upstream schema.

=head2 removing

Deprecated

=head2 state

EndpointPolicyState defines the state of the Policy mode: "enforcing", "non-enforcing", "disabled"

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
