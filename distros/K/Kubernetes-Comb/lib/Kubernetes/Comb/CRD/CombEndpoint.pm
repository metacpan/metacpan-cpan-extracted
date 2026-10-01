package Kubernetes::Comb::CRD::CombEndpoint;
# ABSTRACT: One resolved endpoint in the status of a Comb custom resource
our $VERSION = '0.001';

use IO::K8s::Resource;


k8s name => Str, { required => 1 };


k8s protocol => Str;


k8s port => Int, { required => 1 };


k8s cluster => Str;


k8s external => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::CRD::CombEndpoint - One resolved endpoint in the status of a Comb custom resource

=head1 VERSION

version 0.001

=head1 DESCRIPTION

An entry of C<status.endpoints> of a L<Kubernetes::Comb::CRD::Comb>. A Comb
publishes its endpoints already resolved -- redirected when an upstream is
active -- so a Comb borrowing from this one needs no knowledge of the layers
behind it. In Perl code the value object is L<Kubernetes::Comb::Endpoint>;
L<Kubernetes::Comb::Endpoint/to_crd> and L<Kubernetes::Comb::Endpoint/from_crd>
convert.

=head2 name

Required. Endpoint name as the Comb class declares it, e.g. C<client>.

=head2 protocol

C<tcp>, C<udp>, ...

=head2 port

Required. The port the endpoint is offered on.

=head2 cluster

Address inside the cluster, C<host:port>, e.g. C<nats.platform.svc:4222>.

=head2 external

Address from outside the cluster, C<host:port>.

=head1 SEE ALSO

=over

=item * L<Kubernetes::Comb::Endpoint>

=item * L<Kubernetes::Comb::CRD::CombStatus>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-kubernetes-comb/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
