package Google::Cloud::Dataplex::V1::DataProducts::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataProduct',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::DataProduct'];

coerce 'DataProduct',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::DataProduct'->new($_) };

declare 'RepeatedDataProduct',
    as ArrayRef[DataProduct()];

coerce 'RepeatedDataProduct',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::DataProduct'->new($_) } @$_ ] };

declare 'MapStringDataProduct',
    as HashRef[DataProduct()];

declare 'Principal',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::DataProduct::Principal'];

coerce 'Principal',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::DataProduct::Principal'->new($_) };

declare 'RepeatedPrincipal',
    as ArrayRef[Principal()];

coerce 'RepeatedPrincipal',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::DataProduct::Principal'->new($_) } @$_ ] };

declare 'MapStringPrincipal',
    as HashRef[Principal()];

declare 'AccessGroup',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::DataProduct::AccessGroup'];

coerce 'AccessGroup',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::DataProduct::AccessGroup'->new($_) };

declare 'RepeatedAccessGroup',
    as ArrayRef[AccessGroup()];

coerce 'RepeatedAccessGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::DataProduct::AccessGroup'->new($_) } @$_ ] };

declare 'MapStringAccessGroup',
    as HashRef[AccessGroup()];

declare 'AccessApprovalConfig',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::DataProduct::AccessApprovalConfig'];

coerce 'AccessApprovalConfig',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::DataProduct::AccessApprovalConfig'->new($_) };

declare 'RepeatedAccessApprovalConfig',
    as ArrayRef[AccessApprovalConfig()];

coerce 'RepeatedAccessApprovalConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::DataProduct::AccessApprovalConfig'->new($_) } @$_ ] };

declare 'MapStringAccessApprovalConfig',
    as HashRef[AccessApprovalConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::DataProduct::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::DataProduct::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::DataProduct::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AccessGroupsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::DataProduct::AccessGroupsEntry'];

coerce 'AccessGroupsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::DataProduct::AccessGroupsEntry'->new($_) };

declare 'RepeatedAccessGroupsEntry',
    as ArrayRef[AccessGroupsEntry()];

coerce 'RepeatedAccessGroupsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::DataProduct::AccessGroupsEntry'->new($_) } @$_ ] };

declare 'MapStringAccessGroupsEntry',
    as HashRef[AccessGroupsEntry()];

declare 'DataAsset',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::DataAsset'];

coerce 'DataAsset',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::DataAsset'->new($_) };

declare 'RepeatedDataAsset',
    as ArrayRef[DataAsset()];

coerce 'RepeatedDataAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::DataAsset'->new($_) } @$_ ] };

declare 'MapStringDataAsset',
    as HashRef[DataAsset()];

declare 'AccessGroupConfig',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::DataAsset::AccessGroupConfig'];

coerce 'AccessGroupConfig',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::DataAsset::AccessGroupConfig'->new($_) };

declare 'RepeatedAccessGroupConfig',
    as ArrayRef[AccessGroupConfig()];

coerce 'RepeatedAccessGroupConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::DataAsset::AccessGroupConfig'->new($_) } @$_ ] };

declare 'MapStringAccessGroupConfig',
    as HashRef[AccessGroupConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::DataAsset::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::DataAsset::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::DataAsset::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AccessGroupConfigsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::DataAsset::AccessGroupConfigsEntry'];

coerce 'AccessGroupConfigsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::DataAsset::AccessGroupConfigsEntry'->new($_) };

declare 'RepeatedAccessGroupConfigsEntry',
    as ArrayRef[AccessGroupConfigsEntry()];

coerce 'RepeatedAccessGroupConfigsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::DataAsset::AccessGroupConfigsEntry'->new($_) } @$_ ] };

declare 'MapStringAccessGroupConfigsEntry',
    as HashRef[AccessGroupConfigsEntry()];

declare 'CreateDataProductRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::CreateDataProductRequest'];

coerce 'CreateDataProductRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::CreateDataProductRequest'->new($_) };

declare 'RepeatedCreateDataProductRequest',
    as ArrayRef[CreateDataProductRequest()];

coerce 'RepeatedCreateDataProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::CreateDataProductRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataProductRequest',
    as HashRef[CreateDataProductRequest()];

declare 'DeleteDataProductRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::DeleteDataProductRequest'];

coerce 'DeleteDataProductRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::DeleteDataProductRequest'->new($_) };

declare 'RepeatedDeleteDataProductRequest',
    as ArrayRef[DeleteDataProductRequest()];

coerce 'RepeatedDeleteDataProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::DeleteDataProductRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataProductRequest',
    as HashRef[DeleteDataProductRequest()];

declare 'GetDataProductRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::GetDataProductRequest'];

coerce 'GetDataProductRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::GetDataProductRequest'->new($_) };

declare 'RepeatedGetDataProductRequest',
    as ArrayRef[GetDataProductRequest()];

coerce 'RepeatedGetDataProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::GetDataProductRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataProductRequest',
    as HashRef[GetDataProductRequest()];

declare 'ListDataProductsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::ListDataProductsRequest'];

coerce 'ListDataProductsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::ListDataProductsRequest'->new($_) };

declare 'RepeatedListDataProductsRequest',
    as ArrayRef[ListDataProductsRequest()];

coerce 'RepeatedListDataProductsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::ListDataProductsRequest'->new($_) } @$_ ] };

declare 'MapStringListDataProductsRequest',
    as HashRef[ListDataProductsRequest()];

declare 'ListDataProductsResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::ListDataProductsResponse'];

coerce 'ListDataProductsResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::ListDataProductsResponse'->new($_) };

declare 'RepeatedListDataProductsResponse',
    as ArrayRef[ListDataProductsResponse()];

coerce 'RepeatedListDataProductsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::ListDataProductsResponse'->new($_) } @$_ ] };

declare 'MapStringListDataProductsResponse',
    as HashRef[ListDataProductsResponse()];

declare 'UpdateDataProductRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::UpdateDataProductRequest'];

coerce 'UpdateDataProductRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::UpdateDataProductRequest'->new($_) };

declare 'RepeatedUpdateDataProductRequest',
    as ArrayRef[UpdateDataProductRequest()];

coerce 'RepeatedUpdateDataProductRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::UpdateDataProductRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataProductRequest',
    as HashRef[UpdateDataProductRequest()];

declare 'RequestDataProductAccessRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::RequestDataProductAccessRequest'];

coerce 'RequestDataProductAccessRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::RequestDataProductAccessRequest'->new($_) };

declare 'RepeatedRequestDataProductAccessRequest',
    as ArrayRef[RequestDataProductAccessRequest()];

coerce 'RepeatedRequestDataProductAccessRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::RequestDataProductAccessRequest'->new($_) } @$_ ] };

declare 'MapStringRequestDataProductAccessRequest',
    as HashRef[RequestDataProductAccessRequest()];

declare 'RequestDataProductAccessResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::RequestDataProductAccessResponse'];

coerce 'RequestDataProductAccessResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::RequestDataProductAccessResponse'->new($_) };

declare 'RepeatedRequestDataProductAccessResponse',
    as ArrayRef[RequestDataProductAccessResponse()];

coerce 'RepeatedRequestDataProductAccessResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::RequestDataProductAccessResponse'->new($_) } @$_ ] };

declare 'MapStringRequestDataProductAccessResponse',
    as HashRef[RequestDataProductAccessResponse()];

declare 'CreateDataAssetRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::CreateDataAssetRequest'];

coerce 'CreateDataAssetRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::CreateDataAssetRequest'->new($_) };

declare 'RepeatedCreateDataAssetRequest',
    as ArrayRef[CreateDataAssetRequest()];

coerce 'RepeatedCreateDataAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::CreateDataAssetRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataAssetRequest',
    as HashRef[CreateDataAssetRequest()];

declare 'UpdateDataAssetRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::UpdateDataAssetRequest'];

coerce 'UpdateDataAssetRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::UpdateDataAssetRequest'->new($_) };

declare 'RepeatedUpdateDataAssetRequest',
    as ArrayRef[UpdateDataAssetRequest()];

coerce 'RepeatedUpdateDataAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::UpdateDataAssetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataAssetRequest',
    as HashRef[UpdateDataAssetRequest()];

declare 'DeleteDataAssetRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::DeleteDataAssetRequest'];

coerce 'DeleteDataAssetRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::DeleteDataAssetRequest'->new($_) };

declare 'RepeatedDeleteDataAssetRequest',
    as ArrayRef[DeleteDataAssetRequest()];

coerce 'RepeatedDeleteDataAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::DeleteDataAssetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataAssetRequest',
    as HashRef[DeleteDataAssetRequest()];

declare 'GetDataAssetRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::GetDataAssetRequest'];

coerce 'GetDataAssetRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::GetDataAssetRequest'->new($_) };

declare 'RepeatedGetDataAssetRequest',
    as ArrayRef[GetDataAssetRequest()];

coerce 'RepeatedGetDataAssetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::GetDataAssetRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataAssetRequest',
    as HashRef[GetDataAssetRequest()];

declare 'ListDataAssetsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::ListDataAssetsRequest'];

coerce 'ListDataAssetsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::ListDataAssetsRequest'->new($_) };

declare 'RepeatedListDataAssetsRequest',
    as ArrayRef[ListDataAssetsRequest()];

coerce 'RepeatedListDataAssetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::ListDataAssetsRequest'->new($_) } @$_ ] };

declare 'MapStringListDataAssetsRequest',
    as HashRef[ListDataAssetsRequest()];

declare 'ListDataAssetsResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::DataProducts::ListDataAssetsResponse'];

coerce 'ListDataAssetsResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::DataProducts::ListDataAssetsResponse'->new($_) };

declare 'RepeatedListDataAssetsResponse',
    as ArrayRef[ListDataAssetsResponse()];

coerce 'RepeatedListDataAssetsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::DataProducts::ListDataAssetsResponse'->new($_) } @$_ ] };

declare 'MapStringListDataAssetsResponse',
    as HashRef[ListDataAssetsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::DataProducts::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
