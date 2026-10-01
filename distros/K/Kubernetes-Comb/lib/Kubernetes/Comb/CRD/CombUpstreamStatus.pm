package Kubernetes::Comb::CRD::CombUpstreamStatus;
# ABSTRACT: Upstream section in the status of a Comb custom resource
our $VERSION = '0.001';

use IO::K8s::Resource;


k8s class => Str;


k8s context => Str;


k8s reachable => Bool;


k8s phase => Str;


k8s via => [Str];


k8s observedAt => Time;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::CRD::CombUpstreamStatus - Upstream section in the status of a Comb custom resource

=head1 VERSION

version 0.001

=head1 DESCRIPTION

C<status.upstream> of a L<Kubernetes::Comb::CRD::Comb>, present only while an
upstream is active: which upstream, whether it is reachable, its phase and the
chain of layers the service is borrowed through.

=head2 class

Fully qualified class of the upstream, e.g.
C<Kubernetes::Comb::Upstream::K8s>.

=head2 context

Kube context the upstream lives in, where that applies. A context name only,
never credentials.

=head2 reachable

Whether the upstream answered with a usable address.

=head2 phase

The phase the upstream reports for itself.

=head2 via

ArrayRef of the layers the service is borrowed through, nearest first, e.g.
C<[ 'dev', 'prod' ]>.

=head2 observedAt

RFC 3339 timestamp of the observation.

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
