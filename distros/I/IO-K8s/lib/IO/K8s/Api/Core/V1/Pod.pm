package IO::K8s::Api::Core::V1::Pod;
# ABSTRACT: Pod is a collection of containers that can run on a host. This resource is created by clients and scheduled onto hosts.
our $VERSION = '1.009';
use IO::K8s::APIObject;
with 'IO::K8s::Role::Namespaced';


k8s spec => 'Core::V1::PodSpec';


k8s status => 'Core::V1::PodStatus';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::Pod - Pod is a collection of containers that can run on a host. This resource is created by clients and scheduled onto hosts.

=head1 VERSION

version 1.009

=head1 DESCRIPTION

Pod is a collection of containers that can run on a host. This resource is created by clients and scheduled onto hosts.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

Specification of the desired behavior of the pod. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

=head2 status

Most recently observed status of the pod. This data may not be up to date. Populated by the system. Read-only. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#pod-v1-core>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
