package IO::K8s::ExternalSecrets::V1::BeyondtrustWorkloadCredentialsServer;
# ABSTRACT: Server configures the BeyondTrust Workload Credentials server connection details.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s apiUrl => Str, { required => 'schema' };
k8s siteId => Str, { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::BeyondtrustWorkloadCredentialsServer - Server configures the BeyondTrust Workload Credentials server connection details.

=head1 VERSION

version 1.108

=head2 apiUrl

APIURL is the base URL of your BeyondTrust Workload Credentials API server.
This should be the full URL to your BeyondTrust instance.
Example: https://api.beyondtrust.io/siie
For more information, see: https://docs.beyondtrust.com/bt-docs/docs/secrets-api#base-url

=head2 siteId

SiteID is your BeyondTrust Workload Credentials site identifier (UUID format).
This identifier is unique to your BeyondTrust Workload Credentials instance.
You can find your Site ID in the BeyondTrust Workload Credentials admin console.
Example: a1b2c3d4-e5f6-4890-abcd-ef1234567890
For more information, see: https://docs.beyondtrust.com/bt-docs/docs/secrets-api

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
