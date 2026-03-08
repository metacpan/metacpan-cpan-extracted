package IO::K8s::Api::Scheduling::V1::PriorityClass;
# ABSTRACT: PriorityClass defines mapping from a priority class name to the priority integer value. The value can be any valid integer.
our $VERSION = '1.006';
use IO::K8s::APIObject;


k8s description => Str;


k8s globalDefault => Bool;


k8s preemptionPolicy => Str;


k8s value => Int, 'required';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1::PriorityClass - PriorityClass defines mapping from a priority class name to the priority integer value. The value can be any valid integer.

=head1 VERSION

version 1.006

=head1 DESCRIPTION

PriorityClass defines mapping from a priority class name to the priority integer value. The value can be any valid integer.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 description

description is an arbitrary string that usually provides guidelines on when this priority class should be used.

=head2 globalDefault

globalDefault specifies whether this PriorityClass should be considered as the default priority for pods that do not have any priority class. Only one PriorityClass can be marked as `globalDefault`. However, if more than one PriorityClasses exists with their `globalDefault` field set to true, the smallest value of such global default PriorityClasses will be used as the default priority.

=head2 preemptionPolicy

preemptionPolicy is the Policy for preempting pods with lower priority. One of Never, PreemptLowerPriority. Defaults to PreemptLowerPriority if unset.

=head2 value

value represents the integer value of this priority class. This is the actual priority that pods receive when they have the name of this class in their pod spec.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#priorityclass-v1-scheduling.k8s.io>

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
