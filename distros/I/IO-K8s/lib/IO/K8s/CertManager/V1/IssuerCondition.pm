package IO::K8s::CertManager::V1::IssuerCondition;
# ABSTRACT: IssuerCondition contains condition information for an Issuer.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s lastTransitionTime => Time;
k8s message            => Str;
k8s observedGeneration => Int;
k8s reason             => Str;
k8s status             => Str, { required => 'schema', enum => [qw(True False Unknown)] };
k8s type               => Str, { required => 'schema' };







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::IssuerCondition - IssuerCondition contains condition information for an Issuer.

=head1 VERSION

version 1.108

=head2 lastTransitionTime

LastTransitionTime is the timestamp corresponding to the last status
change of this condition.

=head2 message

Message is a human readable description of the details of the last
transition, complementing reason.

=head2 observedGeneration

If set, this represents the .metadata.generation that the condition was
set based upon.
For instance, if .metadata.generation is currently 12, but the
.status.condition[x].observedGeneration is 9, the condition is out of date
with respect to the current state of the Issuer.

=head2 reason

Reason is a brief machine readable explanation for the condition's last
transition.

=head2 status

Status of the condition, one of (`True`, `False`, `Unknown`).

=head2 type

Type of the condition, known values are (`Ready`).

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
