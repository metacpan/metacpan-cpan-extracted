package Google::Cloud::Appengine::V1beta::DomainMappingsClient;

use strict;
use warnings;

use Protobuf;
use Google::Api::Common;
use Google::Appengine::V1beta::Firewall;
use Google::Appengine::V1beta::DomainMapping;
use Google::Appengine::V1beta::NetworkSettings;
use Google::Appengine::V1beta::Domain;
use Google::Appengine::V1beta::AppYaml;
use Google::Appengine::V1beta::Deploy;
use Google::Appengine::V1beta::Application;
use Google::Appengine::V1beta::Service;
use Google::Appengine::V1beta::Location;
use Google::Appengine::V1beta::Certificate;
use Google::Appengine::V1beta::Instance;
use Google::Appengine::V1beta::Operation;
use Google::Appengine::V1beta::Version;
use Google::Appengine::V1beta::Appengine;
use Google::Appengine::V1beta::AuditData;

our $VERSION = '0.06';
1; # End of Google::Cloud::Appengine::V1beta::DomainMappingsClient

__END__

=head1 NAME

Google::Cloud::Appengine::V1beta::DomainMappingsClient - Auto-generated Protocol Buffers schema container

=head1 DESCRIPTION

This is an auto-generated Protocol Buffers schema container module for Google Cloud Services.

=head1 SYNOPSIS

    use Google::Cloud::Appengine::V1beta::ApplicationsClient;

    my $client = Google::Cloud::Appengine::V1beta::ApplicationsClient->new();

=head1 CLIENTS

This distribution provides the following service client classes:

=over 4

=item * L<Google::Cloud::Appengine::V1beta::ApplicationsClient>

=item * L<Google::Cloud::Appengine::V1beta::AuthorizedCertificatesClient>

=item * L<Google::Cloud::Appengine::V1beta::AuthorizedDomainsClient>

=item * L<Google::Cloud::Appengine::V1beta::DomainMappingsClient>

=item * L<Google::Cloud::Appengine::V1beta::FirewallClient>

=item * L<Google::Cloud::Appengine::V1beta::InstancesClient>

=item * L<Google::Cloud::Appengine::V1beta::ServicesClient>

=item * L<Google::Cloud::Appengine::V1beta::VersionsClient>

=back

=head1 SEE ALSO

L<Google::Cloud::Appengine::V1beta::ApplicationsClient>, L<Google::Cloud::Appengine::V1beta::AuthorizedCertificatesClient>, L<Google::Cloud::Appengine::V1beta::AuthorizedDomainsClient>, L<Google::Cloud::Appengine::V1beta::DomainMappingsClient>, L<Google::Cloud::Appengine::V1beta::FirewallClient>, L<Google::Cloud::Appengine::V1beta::InstancesClient>, L<Google::Cloud::Appengine::V1beta::ServicesClient>, L<Google::Cloud::Appengine::V1beta::VersionsClient>

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/appengine/v1beta/app_yaml.proto>

=item * C<googleapis/google/appengine/v1beta/appengine.proto>

=item * C<googleapis/google/appengine/v1beta/application.proto>

=item * C<googleapis/google/appengine/v1beta/audit_data.proto>

=item * C<googleapis/google/appengine/v1beta/certificate.proto>

=item * C<googleapis/google/appengine/v1beta/deploy.proto>

=item * C<googleapis/google/appengine/v1beta/domain.proto>

=item * C<googleapis/google/appengine/v1beta/domain_mapping.proto>

=item * C<googleapis/google/appengine/v1beta/firewall.proto>

=item * C<googleapis/google/appengine/v1beta/instance.proto>

=item * C<googleapis/google/appengine/v1beta/location.proto>

=item * C<googleapis/google/appengine/v1beta/network_settings.proto>

=item * C<googleapis/google/appengine/v1beta/operation.proto>

=item * C<googleapis/google/appengine/v1beta/service.proto>

=item * C<googleapis/google/appengine/v1beta/version.proto>



=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
