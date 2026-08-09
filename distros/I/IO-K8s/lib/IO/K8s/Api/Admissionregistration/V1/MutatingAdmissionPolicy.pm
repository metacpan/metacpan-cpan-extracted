package IO::K8s::Api::Admissionregistration::V1::MutatingAdmissionPolicy;
# ABSTRACT: MutatingAdmissionPolicy describes the definition of an admission mutation policy that mutates the object coming into admission chain.
our $VERSION = '1.105';
use IO::K8s::APIObject;


k8s spec => 'Admissionregistration::V1::MutatingAdmissionPolicySpec';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Admissionregistration::V1::MutatingAdmissionPolicy - MutatingAdmissionPolicy describes the definition of an admission mutation policy that mutates the object coming into admission chain.

=head1 VERSION

version 1.105

=head1 DESCRIPTION

MutatingAdmissionPolicy describes the definition of an admission mutation policy that mutates the object coming into admission chain.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

spec defines the desired behavior of the MutatingAdmissionPolicy.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#mutatingadmissionpolicy-v1-admissionregistration.k8s.io>

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
