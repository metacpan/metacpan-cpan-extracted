package Google::Cloud::Appengine::V1::VersionsClient;

use strict;
use warnings;

use Protobuf;
use Google::Api::Common;
use Google::Appengine::V1::Domain;
use Google::Appengine::V1::NetworkSettings;
use Google::Appengine::V1::DeployedFiles;
use Google::Appengine::V1::DomainMapping;
use Google::Appengine::V1::Firewall;
use Google::Appengine::V1::Certificate;
use Google::Appengine::V1::Operation;
use Google::Appengine::V1::Service;
use Google::Appengine::V1::Deploy;
use Google::Appengine::V1::AppYaml;
use Google::Appengine::V1::Application;
use Google::Appengine::V1::Location;
use Google::Appengine::V1::Instance;
use Google::Appengine::V1::Version;
use Google::Appengine::V1::Appengine;
use Google::Appengine::V1::AuditData;

our $VERSION = '0.06';
1; # End of Google::Cloud::Appengine::V1::VersionsClient

__END__

=head1 NAME

Google::Cloud::Appengine::V1::VersionsClient - Auto-generated Protocol Buffers schema container

=head1 DESCRIPTION

This is an auto-generated Protocol Buffers schema container module for Google Cloud Services.

=head1 SYNOPSIS

    use Google::Cloud::Appengine::V1::ApplicationsClient;

    my $client = Google::Cloud::Appengine::V1::ApplicationsClient->new();

=head1 CLIENTS

This distribution provides the following service client classes:

=over 4

=item * L<Google::Cloud::Appengine::V1::ApplicationsClient>

=item * L<Google::Cloud::Appengine::V1::AuthorizedCertificatesClient>

=item * L<Google::Cloud::Appengine::V1::AuthorizedDomainsClient>

=item * L<Google::Cloud::Appengine::V1::DomainMappingsClient>

=item * L<Google::Cloud::Appengine::V1::FirewallClient>

=item * L<Google::Cloud::Appengine::V1::InstancesClient>

=item * L<Google::Cloud::Appengine::V1::ServicesClient>

=item * L<Google::Cloud::Appengine::V1::VersionsClient>

=back

=head1 SEE ALSO

L<Google::Cloud::Appengine::V1::ApplicationsClient>, L<Google::Cloud::Appengine::V1::AuthorizedCertificatesClient>, L<Google::Cloud::Appengine::V1::AuthorizedDomainsClient>, L<Google::Cloud::Appengine::V1::DomainMappingsClient>, L<Google::Cloud::Appengine::V1::FirewallClient>, L<Google::Cloud::Appengine::V1::InstancesClient>, L<Google::Cloud::Appengine::V1::ServicesClient>, L<Google::Cloud::Appengine::V1::VersionsClient>

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/appengine/v1/app_yaml.proto>

=item * C<googleapis/google/appengine/v1/appengine.proto>

=item * C<googleapis/google/appengine/v1/application.proto>

=item * C<googleapis/google/appengine/v1/audit_data.proto>

=item * C<googleapis/google/appengine/v1/certificate.proto>

=item * C<googleapis/google/appengine/v1/deploy.proto>

=item * C<googleapis/google/appengine/v1/deployed_files.proto>

=item * C<googleapis/google/appengine/v1/domain.proto>

=item * C<googleapis/google/appengine/v1/domain_mapping.proto>

=item * C<googleapis/google/appengine/v1/firewall.proto>

=item * C<googleapis/google/appengine/v1/instance.proto>

=item * C<googleapis/google/appengine/v1/location.proto>

=item * C<googleapis/google/appengine/v1/network_settings.proto>

=item * C<googleapis/google/appengine/v1/operation.proto>

=item * C<googleapis/google/appengine/v1/service.proto>

=item * C<googleapis/google/appengine/v1/version.proto>



=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
