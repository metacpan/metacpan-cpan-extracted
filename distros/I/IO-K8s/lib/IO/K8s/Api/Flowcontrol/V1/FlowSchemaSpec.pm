package IO::K8s::Api::Flowcontrol::V1::FlowSchemaSpec;
# ABSTRACT: FlowSchemaSpec describes how the FlowSchema's specification looks like.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s distinguisherMethod => 'Flowcontrol::V1::FlowDistinguisherMethod';


k8s matchingPrecedence => Int;


k8s priorityLevelConfiguration => 'Flowcontrol::V1::PriorityLevelConfigurationReference', 'required';


k8s rules => ['Flowcontrol::V1::PolicyRulesWithSubjects'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Flowcontrol::V1::FlowSchemaSpec - FlowSchemaSpec describes how the FlowSchema's specification looks like.

=head1 VERSION

version 1.100

=head2 distinguisherMethod

`distinguisherMethod` defines how to compute the flow distinguisher for requests that match this schema. `nil` specifies that the distinguisher is disabled and thus will always be the empty string.

=head2 matchingPrecedence

`matchingPrecedence` is used to choose among the FlowSchemas that match a given request. The chosen FlowSchema is among those with the numerically lowest (which we take to be logically highest) MatchingPrecedence.  Each MatchingPrecedence value must be ranged in [1,10000]. Note that if the precedence is not specified, it will be set to 1000 as default.

=head2 priorityLevelConfiguration

`priorityLevelConfiguration` should reference a PriorityLevelConfiguration in the cluster. If the reference cannot be resolved, the FlowSchema will be ignored and marked as invalid in its status. Required.

=head2 rules

`rules` describes which requests will match this flow schema. This FlowSchema matches a request if and only if at least one member of rules matches the request. if it is an empty slice, there will be no requests matching the FlowSchema.

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
