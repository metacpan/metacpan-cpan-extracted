package IO::K8s::Api::Certificates::V1::CertificateSigningRequestCondition;
# ABSTRACT: CertificateSigningRequestCondition describes a condition of a CertificateSigningRequest object
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s lastTransitionTime => Time;


k8s lastUpdateTime => Time;


k8s message => Str;


k8s reason => Str;


k8s status => Str, 'required';


k8s type => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Certificates::V1::CertificateSigningRequestCondition - CertificateSigningRequestCondition describes a condition of a CertificateSigningRequest object

=head1 VERSION

version 1.008

=head2 lastTransitionTime

lastTransitionTime is the time the condition last transitioned from one status to another. If unset, when a new condition type is added or an existing condition's status is changed, the server defaults this to the current time.

=head2 lastUpdateTime

lastUpdateTime is the time of the last update to this condition

=head2 message

message contains a human readable message with details about the request state

=head2 reason

reason indicates a brief reason for the request state

=head2 status

status of the condition, one of True, False, Unknown. Approved, Denied, and Failed conditions may not be "False" or "Unknown".

=head2 type

type of the condition. Known conditions are "Approved", "Denied", and "Failed".

An "Approved" condition is added via the /approval subresource, indicating the request was approved and should be issued by the signer.

A "Denied" condition is added via the /approval subresource, indicating the request was denied and should not be issued by the signer.

A "Failed" condition is added via the /status subresource, indicating the signer failed to issue the certificate.

Approved and Denied conditions are mutually exclusive. Approved, Denied, and Failed conditions cannot be removed once added.

Only one condition of a given type is allowed.

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
