package IO::K8s::Api::Admissionregistration::V1beta1::ValidatingAdmissionPolicyStatus;
# ABSTRACT: ValidatingAdmissionPolicyStatus represents the status of an admission validation policy.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s conditions => ['Meta::V1::Condition'];


k8s observedGeneration => Int;


k8s typeChecking => 'Admissionregistration::V1beta1::TypeChecking';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Admissionregistration::V1beta1::ValidatingAdmissionPolicyStatus - ValidatingAdmissionPolicyStatus represents the status of an admission validation policy.

=head1 VERSION

version 1.100

=head2 conditions

The conditions represent the latest available observations of a policy's current state.

=head2 observedGeneration

The generation observed by the controller.

=head2 typeChecking

The results of type checking for each expression. Presence of this field indicates the completion of the type checking.

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
