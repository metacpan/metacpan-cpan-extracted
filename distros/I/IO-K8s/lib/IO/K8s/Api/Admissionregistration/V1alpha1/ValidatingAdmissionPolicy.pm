package IO::K8s::Api::Admissionregistration::V1alpha1::ValidatingAdmissionPolicy;
# ABSTRACT: ValidatingAdmissionPolicy describes the definition of an admission validation policy that accepts or rejects an object without changing it.
our $VERSION = '1.006';
use IO::K8s::APIObject;


k8s spec => 'Admissionregistration::V1alpha1::ValidatingAdmissionPolicySpec';


k8s status => 'Admissionregistration::V1alpha1::ValidatingAdmissionPolicyStatus';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Admissionregistration::V1alpha1::ValidatingAdmissionPolicy - ValidatingAdmissionPolicy describes the definition of an admission validation policy that accepts or rejects an object without changing it.

=head1 VERSION

version 1.006

=head1 DESCRIPTION

ValidatingAdmissionPolicy describes the definition of an admission validation policy that accepts or rejects an object without changing it.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

Specification of the desired behavior of the ValidatingAdmissionPolicy.

=head2 status

The status of the ValidatingAdmissionPolicy, including warnings that are useful to determine if the policy behaves in the expected way. Populated by the system. Read-only.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#validatingadmissionpolicy-v1alpha1-admissionregistration.k8s.io>

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
