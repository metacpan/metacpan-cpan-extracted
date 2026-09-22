package IO::K8s::PrometheusOperator::V1::GlobalSMTPConfig;
# ABSTRACT: smtp defines global SMTP parameters.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s authIdentity     => Str;
k8s authPassword     => 'Core::V1::ConfigMapKeySelector';
k8s authSecret       => 'Core::V1::ConfigMapKeySelector';
k8s authUsername     => Str;
k8s forceImplicitTLS => Bool;
k8s from             => Str;
k8s hello            => Str;
k8s requireTLS       => Bool;
k8s smartHost        => '+IO::K8s::PrometheusOperator::V1::HostPort';
k8s tlsConfig        => '+IO::K8s::PrometheusOperator::V1::SafeTLSConfig';











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::GlobalSMTPConfig - smtp defines global SMTP parameters.

=head1 VERSION

version 1.108

=head2 authIdentity

authIdentity represents SMTP Auth using PLAIN

=head2 authPassword

authPassword represents SMTP Auth using LOGIN and PLAIN.

=head2 authSecret

authSecret represents SMTP Auth using CRAM-MD5.

=head2 authUsername

authUsername represents SMTP Auth using CRAM-MD5, LOGIN and PLAIN. If empty, Alertmanager doesn't authenticate to the SMTP server.

=head2 forceImplicitTLS

forceImplicitTLS defines whether to force use of implicit TLS (direct TLS connection) for better security.
true: force use of implicit TLS (direct TLS connection on any port)
false: force disable implicit TLS (use explicit TLS/STARTTLS if required)
nil (default): auto-detect based on port (465=implicit, other=explicit) for backward compatibility
It requires Alertmanager >= v0.31.0.

=head2 from

from defines the default SMTP From header field.

=head2 hello

hello defines the default hostname to identify to the SMTP server.

=head2 requireTLS

requireTLS defines the default SMTP TLS requirement.
Note that Go does not support unencrypted connections to remote SMTP endpoints.

=head2 smartHost

smartHost defines the default SMTP smarthost used for sending emails.

=head2 tlsConfig

tlsConfig defines the default TLS configuration for SMTP receivers

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
