package IO::K8s::Api::Flowcontrol::V1beta3::PolicyRulesWithSubjects;
# ABSTRACT: PolicyRulesWithSubjects prescribes a test that applies to a request to an apiserver. The test considers the subject making the request, the verb being requested, and the resource to be acted upon. This PolicyRulesWithSubjects matches a request if and only if both (a) at least one member of subjects matches the request and (b) at least one member of resourceRules or nonResourceRules matches the request.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s nonResourceRules => ['Flowcontrol::V1beta3::NonResourcePolicyRule'];


k8s resourceRules => ['Flowcontrol::V1beta3::ResourcePolicyRule'];


k8s subjects => ['Flowcontrol::V1beta3::Subject'], 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Flowcontrol::V1beta3::PolicyRulesWithSubjects - PolicyRulesWithSubjects prescribes a test that applies to a request to an apiserver. The test considers the subject making the request, the verb being requested, and the resource to be acted upon. This PolicyRulesWithSubjects matches a request if and only if both (a) at least one member of subjects matches the request and (b) at least one member of resourceRules or nonResourceRules matches the request.

=head1 VERSION

version 1.009

=head2 nonResourceRules

C<nonResourceRules> is a list of NonResourcePolicyRules that identify matching requests according to their verb and the target non-resource URL.

=head2 resourceRules

C<resourceRules> is a slice of ResourcePolicyRules that identify matching requests according to their verb and the target resource. At least one of C<resourceRules> and C<nonResourceRules> has to be non-empty.

=head2 subjects

subjects is the list of normal user, serviceaccount, or group that this rule cares about. There must be at least one member in this slice. A slice that includes both the system:authenticated and system:unauthenticated user groups matches every request. Required.

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
