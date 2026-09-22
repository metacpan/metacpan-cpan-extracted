package IO::K8s::CertManager::V1::ChallengeStatus;
# ABSTRACT: ChallengeStatus
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s presented   => Bool;
k8s presentedAt => Time;
k8s processing  => Bool;
k8s reason      => Str;
k8s state       => Str, { enum => [qw(valid ready pending processing invalid expired errored)] };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ChallengeStatus - ChallengeStatus

=head1 VERSION

version 1.108

=head2 presented

Presented is true once cert-manager has configured the solver resources
needed to expose this challenge's validation material.
For example, the DNS01 TXT record has been created, or the HTTP01 solver
has been configured to serve the challenge token.
This does not imply the self check is passing, that the ACME server has
validated the challenge, or that cert-manager has already accepted the
challenge with the ACME server.

=head2 presentedAt

PresentedAt records when cert-manager first configured the solver
resources for this challenge. This is used by the optional delay-based
readiness logic.

=head2 processing

Used to denote whether this challenge should be processed or not.
This field will only be set to true by the 'scheduling' component.
It will only be set to false by the 'challenges' controller, after the
challenge has reached a final state or timed out.
If this field is set to false, the challenge controller will not take
any more action.

=head2 reason

Contains human readable information on why the Challenge is in the
current state.

=head2 state

Contains the current 'state' of the challenge.
If not set, the state of the challenge is unknown.

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
