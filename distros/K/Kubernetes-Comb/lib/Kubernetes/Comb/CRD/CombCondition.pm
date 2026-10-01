package Kubernetes::Comb::CRD::CombCondition;
# ABSTRACT: One condition in the status of a Comb custom resource
our $VERSION = '0.001';

use IO::K8s::Resource;


k8s type => Str, { required => 1 };


k8s status => Str, { required => 1, enum => [qw( True False Unknown )] };


k8s reason => Str;


k8s message => Str;


k8s lastTransitionTime => Time;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::Comb::CRD::CombCondition - One condition in the status of a Comb custom resource

=head1 VERSION

version 0.001

=head1 DESCRIPTION

An entry of C<status.conditions> of a L<Kubernetes::Comb::CRD::Comb>, shaped
like the conditions of the built-in Kinds, so the condition helpers of
L<IO::K8s::Role::APIObject> (C<get_condition>, C<is_condition_true>, ...) work
on a Comb custom resource as well.

=head2 type

Required. The condition type, e.g. C<Ready>.

=head2 status

Required. C<True>, C<False> or C<Unknown>.

=head2 reason

Machine-readable CamelCase reason for the last transition.

=head2 message

Human-readable detail.

=head2 lastTransitionTime

RFC 3339 timestamp of the last change of L</status>.

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
