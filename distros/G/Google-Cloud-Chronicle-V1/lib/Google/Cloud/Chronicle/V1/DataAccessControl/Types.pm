package Google::Cloud::Chronicle::V1::DataAccessControl::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateDataAccessLabelRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::CreateDataAccessLabelRequest'];

coerce 'CreateDataAccessLabelRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::CreateDataAccessLabelRequest'->new($_) };

declare 'RepeatedCreateDataAccessLabelRequest',
    as ArrayRef[CreateDataAccessLabelRequest()];

coerce 'RepeatedCreateDataAccessLabelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::CreateDataAccessLabelRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataAccessLabelRequest',
    as HashRef[CreateDataAccessLabelRequest()];

declare 'GetDataAccessLabelRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::GetDataAccessLabelRequest'];

coerce 'GetDataAccessLabelRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::GetDataAccessLabelRequest'->new($_) };

declare 'RepeatedGetDataAccessLabelRequest',
    as ArrayRef[GetDataAccessLabelRequest()];

coerce 'RepeatedGetDataAccessLabelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::GetDataAccessLabelRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataAccessLabelRequest',
    as HashRef[GetDataAccessLabelRequest()];

declare 'ListDataAccessLabelsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::ListDataAccessLabelsRequest'];

coerce 'ListDataAccessLabelsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::ListDataAccessLabelsRequest'->new($_) };

declare 'RepeatedListDataAccessLabelsRequest',
    as ArrayRef[ListDataAccessLabelsRequest()];

coerce 'RepeatedListDataAccessLabelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::ListDataAccessLabelsRequest'->new($_) } @$_ ] };

declare 'MapStringListDataAccessLabelsRequest',
    as HashRef[ListDataAccessLabelsRequest()];

declare 'ListDataAccessLabelsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::ListDataAccessLabelsResponse'];

coerce 'ListDataAccessLabelsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::ListDataAccessLabelsResponse'->new($_) };

declare 'RepeatedListDataAccessLabelsResponse',
    as ArrayRef[ListDataAccessLabelsResponse()];

coerce 'RepeatedListDataAccessLabelsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::ListDataAccessLabelsResponse'->new($_) } @$_ ] };

declare 'MapStringListDataAccessLabelsResponse',
    as HashRef[ListDataAccessLabelsResponse()];

declare 'UpdateDataAccessLabelRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::UpdateDataAccessLabelRequest'];

coerce 'UpdateDataAccessLabelRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::UpdateDataAccessLabelRequest'->new($_) };

declare 'RepeatedUpdateDataAccessLabelRequest',
    as ArrayRef[UpdateDataAccessLabelRequest()];

coerce 'RepeatedUpdateDataAccessLabelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::UpdateDataAccessLabelRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataAccessLabelRequest',
    as HashRef[UpdateDataAccessLabelRequest()];

declare 'DeleteDataAccessLabelRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::DeleteDataAccessLabelRequest'];

coerce 'DeleteDataAccessLabelRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::DeleteDataAccessLabelRequest'->new($_) };

declare 'RepeatedDeleteDataAccessLabelRequest',
    as ArrayRef[DeleteDataAccessLabelRequest()];

coerce 'RepeatedDeleteDataAccessLabelRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::DeleteDataAccessLabelRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataAccessLabelRequest',
    as HashRef[DeleteDataAccessLabelRequest()];

declare 'CreateDataAccessScopeRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::CreateDataAccessScopeRequest'];

coerce 'CreateDataAccessScopeRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::CreateDataAccessScopeRequest'->new($_) };

declare 'RepeatedCreateDataAccessScopeRequest',
    as ArrayRef[CreateDataAccessScopeRequest()];

coerce 'RepeatedCreateDataAccessScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::CreateDataAccessScopeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataAccessScopeRequest',
    as HashRef[CreateDataAccessScopeRequest()];

declare 'GetDataAccessScopeRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::GetDataAccessScopeRequest'];

coerce 'GetDataAccessScopeRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::GetDataAccessScopeRequest'->new($_) };

declare 'RepeatedGetDataAccessScopeRequest',
    as ArrayRef[GetDataAccessScopeRequest()];

coerce 'RepeatedGetDataAccessScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::GetDataAccessScopeRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataAccessScopeRequest',
    as HashRef[GetDataAccessScopeRequest()];

declare 'ListDataAccessScopesRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::ListDataAccessScopesRequest'];

coerce 'ListDataAccessScopesRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::ListDataAccessScopesRequest'->new($_) };

declare 'RepeatedListDataAccessScopesRequest',
    as ArrayRef[ListDataAccessScopesRequest()];

coerce 'RepeatedListDataAccessScopesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::ListDataAccessScopesRequest'->new($_) } @$_ ] };

declare 'MapStringListDataAccessScopesRequest',
    as HashRef[ListDataAccessScopesRequest()];

declare 'ListDataAccessScopesResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::ListDataAccessScopesResponse'];

coerce 'ListDataAccessScopesResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::ListDataAccessScopesResponse'->new($_) };

declare 'RepeatedListDataAccessScopesResponse',
    as ArrayRef[ListDataAccessScopesResponse()];

coerce 'RepeatedListDataAccessScopesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::ListDataAccessScopesResponse'->new($_) } @$_ ] };

declare 'MapStringListDataAccessScopesResponse',
    as HashRef[ListDataAccessScopesResponse()];

declare 'UpdateDataAccessScopeRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::UpdateDataAccessScopeRequest'];

coerce 'UpdateDataAccessScopeRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::UpdateDataAccessScopeRequest'->new($_) };

declare 'RepeatedUpdateDataAccessScopeRequest',
    as ArrayRef[UpdateDataAccessScopeRequest()];

coerce 'RepeatedUpdateDataAccessScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::UpdateDataAccessScopeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataAccessScopeRequest',
    as HashRef[UpdateDataAccessScopeRequest()];

declare 'DeleteDataAccessScopeRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::DeleteDataAccessScopeRequest'];

coerce 'DeleteDataAccessScopeRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::DeleteDataAccessScopeRequest'->new($_) };

declare 'RepeatedDeleteDataAccessScopeRequest',
    as ArrayRef[DeleteDataAccessScopeRequest()];

coerce 'RepeatedDeleteDataAccessScopeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::DeleteDataAccessScopeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataAccessScopeRequest',
    as HashRef[DeleteDataAccessScopeRequest()];

declare 'DataAccessLabel',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessLabel'];

coerce 'DataAccessLabel',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessLabel'->new($_) };

declare 'RepeatedDataAccessLabel',
    as ArrayRef[DataAccessLabel()];

coerce 'RepeatedDataAccessLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessLabel'->new($_) } @$_ ] };

declare 'MapStringDataAccessLabel',
    as HashRef[DataAccessLabel()];

declare 'DataAccessScope',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessScope'];

coerce 'DataAccessScope',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessScope'->new($_) };

declare 'RepeatedDataAccessScope',
    as ArrayRef[DataAccessScope()];

coerce 'RepeatedDataAccessScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessScope'->new($_) } @$_ ] };

declare 'MapStringDataAccessScope',
    as HashRef[DataAccessScope()];

declare 'DataAccessLabelReference',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessLabelReference'];

coerce 'DataAccessLabelReference',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessLabelReference'->new($_) };

declare 'RepeatedDataAccessLabelReference',
    as ArrayRef[DataAccessLabelReference()];

coerce 'RepeatedDataAccessLabelReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessLabelReference'->new($_) } @$_ ] };

declare 'MapStringDataAccessLabelReference',
    as HashRef[DataAccessLabelReference()];

declare 'IngestionLabel',
    as InstanceOf['Google::Cloud::Chronicle::V1::DataAccessControl::IngestionLabel'];

coerce 'IngestionLabel',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DataAccessControl::IngestionLabel'->new($_) };

declare 'RepeatedIngestionLabel',
    as ArrayRef[IngestionLabel()];

coerce 'RepeatedIngestionLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DataAccessControl::IngestionLabel'->new($_) } @$_ ] };

declare 'MapStringIngestionLabel',
    as HashRef[IngestionLabel()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::DataAccessControl::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
