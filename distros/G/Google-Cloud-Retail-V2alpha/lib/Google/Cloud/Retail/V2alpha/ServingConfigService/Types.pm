package Google::Cloud::Retail::V2alpha::ServingConfigService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateServingConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ServingConfigService::CreateServingConfigRequest'];

coerce 'CreateServingConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ServingConfigService::CreateServingConfigRequest'->new($_) };

declare 'RepeatedCreateServingConfigRequest',
    as ArrayRef[CreateServingConfigRequest()];

coerce 'RepeatedCreateServingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ServingConfigService::CreateServingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServingConfigRequest',
    as HashRef[CreateServingConfigRequest()];

declare 'UpdateServingConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ServingConfigService::UpdateServingConfigRequest'];

coerce 'UpdateServingConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ServingConfigService::UpdateServingConfigRequest'->new($_) };

declare 'RepeatedUpdateServingConfigRequest',
    as ArrayRef[UpdateServingConfigRequest()];

coerce 'RepeatedUpdateServingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ServingConfigService::UpdateServingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServingConfigRequest',
    as HashRef[UpdateServingConfigRequest()];

declare 'DeleteServingConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ServingConfigService::DeleteServingConfigRequest'];

coerce 'DeleteServingConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ServingConfigService::DeleteServingConfigRequest'->new($_) };

declare 'RepeatedDeleteServingConfigRequest',
    as ArrayRef[DeleteServingConfigRequest()];

coerce 'RepeatedDeleteServingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ServingConfigService::DeleteServingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServingConfigRequest',
    as HashRef[DeleteServingConfigRequest()];

declare 'GetServingConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ServingConfigService::GetServingConfigRequest'];

coerce 'GetServingConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ServingConfigService::GetServingConfigRequest'->new($_) };

declare 'RepeatedGetServingConfigRequest',
    as ArrayRef[GetServingConfigRequest()];

coerce 'RepeatedGetServingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ServingConfigService::GetServingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetServingConfigRequest',
    as HashRef[GetServingConfigRequest()];

declare 'ListServingConfigsRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ServingConfigService::ListServingConfigsRequest'];

coerce 'ListServingConfigsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ServingConfigService::ListServingConfigsRequest'->new($_) };

declare 'RepeatedListServingConfigsRequest',
    as ArrayRef[ListServingConfigsRequest()];

coerce 'RepeatedListServingConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ServingConfigService::ListServingConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListServingConfigsRequest',
    as HashRef[ListServingConfigsRequest()];

declare 'ListServingConfigsResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ServingConfigService::ListServingConfigsResponse'];

coerce 'ListServingConfigsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ServingConfigService::ListServingConfigsResponse'->new($_) };

declare 'RepeatedListServingConfigsResponse',
    as ArrayRef[ListServingConfigsResponse()];

coerce 'RepeatedListServingConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ServingConfigService::ListServingConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListServingConfigsResponse',
    as HashRef[ListServingConfigsResponse()];

declare 'AddControlRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ServingConfigService::AddControlRequest'];

coerce 'AddControlRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ServingConfigService::AddControlRequest'->new($_) };

declare 'RepeatedAddControlRequest',
    as ArrayRef[AddControlRequest()];

coerce 'RepeatedAddControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ServingConfigService::AddControlRequest'->new($_) } @$_ ] };

declare 'MapStringAddControlRequest',
    as HashRef[AddControlRequest()];

declare 'RemoveControlRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ServingConfigService::RemoveControlRequest'];

coerce 'RemoveControlRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ServingConfigService::RemoveControlRequest'->new($_) };

declare 'RepeatedRemoveControlRequest',
    as ArrayRef[RemoveControlRequest()];

coerce 'RepeatedRemoveControlRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ServingConfigService::RemoveControlRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveControlRequest',
    as HashRef[RemoveControlRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::ServingConfigService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
