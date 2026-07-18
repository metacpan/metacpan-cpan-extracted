# Copyright (C) 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Cloud::Bigquery::V2::Dataset::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DatasetAccessEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::DatasetAccessEntry'];

coerce 'DatasetAccessEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::DatasetAccessEntry'->new($_) };

declare 'RepeatedDatasetAccessEntry',
    as ArrayRef[DatasetAccessEntry()];

coerce 'RepeatedDatasetAccessEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::DatasetAccessEntry'->new($_) } @$_ ] };

declare 'MapStringDatasetAccessEntry',
    as HashRef[DatasetAccessEntry()];

declare 'TargetType',
    as (Int | Str);

declare 'Access',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::Access'];

coerce 'Access',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::Access'->new($_) };

declare 'RepeatedAccess',
    as ArrayRef[Access()];

coerce 'RepeatedAccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::Access'->new($_) } @$_ ] };

declare 'MapStringAccess',
    as HashRef[Access()];

declare 'Dataset',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::Dataset'];

coerce 'Dataset',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::Dataset'->new($_) };

declare 'RepeatedDataset',
    as ArrayRef[Dataset()];

coerce 'RepeatedDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::Dataset'->new($_) } @$_ ] };

declare 'MapStringDataset',
    as HashRef[Dataset()];

declare 'StorageBillingModel',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::Dataset::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::Dataset::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::Dataset::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ResourceTagsEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::Dataset::ResourceTagsEntry'];

coerce 'ResourceTagsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::Dataset::ResourceTagsEntry'->new($_) };

declare 'RepeatedResourceTagsEntry',
    as ArrayRef[ResourceTagsEntry()];

coerce 'RepeatedResourceTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::Dataset::ResourceTagsEntry'->new($_) } @$_ ] };

declare 'MapStringResourceTagsEntry',
    as HashRef[ResourceTagsEntry()];

declare 'GcpTag',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::GcpTag'];

coerce 'GcpTag',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::GcpTag'->new($_) };

declare 'RepeatedGcpTag',
    as ArrayRef[GcpTag()];

coerce 'RepeatedGcpTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::GcpTag'->new($_) } @$_ ] };

declare 'MapStringGcpTag',
    as HashRef[GcpTag()];

declare 'LinkedDatasetSource',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::LinkedDatasetSource'];

coerce 'LinkedDatasetSource',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::LinkedDatasetSource'->new($_) };

declare 'RepeatedLinkedDatasetSource',
    as ArrayRef[LinkedDatasetSource()];

coerce 'RepeatedLinkedDatasetSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::LinkedDatasetSource'->new($_) } @$_ ] };

declare 'MapStringLinkedDatasetSource',
    as HashRef[LinkedDatasetSource()];

declare 'Replica',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::Replica'];

coerce 'Replica',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::Replica'->new($_) };

declare 'RepeatedReplica',
    as ArrayRef[Replica()];

coerce 'RepeatedReplica',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::Replica'->new($_) } @$_ ] };

declare 'MapStringReplica',
    as HashRef[Replica()];

declare 'ReplicaState',
    as (Int | Str);

declare 'ReplicaOptions',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::Replica::ReplicaOptions'];

coerce 'ReplicaOptions',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::Replica::ReplicaOptions'->new($_) };

declare 'RepeatedReplicaOptions',
    as ArrayRef[ReplicaOptions()];

coerce 'RepeatedReplicaOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::Replica::ReplicaOptions'->new($_) } @$_ ] };

declare 'MapStringReplicaOptions',
    as HashRef[ReplicaOptions()];

declare 'LinkedDatasetMetadata',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::LinkedDatasetMetadata'];

coerce 'LinkedDatasetMetadata',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::LinkedDatasetMetadata'->new($_) };

declare 'RepeatedLinkedDatasetMetadata',
    as ArrayRef[LinkedDatasetMetadata()];

coerce 'RepeatedLinkedDatasetMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::LinkedDatasetMetadata'->new($_) } @$_ ] };

declare 'MapStringLinkedDatasetMetadata',
    as HashRef[LinkedDatasetMetadata()];

declare 'LinkState',
    as (Int | Str);

declare 'GetDatasetRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::GetDatasetRequest'];

coerce 'GetDatasetRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::GetDatasetRequest'->new($_) };

declare 'RepeatedGetDatasetRequest',
    as ArrayRef[GetDatasetRequest()];

coerce 'RepeatedGetDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::GetDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatasetRequest',
    as HashRef[GetDatasetRequest()];

declare 'DatasetView',
    as (Int | Str);

declare 'InsertDatasetRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::InsertDatasetRequest'];

coerce 'InsertDatasetRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::InsertDatasetRequest'->new($_) };

declare 'RepeatedInsertDatasetRequest',
    as ArrayRef[InsertDatasetRequest()];

coerce 'RepeatedInsertDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::InsertDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringInsertDatasetRequest',
    as HashRef[InsertDatasetRequest()];

declare 'UpdateOrPatchDatasetRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::UpdateOrPatchDatasetRequest'];

coerce 'UpdateOrPatchDatasetRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::UpdateOrPatchDatasetRequest'->new($_) };

declare 'RepeatedUpdateOrPatchDatasetRequest',
    as ArrayRef[UpdateOrPatchDatasetRequest()];

coerce 'RepeatedUpdateOrPatchDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::UpdateOrPatchDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateOrPatchDatasetRequest',
    as HashRef[UpdateOrPatchDatasetRequest()];

declare 'UpdateMode',
    as (Int | Str);

declare 'DeleteDatasetRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::DeleteDatasetRequest'];

coerce 'DeleteDatasetRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::DeleteDatasetRequest'->new($_) };

declare 'RepeatedDeleteDatasetRequest',
    as ArrayRef[DeleteDatasetRequest()];

coerce 'RepeatedDeleteDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::DeleteDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDatasetRequest',
    as HashRef[DeleteDatasetRequest()];

declare 'ListDatasetsRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::ListDatasetsRequest'];

coerce 'ListDatasetsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::ListDatasetsRequest'->new($_) };

declare 'RepeatedListDatasetsRequest',
    as ArrayRef[ListDatasetsRequest()];

coerce 'RepeatedListDatasetsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::ListDatasetsRequest'->new($_) } @$_ ] };

declare 'MapStringListDatasetsRequest',
    as HashRef[ListDatasetsRequest()];

declare 'ListFormatDataset',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::ListFormatDataset'];

coerce 'ListFormatDataset',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::ListFormatDataset'->new($_) };

declare 'RepeatedListFormatDataset',
    as ArrayRef[ListFormatDataset()];

coerce 'RepeatedListFormatDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::ListFormatDataset'->new($_) } @$_ ] };

declare 'MapStringListFormatDataset',
    as HashRef[ListFormatDataset()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::ListFormatDataset::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::ListFormatDataset::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::ListFormatDataset::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DatasetList',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::DatasetList'];

coerce 'DatasetList',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::DatasetList'->new($_) };

declare 'RepeatedDatasetList',
    as ArrayRef[DatasetList()];

coerce 'RepeatedDatasetList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::DatasetList'->new($_) } @$_ ] };

declare 'MapStringDatasetList',
    as HashRef[DatasetList()];

declare 'UndeleteDatasetRequest',
    as InstanceOf['Google::Cloud::Bigquery::V2::Dataset::UndeleteDatasetRequest'];

coerce 'UndeleteDatasetRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::Dataset::UndeleteDatasetRequest'->new($_) };

declare 'RepeatedUndeleteDatasetRequest',
    as ArrayRef[UndeleteDatasetRequest()];

coerce 'RepeatedUndeleteDatasetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::Dataset::UndeleteDatasetRequest'->new($_) } @$_ ] };

declare 'MapStringUndeleteDatasetRequest',
    as HashRef[UndeleteDatasetRequest()];

1;
