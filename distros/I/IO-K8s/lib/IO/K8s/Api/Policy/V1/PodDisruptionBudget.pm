package IO::K8s::Api::Policy::V1::PodDisruptionBudget;
# ABSTRACT: PodDisruptionBudget is an object to define the max disruption that can be caused to a collection of pods
our $VERSION = '1.008';
use IO::K8s::APIObject;
with 'IO::K8s::Role::Namespaced';


k8s spec => 'Policy::V1::PodDisruptionBudgetSpec';


k8s status => 'Policy::V1::PodDisruptionBudgetStatus';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Policy::V1::PodDisruptionBudget - PodDisruptionBudget is an object to define the max disruption that can be caused to a collection of pods

=head1 VERSION

version 1.008

=head1 DESCRIPTION

PodDisruptionBudget is an object to define the max disruption that can be caused to a collection of pods

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

Specification of the desired behavior of the PodDisruptionBudget.

=head2 status

Most recently observed status of the PodDisruptionBudget.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#poddisruptionbudget-v1-policy.k8s.io>

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
