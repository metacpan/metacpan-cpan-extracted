package IO::K8s::CertManager::V1::CertificateACMEARIStatus;
# ABSTRACT: ARI stores the ACME Renewal Information that is fetched from the ACME server in accordance with RFC 9773.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s explanationURL  => Str;
k8s lastChecked     => Time;
k8s lastError       => Str;
k8s nextCheck       => Time;
k8s suggestedWindow => '+IO::K8s::CertManager::V1::ACMERenewalWindow';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::CertificateACMEARIStatus - ARI stores the ACME Renewal Information that is fetched from the ACME server in accordance with RFC 9773.

=head1 VERSION

version 1.108

=head2 explanationURL

ExplanationURL is a human-readable URL that may explain why the suggested window
has its current value.

=head2 lastChecked

LastChecked is the time at which the ACME server was last checked for renewal information.

=head2 lastError

LastError is the last error encountered when checking the ACME server for renewal information, if any.

=head2 nextCheck

NextCheck is the time at which the ACME server will next be checked for renewal information.

=head2 suggestedWindow

SuggestedWindow is the suggested renewal window as returned by the ACME server in accordance with RFC 9773.

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
