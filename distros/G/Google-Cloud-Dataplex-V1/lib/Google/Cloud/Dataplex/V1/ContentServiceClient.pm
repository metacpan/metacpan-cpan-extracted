package Google::Cloud::Dataplex::V1::ContentServiceClient;

use strict;
use warnings;

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Dataplex::V1::DataDocumentation;
use Google::Cloud::Dataplex::V1::Resources;
use Google::Cloud::Dataplex::V1::DatascansCommon;
use Google::Cloud::Dataplex::V1::DataDiscovery;
use Google::Cloud::Dataplex::V1::Security;
use Google::Cloud::Dataplex::V1::Processing;
use Google::Cloud::Dataplex::V1::DataQualityRuleTemplate;
use Google::Cloud::Dataplex::V1::Content;
use Google::Cloud::Dataplex::V1::Metadata;
use Google::Cloud::Dataplex::V1::Analyze;
use Google::Cloud::Dataplex::V1::Tasks;
use Google::Cloud::Dataplex::V1::Logs;
use Google::Cloud::Dataplex::V1::DataProfile;
use Google::Cloud::Dataplex::V1::DataQuality;
use Google::Cloud::Dataplex::V1::Service;
use Google::Cloud::Dataplex::V1::Datascans;
use Google::Cloud::Dataplex::V1::Catalog;
use Google::Cloud::Dataplex::V1::Cmek;
use Google::Cloud::Dataplex::V1::BusinessGlossary;
use Google::Cloud::Dataplex::V1::DataTaxonomy;
use Google::Cloud::Dataplex::V1::ApprovalWorkflow;
use Google::Cloud::Dataplex::V1::DataProducts;

our $VERSION = '0.06';
1; # End of Google::Cloud::Dataplex::V1::ContentServiceClient

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::ContentServiceClient - Auto-generated Protocol Buffers schema container

=head1 DESCRIPTION

This is an auto-generated Protocol Buffers schema container module for Google Cloud Services.

=head1 SYNOPSIS

    use Google::Cloud::Dataplex::V1::BusinessGlossaryServiceClient;

    my $client = Google::Cloud::Dataplex::V1::BusinessGlossaryServiceClient->new();

=head1 CLIENTS

This distribution provides the following service client classes:

=over 4

=item * L<Google::Cloud::Dataplex::V1::BusinessGlossaryServiceClient>

=item * L<Google::Cloud::Dataplex::V1::CatalogServiceClient>

=item * L<Google::Cloud::Dataplex::V1::CmekServiceClient>

=item * L<Google::Cloud::Dataplex::V1::ContentServiceClient>

=item * L<Google::Cloud::Dataplex::V1::DataProductServiceClient>

=item * L<Google::Cloud::Dataplex::V1::DataScanServiceClient>

=item * L<Google::Cloud::Dataplex::V1::DataTaxonomyServiceClient>

=item * L<Google::Cloud::Dataplex::V1::DataplexServiceClient>

=item * L<Google::Cloud::Dataplex::V1::MetadataServiceClient>

=back

=head1 SEE ALSO

L<Google::Cloud::Dataplex::V1::BusinessGlossaryServiceClient>, L<Google::Cloud::Dataplex::V1::CatalogServiceClient>, L<Google::Cloud::Dataplex::V1::CmekServiceClient>, L<Google::Cloud::Dataplex::V1::ContentServiceClient>, L<Google::Cloud::Dataplex::V1::DataProductServiceClient>, L<Google::Cloud::Dataplex::V1::DataScanServiceClient>, L<Google::Cloud::Dataplex::V1::DataTaxonomyServiceClient>, L<Google::Cloud::Dataplex::V1::DataplexServiceClient>, L<Google::Cloud::Dataplex::V1::MetadataServiceClient>

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/dataplex/v1/analyze.proto>

=item * C<googleapis/google/cloud/dataplex/v1/approval_workflow.proto>

=item * C<googleapis/google/cloud/dataplex/v1/business_glossary.proto>

=item * C<googleapis/google/cloud/dataplex/v1/catalog.proto>

=item * C<googleapis/google/cloud/dataplex/v1/cmek.proto>

=item * C<googleapis/google/cloud/dataplex/v1/content.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_discovery.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_documentation.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_products.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_profile.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_quality.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_quality_rule_template.proto>

=item * C<googleapis/google/cloud/dataplex/v1/data_taxonomy.proto>

=item * C<googleapis/google/cloud/dataplex/v1/datascans.proto>

=item * C<googleapis/google/cloud/dataplex/v1/datascans_common.proto>

=item * C<googleapis/google/cloud/dataplex/v1/logs.proto>

=item * C<googleapis/google/cloud/dataplex/v1/metadata.proto>

=item * C<googleapis/google/cloud/dataplex/v1/processing.proto>

=item * C<googleapis/google/cloud/dataplex/v1/resources.proto>

=item * C<googleapis/google/cloud/dataplex/v1/security.proto>

=item * C<googleapis/google/cloud/dataplex/v1/service.proto>

=item * C<googleapis/google/cloud/dataplex/v1/tasks.proto>



=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
