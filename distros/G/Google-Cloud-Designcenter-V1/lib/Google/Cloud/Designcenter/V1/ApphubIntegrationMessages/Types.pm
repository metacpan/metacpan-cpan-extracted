package Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RegisterAppHubApplicationResourcesRequest',
    as InstanceOf['Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::RegisterAppHubApplicationResourcesRequest'];

coerce 'RegisterAppHubApplicationResourcesRequest',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::RegisterAppHubApplicationResourcesRequest'->new($_) };

declare 'RepeatedRegisterAppHubApplicationResourcesRequest',
    as ArrayRef[RegisterAppHubApplicationResourcesRequest()];

coerce 'RepeatedRegisterAppHubApplicationResourcesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::RegisterAppHubApplicationResourcesRequest'->new($_) } @$_ ] };

declare 'MapStringRegisterAppHubApplicationResourcesRequest',
    as HashRef[RegisterAppHubApplicationResourcesRequest()];

declare 'RegisterAppHubApplicationResourcesResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::RegisterAppHubApplicationResourcesResponse'];

coerce 'RegisterAppHubApplicationResourcesResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::RegisterAppHubApplicationResourcesResponse'->new($_) };

declare 'RepeatedRegisterAppHubApplicationResourcesResponse',
    as ArrayRef[RegisterAppHubApplicationResourcesResponse()];

coerce 'RepeatedRegisterAppHubApplicationResourcesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::RegisterAppHubApplicationResourcesResponse'->new($_) } @$_ ] };

declare 'MapStringRegisterAppHubApplicationResourcesResponse',
    as HashRef[RegisterAppHubApplicationResourcesResponse()];

declare 'DeployedResourceResponse',
    as InstanceOf['Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::DeployedResourceResponse'];

coerce 'DeployedResourceResponse',
    from HashRef, via { 'Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::DeployedResourceResponse'->new($_) };

declare 'RepeatedDeployedResourceResponse',
    as ArrayRef[DeployedResourceResponse()];

coerce 'RepeatedDeployedResourceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::DeployedResourceResponse'->new($_) } @$_ ] };

declare 'MapStringDeployedResourceResponse',
    as HashRef[DeployedResourceResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Designcenter::V1::ApphubIntegrationMessages::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
