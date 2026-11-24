package Google::Cloud::Apptopology::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Apptopology::V1::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'GenerateDiscoveredResourcesTopologyRequest',
    as InstanceOf['Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyRequest'];

coerce 'GenerateDiscoveredResourcesTopologyRequest',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyRequest'->new($_) };

declare 'RepeatedGenerateDiscoveredResourcesTopologyRequest',
    as ArrayRef[GenerateDiscoveredResourcesTopologyRequest()];

coerce 'RepeatedGenerateDiscoveredResourcesTopologyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateDiscoveredResourcesTopologyRequest',
    as HashRef[GenerateDiscoveredResourcesTopologyRequest()];

declare 'GenerateDiscoveredResourcesTopologyResponse',
    as InstanceOf['Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyResponse'];

coerce 'GenerateDiscoveredResourcesTopologyResponse',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyResponse'->new($_) };

declare 'RepeatedGenerateDiscoveredResourcesTopologyResponse',
    as ArrayRef[GenerateDiscoveredResourcesTopologyResponse()];

coerce 'RepeatedGenerateDiscoveredResourcesTopologyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateDiscoveredResourcesTopologyResponse',
    as HashRef[GenerateDiscoveredResourcesTopologyResponse()];

declare 'GetSchemaRequest',
    as InstanceOf['Google::Cloud::Apptopology::V1::Service::GetSchemaRequest'];

coerce 'GetSchemaRequest',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Service::GetSchemaRequest'->new($_) };

declare 'RepeatedGetSchemaRequest',
    as ArrayRef[GetSchemaRequest()];

coerce 'RepeatedGetSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Service::GetSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringGetSchemaRequest',
    as HashRef[GetSchemaRequest()];

declare 'ExploreSchemaRequest',
    as InstanceOf['Google::Cloud::Apptopology::V1::Service::ExploreSchemaRequest'];

coerce 'ExploreSchemaRequest',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Service::ExploreSchemaRequest'->new($_) };

declare 'RepeatedExploreSchemaRequest',
    as ArrayRef[ExploreSchemaRequest()];

coerce 'RepeatedExploreSchemaRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Service::ExploreSchemaRequest'->new($_) } @$_ ] };

declare 'MapStringExploreSchemaRequest',
    as HashRef[ExploreSchemaRequest()];

declare 'ExploreSchemaResponse',
    as InstanceOf['Google::Cloud::Apptopology::V1::Service::ExploreSchemaResponse'];

coerce 'ExploreSchemaResponse',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Service::ExploreSchemaResponse'->new($_) };

declare 'RepeatedExploreSchemaResponse',
    as ArrayRef[ExploreSchemaResponse()];

coerce 'RepeatedExploreSchemaResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Service::ExploreSchemaResponse'->new($_) } @$_ ] };

declare 'MapStringExploreSchemaResponse',
    as HashRef[ExploreSchemaResponse()];

declare 'GetDomainRequest',
    as InstanceOf['Google::Cloud::Apptopology::V1::Service::GetDomainRequest'];

coerce 'GetDomainRequest',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Service::GetDomainRequest'->new($_) };

declare 'RepeatedGetDomainRequest',
    as ArrayRef[GetDomainRequest()];

coerce 'RepeatedGetDomainRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Service::GetDomainRequest'->new($_) } @$_ ] };

declare 'MapStringGetDomainRequest',
    as HashRef[GetDomainRequest()];

declare 'ListDomainsRequest',
    as InstanceOf['Google::Cloud::Apptopology::V1::Service::ListDomainsRequest'];

coerce 'ListDomainsRequest',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Service::ListDomainsRequest'->new($_) };

declare 'RepeatedListDomainsRequest',
    as ArrayRef[ListDomainsRequest()];

coerce 'RepeatedListDomainsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Service::ListDomainsRequest'->new($_) } @$_ ] };

declare 'MapStringListDomainsRequest',
    as HashRef[ListDomainsRequest()];

declare 'ListDomainsResponse',
    as InstanceOf['Google::Cloud::Apptopology::V1::Service::ListDomainsResponse'];

coerce 'ListDomainsResponse',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Service::ListDomainsResponse'->new($_) };

declare 'RepeatedListDomainsResponse',
    as ArrayRef[ListDomainsResponse()];

coerce 'RepeatedListDomainsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Service::ListDomainsResponse'->new($_) } @$_ ] };

declare 'MapStringListDomainsResponse',
    as HashRef[ListDomainsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Apptopology::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
