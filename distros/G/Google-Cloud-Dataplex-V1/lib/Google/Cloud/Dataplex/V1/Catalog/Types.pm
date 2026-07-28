package Google::Cloud::Dataplex::V1::Catalog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EntryView',
    as (Int | Str);

declare 'TransferStatus',
    as (Int | Str);

declare 'AspectType',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::AspectType'];

coerce 'AspectType',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::AspectType'->new($_) };

declare 'RepeatedAspectType',
    as ArrayRef[AspectType()];

coerce 'RepeatedAspectType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::AspectType'->new($_) } @$_ ] };

declare 'MapStringAspectType',
    as HashRef[AspectType()];

declare 'DataClassification',
    as (Int | Str);

declare 'Authorization',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::AspectType::Authorization'];

coerce 'Authorization',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::AspectType::Authorization'->new($_) };

declare 'RepeatedAuthorization',
    as ArrayRef[Authorization()];

coerce 'RepeatedAuthorization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::AspectType::Authorization'->new($_) } @$_ ] };

declare 'MapStringAuthorization',
    as HashRef[Authorization()];

declare 'MetadataTemplate',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::AspectType::MetadataTemplate'];

coerce 'MetadataTemplate',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::AspectType::MetadataTemplate'->new($_) };

declare 'RepeatedMetadataTemplate',
    as ArrayRef[MetadataTemplate()];

coerce 'RepeatedMetadataTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::AspectType::MetadataTemplate'->new($_) } @$_ ] };

declare 'MapStringMetadataTemplate',
    as HashRef[MetadataTemplate()];

declare 'EnumValue',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::AspectType::MetadataTemplate::EnumValue'];

coerce 'EnumValue',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::AspectType::MetadataTemplate::EnumValue'->new($_) };

declare 'RepeatedEnumValue',
    as ArrayRef[EnumValue()];

coerce 'RepeatedEnumValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::AspectType::MetadataTemplate::EnumValue'->new($_) } @$_ ] };

declare 'MapStringEnumValue',
    as HashRef[EnumValue()];

declare 'Constraints',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::AspectType::MetadataTemplate::Constraints'];

coerce 'Constraints',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::AspectType::MetadataTemplate::Constraints'->new($_) };

declare 'RepeatedConstraints',
    as ArrayRef[Constraints()];

coerce 'RepeatedConstraints',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::AspectType::MetadataTemplate::Constraints'->new($_) } @$_ ] };

declare 'MapStringConstraints',
    as HashRef[Constraints()];

declare 'Annotations',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::AspectType::MetadataTemplate::Annotations'];

coerce 'Annotations',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::AspectType::MetadataTemplate::Annotations'->new($_) };

declare 'RepeatedAnnotations',
    as ArrayRef[Annotations()];

coerce 'RepeatedAnnotations',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::AspectType::MetadataTemplate::Annotations'->new($_) } @$_ ] };

declare 'MapStringAnnotations',
    as HashRef[Annotations()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::AspectType::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::AspectType::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::AspectType::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'EntryGroup',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::EntryGroup'];

coerce 'EntryGroup',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::EntryGroup'->new($_) };

declare 'RepeatedEntryGroup',
    as ArrayRef[EntryGroup()];

coerce 'RepeatedEntryGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::EntryGroup'->new($_) } @$_ ] };

declare 'MapStringEntryGroup',
    as HashRef[EntryGroup()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::EntryGroup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::EntryGroup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::EntryGroup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'EntryType',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::EntryType'];

coerce 'EntryType',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::EntryType'->new($_) };

declare 'RepeatedEntryType',
    as ArrayRef[EntryType()];

coerce 'RepeatedEntryType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::EntryType'->new($_) } @$_ ] };

declare 'MapStringEntryType',
    as HashRef[EntryType()];

declare 'AspectInfo',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::EntryType::AspectInfo'];

coerce 'AspectInfo',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::EntryType::AspectInfo'->new($_) };

declare 'RepeatedAspectInfo',
    as ArrayRef[AspectInfo()];

coerce 'RepeatedAspectInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::EntryType::AspectInfo'->new($_) } @$_ ] };

declare 'MapStringAspectInfo',
    as HashRef[AspectInfo()];

declare 'Authorization',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::EntryType::Authorization'];

coerce 'Authorization',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::EntryType::Authorization'->new($_) };

declare 'RepeatedAuthorization',
    as ArrayRef[Authorization()];

coerce 'RepeatedAuthorization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::EntryType::Authorization'->new($_) } @$_ ] };

declare 'MapStringAuthorization',
    as HashRef[Authorization()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::EntryType::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::EntryType::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::EntryType::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Aspect',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::Aspect'];

coerce 'Aspect',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::Aspect'->new($_) };

declare 'RepeatedAspect',
    as ArrayRef[Aspect()];

coerce 'RepeatedAspect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::Aspect'->new($_) } @$_ ] };

declare 'MapStringAspect',
    as HashRef[Aspect()];

declare 'AspectSource',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::AspectSource'];

coerce 'AspectSource',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::AspectSource'->new($_) };

declare 'RepeatedAspectSource',
    as ArrayRef[AspectSource()];

coerce 'RepeatedAspectSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::AspectSource'->new($_) } @$_ ] };

declare 'MapStringAspectSource',
    as HashRef[AspectSource()];

declare 'Entry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::Entry'];

coerce 'Entry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::Entry'->new($_) };

declare 'RepeatedEntry',
    as ArrayRef[Entry()];

coerce 'RepeatedEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::Entry'->new($_) } @$_ ] };

declare 'MapStringEntry',
    as HashRef[Entry()];

declare 'AspectsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::Entry::AspectsEntry'];

coerce 'AspectsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::Entry::AspectsEntry'->new($_) };

declare 'RepeatedAspectsEntry',
    as ArrayRef[AspectsEntry()];

coerce 'RepeatedAspectsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::Entry::AspectsEntry'->new($_) } @$_ ] };

declare 'MapStringAspectsEntry',
    as HashRef[AspectsEntry()];

declare 'EntrySource',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::EntrySource'];

coerce 'EntrySource',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::EntrySource'->new($_) };

declare 'RepeatedEntrySource',
    as ArrayRef[EntrySource()];

coerce 'RepeatedEntrySource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::EntrySource'->new($_) } @$_ ] };

declare 'MapStringEntrySource',
    as HashRef[EntrySource()];

declare 'Ancestor',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::EntrySource::Ancestor'];

coerce 'Ancestor',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::EntrySource::Ancestor'->new($_) };

declare 'RepeatedAncestor',
    as ArrayRef[Ancestor()];

coerce 'RepeatedAncestor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::EntrySource::Ancestor'->new($_) } @$_ ] };

declare 'MapStringAncestor',
    as HashRef[Ancestor()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::EntrySource::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::EntrySource::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::EntrySource::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateEntryGroupRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::CreateEntryGroupRequest'];

coerce 'CreateEntryGroupRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::CreateEntryGroupRequest'->new($_) };

declare 'RepeatedCreateEntryGroupRequest',
    as ArrayRef[CreateEntryGroupRequest()];

coerce 'RepeatedCreateEntryGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::CreateEntryGroupRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEntryGroupRequest',
    as HashRef[CreateEntryGroupRequest()];

declare 'UpdateEntryGroupRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::UpdateEntryGroupRequest'];

coerce 'UpdateEntryGroupRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::UpdateEntryGroupRequest'->new($_) };

declare 'RepeatedUpdateEntryGroupRequest',
    as ArrayRef[UpdateEntryGroupRequest()];

coerce 'RepeatedUpdateEntryGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::UpdateEntryGroupRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEntryGroupRequest',
    as HashRef[UpdateEntryGroupRequest()];

declare 'DeleteEntryGroupRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::DeleteEntryGroupRequest'];

coerce 'DeleteEntryGroupRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::DeleteEntryGroupRequest'->new($_) };

declare 'RepeatedDeleteEntryGroupRequest',
    as ArrayRef[DeleteEntryGroupRequest()];

coerce 'RepeatedDeleteEntryGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::DeleteEntryGroupRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEntryGroupRequest',
    as HashRef[DeleteEntryGroupRequest()];

declare 'ListEntryGroupsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ListEntryGroupsRequest'];

coerce 'ListEntryGroupsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ListEntryGroupsRequest'->new($_) };

declare 'RepeatedListEntryGroupsRequest',
    as ArrayRef[ListEntryGroupsRequest()];

coerce 'RepeatedListEntryGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ListEntryGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListEntryGroupsRequest',
    as HashRef[ListEntryGroupsRequest()];

declare 'ListEntryGroupsResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ListEntryGroupsResponse'];

coerce 'ListEntryGroupsResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ListEntryGroupsResponse'->new($_) };

declare 'RepeatedListEntryGroupsResponse',
    as ArrayRef[ListEntryGroupsResponse()];

coerce 'RepeatedListEntryGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ListEntryGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListEntryGroupsResponse',
    as HashRef[ListEntryGroupsResponse()];

declare 'GetEntryGroupRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::GetEntryGroupRequest'];

coerce 'GetEntryGroupRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::GetEntryGroupRequest'->new($_) };

declare 'RepeatedGetEntryGroupRequest',
    as ArrayRef[GetEntryGroupRequest()];

coerce 'RepeatedGetEntryGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::GetEntryGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetEntryGroupRequest',
    as HashRef[GetEntryGroupRequest()];

declare 'CreateEntryTypeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::CreateEntryTypeRequest'];

coerce 'CreateEntryTypeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::CreateEntryTypeRequest'->new($_) };

declare 'RepeatedCreateEntryTypeRequest',
    as ArrayRef[CreateEntryTypeRequest()];

coerce 'RepeatedCreateEntryTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::CreateEntryTypeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEntryTypeRequest',
    as HashRef[CreateEntryTypeRequest()];

declare 'UpdateEntryTypeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::UpdateEntryTypeRequest'];

coerce 'UpdateEntryTypeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::UpdateEntryTypeRequest'->new($_) };

declare 'RepeatedUpdateEntryTypeRequest',
    as ArrayRef[UpdateEntryTypeRequest()];

coerce 'RepeatedUpdateEntryTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::UpdateEntryTypeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEntryTypeRequest',
    as HashRef[UpdateEntryTypeRequest()];

declare 'DeleteEntryTypeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::DeleteEntryTypeRequest'];

coerce 'DeleteEntryTypeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::DeleteEntryTypeRequest'->new($_) };

declare 'RepeatedDeleteEntryTypeRequest',
    as ArrayRef[DeleteEntryTypeRequest()];

coerce 'RepeatedDeleteEntryTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::DeleteEntryTypeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEntryTypeRequest',
    as HashRef[DeleteEntryTypeRequest()];

declare 'ListEntryTypesRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ListEntryTypesRequest'];

coerce 'ListEntryTypesRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ListEntryTypesRequest'->new($_) };

declare 'RepeatedListEntryTypesRequest',
    as ArrayRef[ListEntryTypesRequest()];

coerce 'RepeatedListEntryTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ListEntryTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListEntryTypesRequest',
    as HashRef[ListEntryTypesRequest()];

declare 'ListEntryTypesResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ListEntryTypesResponse'];

coerce 'ListEntryTypesResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ListEntryTypesResponse'->new($_) };

declare 'RepeatedListEntryTypesResponse',
    as ArrayRef[ListEntryTypesResponse()];

coerce 'RepeatedListEntryTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ListEntryTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListEntryTypesResponse',
    as HashRef[ListEntryTypesResponse()];

declare 'GetEntryTypeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::GetEntryTypeRequest'];

coerce 'GetEntryTypeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::GetEntryTypeRequest'->new($_) };

declare 'RepeatedGetEntryTypeRequest',
    as ArrayRef[GetEntryTypeRequest()];

coerce 'RepeatedGetEntryTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::GetEntryTypeRequest'->new($_) } @$_ ] };

declare 'MapStringGetEntryTypeRequest',
    as HashRef[GetEntryTypeRequest()];

declare 'CreateAspectTypeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::CreateAspectTypeRequest'];

coerce 'CreateAspectTypeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::CreateAspectTypeRequest'->new($_) };

declare 'RepeatedCreateAspectTypeRequest',
    as ArrayRef[CreateAspectTypeRequest()];

coerce 'RepeatedCreateAspectTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::CreateAspectTypeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAspectTypeRequest',
    as HashRef[CreateAspectTypeRequest()];

declare 'UpdateAspectTypeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::UpdateAspectTypeRequest'];

coerce 'UpdateAspectTypeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::UpdateAspectTypeRequest'->new($_) };

declare 'RepeatedUpdateAspectTypeRequest',
    as ArrayRef[UpdateAspectTypeRequest()];

coerce 'RepeatedUpdateAspectTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::UpdateAspectTypeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAspectTypeRequest',
    as HashRef[UpdateAspectTypeRequest()];

declare 'DeleteAspectTypeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::DeleteAspectTypeRequest'];

coerce 'DeleteAspectTypeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::DeleteAspectTypeRequest'->new($_) };

declare 'RepeatedDeleteAspectTypeRequest',
    as ArrayRef[DeleteAspectTypeRequest()];

coerce 'RepeatedDeleteAspectTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::DeleteAspectTypeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAspectTypeRequest',
    as HashRef[DeleteAspectTypeRequest()];

declare 'ListAspectTypesRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ListAspectTypesRequest'];

coerce 'ListAspectTypesRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ListAspectTypesRequest'->new($_) };

declare 'RepeatedListAspectTypesRequest',
    as ArrayRef[ListAspectTypesRequest()];

coerce 'RepeatedListAspectTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ListAspectTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListAspectTypesRequest',
    as HashRef[ListAspectTypesRequest()];

declare 'ListAspectTypesResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ListAspectTypesResponse'];

coerce 'ListAspectTypesResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ListAspectTypesResponse'->new($_) };

declare 'RepeatedListAspectTypesResponse',
    as ArrayRef[ListAspectTypesResponse()];

coerce 'RepeatedListAspectTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ListAspectTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListAspectTypesResponse',
    as HashRef[ListAspectTypesResponse()];

declare 'GetAspectTypeRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::GetAspectTypeRequest'];

coerce 'GetAspectTypeRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::GetAspectTypeRequest'->new($_) };

declare 'RepeatedGetAspectTypeRequest',
    as ArrayRef[GetAspectTypeRequest()];

coerce 'RepeatedGetAspectTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::GetAspectTypeRequest'->new($_) } @$_ ] };

declare 'MapStringGetAspectTypeRequest',
    as HashRef[GetAspectTypeRequest()];

declare 'CreateEntryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::CreateEntryRequest'];

coerce 'CreateEntryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::CreateEntryRequest'->new($_) };

declare 'RepeatedCreateEntryRequest',
    as ArrayRef[CreateEntryRequest()];

coerce 'RepeatedCreateEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::CreateEntryRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEntryRequest',
    as HashRef[CreateEntryRequest()];

declare 'UpdateEntryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::UpdateEntryRequest'];

coerce 'UpdateEntryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::UpdateEntryRequest'->new($_) };

declare 'RepeatedUpdateEntryRequest',
    as ArrayRef[UpdateEntryRequest()];

coerce 'RepeatedUpdateEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::UpdateEntryRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEntryRequest',
    as HashRef[UpdateEntryRequest()];

declare 'DeleteEntryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::DeleteEntryRequest'];

coerce 'DeleteEntryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::DeleteEntryRequest'->new($_) };

declare 'RepeatedDeleteEntryRequest',
    as ArrayRef[DeleteEntryRequest()];

coerce 'RepeatedDeleteEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::DeleteEntryRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEntryRequest',
    as HashRef[DeleteEntryRequest()];

declare 'ListEntriesRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ListEntriesRequest'];

coerce 'ListEntriesRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ListEntriesRequest'->new($_) };

declare 'RepeatedListEntriesRequest',
    as ArrayRef[ListEntriesRequest()];

coerce 'RepeatedListEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ListEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringListEntriesRequest',
    as HashRef[ListEntriesRequest()];

declare 'ListEntriesResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ListEntriesResponse'];

coerce 'ListEntriesResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ListEntriesResponse'->new($_) };

declare 'RepeatedListEntriesResponse',
    as ArrayRef[ListEntriesResponse()];

coerce 'RepeatedListEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ListEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringListEntriesResponse',
    as HashRef[ListEntriesResponse()];

declare 'GetEntryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::GetEntryRequest'];

coerce 'GetEntryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::GetEntryRequest'->new($_) };

declare 'RepeatedGetEntryRequest',
    as ArrayRef[GetEntryRequest()];

coerce 'RepeatedGetEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::GetEntryRequest'->new($_) } @$_ ] };

declare 'MapStringGetEntryRequest',
    as HashRef[GetEntryRequest()];

declare 'LookupEntryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::LookupEntryRequest'];

coerce 'LookupEntryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::LookupEntryRequest'->new($_) };

declare 'RepeatedLookupEntryRequest',
    as ArrayRef[LookupEntryRequest()];

coerce 'RepeatedLookupEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::LookupEntryRequest'->new($_) } @$_ ] };

declare 'MapStringLookupEntryRequest',
    as HashRef[LookupEntryRequest()];

declare 'LookupContextRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::LookupContextRequest'];

coerce 'LookupContextRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::LookupContextRequest'->new($_) };

declare 'RepeatedLookupContextRequest',
    as ArrayRef[LookupContextRequest()];

coerce 'RepeatedLookupContextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::LookupContextRequest'->new($_) } @$_ ] };

declare 'MapStringLookupContextRequest',
    as HashRef[LookupContextRequest()];

declare 'OptionsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::LookupContextRequest::OptionsEntry'];

coerce 'OptionsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::LookupContextRequest::OptionsEntry'->new($_) };

declare 'RepeatedOptionsEntry',
    as ArrayRef[OptionsEntry()];

coerce 'RepeatedOptionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::LookupContextRequest::OptionsEntry'->new($_) } @$_ ] };

declare 'MapStringOptionsEntry',
    as HashRef[OptionsEntry()];

declare 'ModifyEntryRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ModifyEntryRequest'];

coerce 'ModifyEntryRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ModifyEntryRequest'->new($_) };

declare 'RepeatedModifyEntryRequest',
    as ArrayRef[ModifyEntryRequest()];

coerce 'RepeatedModifyEntryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ModifyEntryRequest'->new($_) } @$_ ] };

declare 'MapStringModifyEntryRequest',
    as HashRef[ModifyEntryRequest()];

declare 'LookupContextResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::LookupContextResponse'];

coerce 'LookupContextResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::LookupContextResponse'->new($_) };

declare 'RepeatedLookupContextResponse',
    as ArrayRef[LookupContextResponse()];

coerce 'RepeatedLookupContextResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::LookupContextResponse'->new($_) } @$_ ] };

declare 'MapStringLookupContextResponse',
    as HashRef[LookupContextResponse()];

declare 'SearchEntriesRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::SearchEntriesRequest'];

coerce 'SearchEntriesRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::SearchEntriesRequest'->new($_) };

declare 'RepeatedSearchEntriesRequest',
    as ArrayRef[SearchEntriesRequest()];

coerce 'RepeatedSearchEntriesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::SearchEntriesRequest'->new($_) } @$_ ] };

declare 'MapStringSearchEntriesRequest',
    as HashRef[SearchEntriesRequest()];

declare 'SearchEntriesResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::SearchEntriesResult'];

coerce 'SearchEntriesResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::SearchEntriesResult'->new($_) };

declare 'RepeatedSearchEntriesResult',
    as ArrayRef[SearchEntriesResult()];

coerce 'RepeatedSearchEntriesResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::SearchEntriesResult'->new($_) } @$_ ] };

declare 'MapStringSearchEntriesResult',
    as HashRef[SearchEntriesResult()];

declare 'Snippets',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::SearchEntriesResult::Snippets'];

coerce 'Snippets',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::SearchEntriesResult::Snippets'->new($_) };

declare 'RepeatedSnippets',
    as ArrayRef[Snippets()];

coerce 'RepeatedSnippets',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::SearchEntriesResult::Snippets'->new($_) } @$_ ] };

declare 'MapStringSnippets',
    as HashRef[Snippets()];

declare 'SearchEntriesResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::SearchEntriesResponse'];

coerce 'SearchEntriesResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::SearchEntriesResponse'->new($_) };

declare 'RepeatedSearchEntriesResponse',
    as ArrayRef[SearchEntriesResponse()];

coerce 'RepeatedSearchEntriesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::SearchEntriesResponse'->new($_) } @$_ ] };

declare 'MapStringSearchEntriesResponse',
    as HashRef[SearchEntriesResponse()];

declare 'ImportItem',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ImportItem'];

coerce 'ImportItem',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ImportItem'->new($_) };

declare 'RepeatedImportItem',
    as ArrayRef[ImportItem()];

coerce 'RepeatedImportItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ImportItem'->new($_) } @$_ ] };

declare 'MapStringImportItem',
    as HashRef[ImportItem()];

declare 'CreateMetadataJobRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::CreateMetadataJobRequest'];

coerce 'CreateMetadataJobRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::CreateMetadataJobRequest'->new($_) };

declare 'RepeatedCreateMetadataJobRequest',
    as ArrayRef[CreateMetadataJobRequest()];

coerce 'RepeatedCreateMetadataJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::CreateMetadataJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMetadataJobRequest',
    as HashRef[CreateMetadataJobRequest()];

declare 'GetMetadataJobRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::GetMetadataJobRequest'];

coerce 'GetMetadataJobRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::GetMetadataJobRequest'->new($_) };

declare 'RepeatedGetMetadataJobRequest',
    as ArrayRef[GetMetadataJobRequest()];

coerce 'RepeatedGetMetadataJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::GetMetadataJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetMetadataJobRequest',
    as HashRef[GetMetadataJobRequest()];

declare 'ListMetadataJobsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ListMetadataJobsRequest'];

coerce 'ListMetadataJobsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ListMetadataJobsRequest'->new($_) };

declare 'RepeatedListMetadataJobsRequest',
    as ArrayRef[ListMetadataJobsRequest()];

coerce 'RepeatedListMetadataJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ListMetadataJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListMetadataJobsRequest',
    as HashRef[ListMetadataJobsRequest()];

declare 'ListMetadataJobsResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ListMetadataJobsResponse'];

coerce 'ListMetadataJobsResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ListMetadataJobsResponse'->new($_) };

declare 'RepeatedListMetadataJobsResponse',
    as ArrayRef[ListMetadataJobsResponse()];

coerce 'RepeatedListMetadataJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ListMetadataJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListMetadataJobsResponse',
    as HashRef[ListMetadataJobsResponse()];

declare 'CancelMetadataJobRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::CancelMetadataJobRequest'];

coerce 'CancelMetadataJobRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::CancelMetadataJobRequest'->new($_) };

declare 'RepeatedCancelMetadataJobRequest',
    as ArrayRef[CancelMetadataJobRequest()];

coerce 'RepeatedCancelMetadataJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::CancelMetadataJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelMetadataJobRequest',
    as HashRef[CancelMetadataJobRequest()];

declare 'MetadataJob',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::MetadataJob'];

coerce 'MetadataJob',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob'->new($_) };

declare 'RepeatedMetadataJob',
    as ArrayRef[MetadataJob()];

coerce 'RepeatedMetadataJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob'->new($_) } @$_ ] };

declare 'MapStringMetadataJob',
    as HashRef[MetadataJob()];

declare 'Type',
    as (Int | Str);

declare 'ImportJobResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ImportJobResult'];

coerce 'ImportJobResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ImportJobResult'->new($_) };

declare 'RepeatedImportJobResult',
    as ArrayRef[ImportJobResult()];

coerce 'RepeatedImportJobResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ImportJobResult'->new($_) } @$_ ] };

declare 'MapStringImportJobResult',
    as HashRef[ImportJobResult()];

declare 'ExportJobResult',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ExportJobResult'];

coerce 'ExportJobResult',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ExportJobResult'->new($_) };

declare 'RepeatedExportJobResult',
    as ArrayRef[ExportJobResult()];

coerce 'RepeatedExportJobResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ExportJobResult'->new($_) } @$_ ] };

declare 'MapStringExportJobResult',
    as HashRef[ExportJobResult()];

declare 'ImportJobSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ImportJobSpec'];

coerce 'ImportJobSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ImportJobSpec'->new($_) };

declare 'RepeatedImportJobSpec',
    as ArrayRef[ImportJobSpec()];

coerce 'RepeatedImportJobSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ImportJobSpec'->new($_) } @$_ ] };

declare 'MapStringImportJobSpec',
    as HashRef[ImportJobSpec()];

declare 'SyncMode',
    as (Int | Str);

declare 'LogLevel',
    as (Int | Str);

declare 'ImportJobScope',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ImportJobSpec::ImportJobScope'];

coerce 'ImportJobScope',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ImportJobSpec::ImportJobScope'->new($_) };

declare 'RepeatedImportJobScope',
    as ArrayRef[ImportJobScope()];

coerce 'RepeatedImportJobScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ImportJobSpec::ImportJobScope'->new($_) } @$_ ] };

declare 'MapStringImportJobScope',
    as HashRef[ImportJobScope()];

declare 'ExportJobSpec',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ExportJobSpec'];

coerce 'ExportJobSpec',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ExportJobSpec'->new($_) };

declare 'RepeatedExportJobSpec',
    as ArrayRef[ExportJobSpec()];

coerce 'RepeatedExportJobSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ExportJobSpec'->new($_) } @$_ ] };

declare 'MapStringExportJobSpec',
    as HashRef[ExportJobSpec()];

declare 'ExportJobScope',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ExportJobSpec::ExportJobScope'];

coerce 'ExportJobScope',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ExportJobSpec::ExportJobScope'->new($_) };

declare 'RepeatedExportJobScope',
    as ArrayRef[ExportJobScope()];

coerce 'RepeatedExportJobScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::ExportJobSpec::ExportJobScope'->new($_) } @$_ ] };

declare 'MapStringExportJobScope',
    as HashRef[ExportJobScope()];

declare 'Status',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::MetadataJob::Status'];

coerce 'Status',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::Status'->new($_) };

declare 'RepeatedStatus',
    as ArrayRef[Status()];

coerce 'RepeatedStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::Status'->new($_) } @$_ ] };

declare 'MapStringStatus',
    as HashRef[Status()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::MetadataJob::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::MetadataJob::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'EntryLink',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::EntryLink'];

coerce 'EntryLink',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::EntryLink'->new($_) };

declare 'RepeatedEntryLink',
    as ArrayRef[EntryLink()];

coerce 'RepeatedEntryLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::EntryLink'->new($_) } @$_ ] };

declare 'MapStringEntryLink',
    as HashRef[EntryLink()];

declare 'EntryReference',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::EntryLink::EntryReference'];

coerce 'EntryReference',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::EntryLink::EntryReference'->new($_) };

declare 'RepeatedEntryReference',
    as ArrayRef[EntryReference()];

coerce 'RepeatedEntryReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::EntryLink::EntryReference'->new($_) } @$_ ] };

declare 'MapStringEntryReference',
    as HashRef[EntryReference()];

declare 'Type',
    as (Int | Str);

declare 'AspectsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::EntryLink::AspectsEntry'];

coerce 'AspectsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::EntryLink::AspectsEntry'->new($_) };

declare 'RepeatedAspectsEntry',
    as ArrayRef[AspectsEntry()];

coerce 'RepeatedAspectsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::EntryLink::AspectsEntry'->new($_) } @$_ ] };

declare 'MapStringAspectsEntry',
    as HashRef[AspectsEntry()];

declare 'CreateEntryLinkRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::CreateEntryLinkRequest'];

coerce 'CreateEntryLinkRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::CreateEntryLinkRequest'->new($_) };

declare 'RepeatedCreateEntryLinkRequest',
    as ArrayRef[CreateEntryLinkRequest()];

coerce 'RepeatedCreateEntryLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::CreateEntryLinkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEntryLinkRequest',
    as HashRef[CreateEntryLinkRequest()];

declare 'UpdateEntryLinkRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::UpdateEntryLinkRequest'];

coerce 'UpdateEntryLinkRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::UpdateEntryLinkRequest'->new($_) };

declare 'RepeatedUpdateEntryLinkRequest',
    as ArrayRef[UpdateEntryLinkRequest()];

coerce 'RepeatedUpdateEntryLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::UpdateEntryLinkRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEntryLinkRequest',
    as HashRef[UpdateEntryLinkRequest()];

declare 'DeleteEntryLinkRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::DeleteEntryLinkRequest'];

coerce 'DeleteEntryLinkRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::DeleteEntryLinkRequest'->new($_) };

declare 'RepeatedDeleteEntryLinkRequest',
    as ArrayRef[DeleteEntryLinkRequest()];

coerce 'RepeatedDeleteEntryLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::DeleteEntryLinkRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEntryLinkRequest',
    as HashRef[DeleteEntryLinkRequest()];

declare 'LookupEntryLinksRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::LookupEntryLinksRequest'];

coerce 'LookupEntryLinksRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::LookupEntryLinksRequest'->new($_) };

declare 'RepeatedLookupEntryLinksRequest',
    as ArrayRef[LookupEntryLinksRequest()];

coerce 'RepeatedLookupEntryLinksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::LookupEntryLinksRequest'->new($_) } @$_ ] };

declare 'MapStringLookupEntryLinksRequest',
    as HashRef[LookupEntryLinksRequest()];

declare 'EntryMode',
    as (Int | Str);

declare 'LookupEntryLinksResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::LookupEntryLinksResponse'];

coerce 'LookupEntryLinksResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::LookupEntryLinksResponse'->new($_) };

declare 'RepeatedLookupEntryLinksResponse',
    as ArrayRef[LookupEntryLinksResponse()];

coerce 'RepeatedLookupEntryLinksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::LookupEntryLinksResponse'->new($_) } @$_ ] };

declare 'MapStringLookupEntryLinksResponse',
    as HashRef[LookupEntryLinksResponse()];

declare 'GetEntryLinkRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::GetEntryLinkRequest'];

coerce 'GetEntryLinkRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::GetEntryLinkRequest'->new($_) };

declare 'RepeatedGetEntryLinkRequest',
    as ArrayRef[GetEntryLinkRequest()];

coerce 'RepeatedGetEntryLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::GetEntryLinkRequest'->new($_) } @$_ ] };

declare 'MapStringGetEntryLinkRequest',
    as HashRef[GetEntryLinkRequest()];

declare 'MetadataFeed',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::MetadataFeed'];

coerce 'MetadataFeed',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::MetadataFeed'->new($_) };

declare 'RepeatedMetadataFeed',
    as ArrayRef[MetadataFeed()];

coerce 'RepeatedMetadataFeed',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::MetadataFeed'->new($_) } @$_ ] };

declare 'MapStringMetadataFeed',
    as HashRef[MetadataFeed()];

declare 'Scope',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::MetadataFeed::Scope'];

coerce 'Scope',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::MetadataFeed::Scope'->new($_) };

declare 'RepeatedScope',
    as ArrayRef[Scope()];

coerce 'RepeatedScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::MetadataFeed::Scope'->new($_) } @$_ ] };

declare 'MapStringScope',
    as HashRef[Scope()];

declare 'Filters',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::MetadataFeed::Filters'];

coerce 'Filters',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::MetadataFeed::Filters'->new($_) };

declare 'RepeatedFilters',
    as ArrayRef[Filters()];

coerce 'RepeatedFilters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::MetadataFeed::Filters'->new($_) } @$_ ] };

declare 'MapStringFilters',
    as HashRef[Filters()];

declare 'ChangeType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::MetadataFeed::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::MetadataFeed::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::MetadataFeed::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateMetadataFeedRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::CreateMetadataFeedRequest'];

coerce 'CreateMetadataFeedRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::CreateMetadataFeedRequest'->new($_) };

declare 'RepeatedCreateMetadataFeedRequest',
    as ArrayRef[CreateMetadataFeedRequest()];

coerce 'RepeatedCreateMetadataFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::CreateMetadataFeedRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMetadataFeedRequest',
    as HashRef[CreateMetadataFeedRequest()];

declare 'GetMetadataFeedRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::GetMetadataFeedRequest'];

coerce 'GetMetadataFeedRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::GetMetadataFeedRequest'->new($_) };

declare 'RepeatedGetMetadataFeedRequest',
    as ArrayRef[GetMetadataFeedRequest()];

coerce 'RepeatedGetMetadataFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::GetMetadataFeedRequest'->new($_) } @$_ ] };

declare 'MapStringGetMetadataFeedRequest',
    as HashRef[GetMetadataFeedRequest()];

declare 'ListMetadataFeedsRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ListMetadataFeedsRequest'];

coerce 'ListMetadataFeedsRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ListMetadataFeedsRequest'->new($_) };

declare 'RepeatedListMetadataFeedsRequest',
    as ArrayRef[ListMetadataFeedsRequest()];

coerce 'RepeatedListMetadataFeedsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ListMetadataFeedsRequest'->new($_) } @$_ ] };

declare 'MapStringListMetadataFeedsRequest',
    as HashRef[ListMetadataFeedsRequest()];

declare 'ListMetadataFeedsResponse',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::ListMetadataFeedsResponse'];

coerce 'ListMetadataFeedsResponse',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::ListMetadataFeedsResponse'->new($_) };

declare 'RepeatedListMetadataFeedsResponse',
    as ArrayRef[ListMetadataFeedsResponse()];

coerce 'RepeatedListMetadataFeedsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::ListMetadataFeedsResponse'->new($_) } @$_ ] };

declare 'MapStringListMetadataFeedsResponse',
    as HashRef[ListMetadataFeedsResponse()];

declare 'DeleteMetadataFeedRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::DeleteMetadataFeedRequest'];

coerce 'DeleteMetadataFeedRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::DeleteMetadataFeedRequest'->new($_) };

declare 'RepeatedDeleteMetadataFeedRequest',
    as ArrayRef[DeleteMetadataFeedRequest()];

coerce 'RepeatedDeleteMetadataFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::DeleteMetadataFeedRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMetadataFeedRequest',
    as HashRef[DeleteMetadataFeedRequest()];

declare 'UpdateMetadataFeedRequest',
    as InstanceOf['Google::Cloud::Dataplex::V1::Catalog::UpdateMetadataFeedRequest'];

coerce 'UpdateMetadataFeedRequest',
    from HashRef, via { 'Google::Cloud::Dataplex::V1::Catalog::UpdateMetadataFeedRequest'->new($_) };

declare 'RepeatedUpdateMetadataFeedRequest',
    as ArrayRef[UpdateMetadataFeedRequest()];

coerce 'RepeatedUpdateMetadataFeedRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataplex::V1::Catalog::UpdateMetadataFeedRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMetadataFeedRequest',
    as HashRef[UpdateMetadataFeedRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dataplex::V1::Catalog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
