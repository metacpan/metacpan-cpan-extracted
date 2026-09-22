package IO::K8s::CertManager::V1::CertificateRenewalWindows;
# ABSTRACT: CertificateRenewalWindows is the definition for renewal windows
our $VERSION = '1.108';
use utf8;
use IO::K8s::Resource;

k8s cron           => Str, { required => 'schema' };
k8s timezone       => Str;
k8s windowDuration => Str, { required => 'schema', pattern => qr/^([0-9]+(\.[0-9]+)?(s|m|h))+$/ };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::CertificateRenewalWindows - CertificateRenewalWindows is the definition for renewal windows

=head1 VERSION

version 1.108

=head2 cron

`cron` is a cron compliant string to allow when the renewal should be allowed. Format is as shown below:
* * * * *
| | | | |
| | | | day of the week (0–6) (Sunday to Saturday;
| | | month (1–12)             7 is also Sunday on some systems)
| | day of the month (1–31)
| hour (0–23)
minute (0–59)

=head2 timezone

`timezone` is IANA compliant timezone. For example America/Denver.
If this field is not set, timezone is treated as UTC.

=head2 windowDuration

`windowDuration` is how long the cron definition is active for.
Value must be in units accepted by Go time.ParseDuration https://golang.org/pkg/time/#ParseDuration.

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
