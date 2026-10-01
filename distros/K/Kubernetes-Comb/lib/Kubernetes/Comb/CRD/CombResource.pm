package Kubernetes::Comb::CRD::CombResource;
# ABSTRACT: Identity of one Kubernetes object a Comb manages
our $VERSION = '0.001';

use IO::K8s::Resource;


k8s apiVersion => Str, { required => 1 };


k8s kind => Str, { required => 1 };


k8s namespace => Str;


k8s name => Str, { required => 1 };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::CRD::CombResource - Identity of one Kubernetes object a Comb manages

=head1 VERSION

version 0.001

=head1 DESCRIPTION

An entry of C<status.managedResources> of a L<Kubernetes::Comb::CRD::Comb>:
enough to address an object the Comb deployed. Pruning compares the objects a
Comb renders now against this list; whatever is recorded here and no longer
rendered is an orphan.

=head2 apiVersion

Required. C<v1>, C<apps/v1>, ...

=head2 kind

Required. C<Deployment>, C<Service>, ...

=head2 namespace

Namespace of the object; absent for cluster-scoped objects.

=head2 name

Required. Name of the object.

=head1 SEE ALSO

=over

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
