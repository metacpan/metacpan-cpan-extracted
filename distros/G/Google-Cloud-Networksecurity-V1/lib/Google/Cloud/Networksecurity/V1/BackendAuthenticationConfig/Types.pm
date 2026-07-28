package Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackendAuthenticationConfig',
    as InstanceOf['Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::BackendAuthenticationConfig'];

coerce 'BackendAuthenticationConfig',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::BackendAuthenticationConfig'->new($_) };

declare 'RepeatedBackendAuthenticationConfig',
    as ArrayRef[BackendAuthenticationConfig()];

coerce 'RepeatedBackendAuthenticationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::BackendAuthenticationConfig'->new($_) } @$_ ] };

declare 'MapStringBackendAuthenticationConfig',
    as HashRef[BackendAuthenticationConfig()];

declare 'WellKnownRoots',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::BackendAuthenticationConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::BackendAuthenticationConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::BackendAuthenticationConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListBackendAuthenticationConfigsRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::ListBackendAuthenticationConfigsRequest'];

coerce 'ListBackendAuthenticationConfigsRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::ListBackendAuthenticationConfigsRequest'->new($_) };

declare 'RepeatedListBackendAuthenticationConfigsRequest',
    as ArrayRef[ListBackendAuthenticationConfigsRequest()];

coerce 'RepeatedListBackendAuthenticationConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::ListBackendAuthenticationConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackendAuthenticationConfigsRequest',
    as HashRef[ListBackendAuthenticationConfigsRequest()];

declare 'ListBackendAuthenticationConfigsResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::ListBackendAuthenticationConfigsResponse'];

coerce 'ListBackendAuthenticationConfigsResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::ListBackendAuthenticationConfigsResponse'->new($_) };

declare 'RepeatedListBackendAuthenticationConfigsResponse',
    as ArrayRef[ListBackendAuthenticationConfigsResponse()];

coerce 'RepeatedListBackendAuthenticationConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::ListBackendAuthenticationConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackendAuthenticationConfigsResponse',
    as HashRef[ListBackendAuthenticationConfigsResponse()];

declare 'GetBackendAuthenticationConfigRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::GetBackendAuthenticationConfigRequest'];

coerce 'GetBackendAuthenticationConfigRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::GetBackendAuthenticationConfigRequest'->new($_) };

declare 'RepeatedGetBackendAuthenticationConfigRequest',
    as ArrayRef[GetBackendAuthenticationConfigRequest()];

coerce 'RepeatedGetBackendAuthenticationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::GetBackendAuthenticationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetBackendAuthenticationConfigRequest',
    as HashRef[GetBackendAuthenticationConfigRequest()];

declare 'CreateBackendAuthenticationConfigRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::CreateBackendAuthenticationConfigRequest'];

coerce 'CreateBackendAuthenticationConfigRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::CreateBackendAuthenticationConfigRequest'->new($_) };

declare 'RepeatedCreateBackendAuthenticationConfigRequest',
    as ArrayRef[CreateBackendAuthenticationConfigRequest()];

coerce 'RepeatedCreateBackendAuthenticationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::CreateBackendAuthenticationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBackendAuthenticationConfigRequest',
    as HashRef[CreateBackendAuthenticationConfigRequest()];

declare 'UpdateBackendAuthenticationConfigRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::UpdateBackendAuthenticationConfigRequest'];

coerce 'UpdateBackendAuthenticationConfigRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::UpdateBackendAuthenticationConfigRequest'->new($_) };

declare 'RepeatedUpdateBackendAuthenticationConfigRequest',
    as ArrayRef[UpdateBackendAuthenticationConfigRequest()];

coerce 'RepeatedUpdateBackendAuthenticationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::UpdateBackendAuthenticationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateBackendAuthenticationConfigRequest',
    as HashRef[UpdateBackendAuthenticationConfigRequest()];

declare 'DeleteBackendAuthenticationConfigRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::DeleteBackendAuthenticationConfigRequest'];

coerce 'DeleteBackendAuthenticationConfigRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::DeleteBackendAuthenticationConfigRequest'->new($_) };

declare 'RepeatedDeleteBackendAuthenticationConfigRequest',
    as ArrayRef[DeleteBackendAuthenticationConfigRequest()];

coerce 'RepeatedDeleteBackendAuthenticationConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::DeleteBackendAuthenticationConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBackendAuthenticationConfigRequest',
    as HashRef[DeleteBackendAuthenticationConfigRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::BackendAuthenticationConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
