package Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Location',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Location'];

coerce 'Location',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Location'->new($_) };

declare 'RepeatedLocation',
    as ArrayRef[Location()];

coerce 'RepeatedLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Location'->new($_) } @$_ ] };

declare 'MapStringLocation',
    as HashRef[Location()];

declare 'LocationDistance',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance'];

coerce 'LocationDistance',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance'->new($_) };

declare 'RepeatedLocationDistance',
    as ArrayRef[LocationDistance()];

coerce 'RepeatedLocationDistance',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance'->new($_) } @$_ ] };

declare 'MapStringLocationDistance',
    as HashRef[LocationDistance()];

declare 'Zone',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Zone'];

coerce 'Zone',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Zone'->new($_) };

declare 'RepeatedZone',
    as ArrayRef[Zone()];

coerce 'RepeatedZone',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Zone'->new($_) } @$_ ] };

declare 'MapStringZone',
    as HashRef[Zone()];

declare 'ReplicaType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'Server',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Server'];

coerce 'Server',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Server'->new($_) };

declare 'RepeatedServer',
    as ArrayRef[Server()];

coerce 'RepeatedServer',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Server'->new($_) } @$_ ] };

declare 'MapStringServer',
    as HashRef[Server()];

declare 'State',
    as (Int | Str);

declare 'GcsExternalStorage',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GcsExternalStorage'];

coerce 'GcsExternalStorage',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GcsExternalStorage'->new($_) };

declare 'RepeatedGcsExternalStorage',
    as ArrayRef[GcsExternalStorage()];

coerce 'RepeatedGcsExternalStorage',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GcsExternalStorage'->new($_) } @$_ ] };

declare 'MapStringGcsExternalStorage',
    as HashRef[GcsExternalStorage()];

declare 'S3ExternalStorage',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::S3ExternalStorage'];

coerce 'S3ExternalStorage',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::S3ExternalStorage'->new($_) };

declare 'RepeatedS3ExternalStorage',
    as ArrayRef[S3ExternalStorage()];

coerce 'RepeatedS3ExternalStorage',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::S3ExternalStorage'->new($_) } @$_ ] };

declare 'MapStringS3ExternalStorage',
    as HashRef[S3ExternalStorage()];

declare 'S3AuthConfig',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::S3ExternalStorage::S3AuthConfig'];

coerce 'S3AuthConfig',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::S3ExternalStorage::S3AuthConfig'->new($_) };

declare 'RepeatedS3AuthConfig',
    as ArrayRef[S3AuthConfig()];

coerce 'RepeatedS3AuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::S3ExternalStorage::S3AuthConfig'->new($_) } @$_ ] };

declare 'MapStringS3AuthConfig',
    as HashRef[S3AuthConfig()];

declare 'S3CompatibleExternalStorage',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::S3CompatibleExternalStorage'];

coerce 'S3CompatibleExternalStorage',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::S3CompatibleExternalStorage'->new($_) };

declare 'RepeatedS3CompatibleExternalStorage',
    as ArrayRef[S3CompatibleExternalStorage()];

coerce 'RepeatedS3CompatibleExternalStorage',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::S3CompatibleExternalStorage'->new($_) } @$_ ] };

declare 'MapStringS3CompatibleExternalStorage',
    as HashRef[S3CompatibleExternalStorage()];

declare 'S3CompatibleAuthConfig',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::S3CompatibleExternalStorage::S3CompatibleAuthConfig'];

coerce 'S3CompatibleAuthConfig',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::S3CompatibleExternalStorage::S3CompatibleAuthConfig'->new($_) };

declare 'RepeatedS3CompatibleAuthConfig',
    as ArrayRef[S3CompatibleAuthConfig()];

coerce 'RepeatedS3CompatibleAuthConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::S3CompatibleExternalStorage::S3CompatibleAuthConfig'->new($_) } @$_ ] };

declare 'MapStringS3CompatibleAuthConfig',
    as HashRef[S3CompatibleAuthConfig()];

declare 'ExternalStorage',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ExternalStorage'];

coerce 'ExternalStorage',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ExternalStorage'->new($_) };

declare 'RepeatedExternalStorage',
    as ArrayRef[ExternalStorage()];

coerce 'RepeatedExternalStorage',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ExternalStorage'->new($_) } @$_ ] };

declare 'MapStringExternalStorage',
    as HashRef[ExternalStorage()];

declare 'BackupDescriptor',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::BackupDescriptor'];

coerce 'BackupDescriptor',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::BackupDescriptor'->new($_) };

declare 'RepeatedBackupDescriptor',
    as ArrayRef[BackupDescriptor()];

coerce 'RepeatedBackupDescriptor',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::BackupDescriptor'->new($_) } @$_ ] };

declare 'MapStringBackupDescriptor',
    as HashRef[BackupDescriptor()];

declare 'CreateExternalStorageRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateExternalStorageRequest'];

coerce 'CreateExternalStorageRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateExternalStorageRequest'->new($_) };

declare 'RepeatedCreateExternalStorageRequest',
    as ArrayRef[CreateExternalStorageRequest()];

coerce 'RepeatedCreateExternalStorageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateExternalStorageRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExternalStorageRequest',
    as HashRef[CreateExternalStorageRequest()];

declare 'GetExternalStorageRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetExternalStorageRequest'];

coerce 'GetExternalStorageRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetExternalStorageRequest'->new($_) };

declare 'RepeatedGetExternalStorageRequest',
    as ArrayRef[GetExternalStorageRequest()];

coerce 'RepeatedGetExternalStorageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetExternalStorageRequest'->new($_) } @$_ ] };

declare 'MapStringGetExternalStorageRequest',
    as HashRef[GetExternalStorageRequest()];

declare 'DeleteExternalStorageRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteExternalStorageRequest'];

coerce 'DeleteExternalStorageRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteExternalStorageRequest'->new($_) };

declare 'RepeatedDeleteExternalStorageRequest',
    as ArrayRef[DeleteExternalStorageRequest()];

coerce 'RepeatedDeleteExternalStorageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteExternalStorageRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExternalStorageRequest',
    as HashRef[DeleteExternalStorageRequest()];

declare 'ListExternalStoragesRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesRequest'];

coerce 'ListExternalStoragesRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesRequest'->new($_) };

declare 'RepeatedListExternalStoragesRequest',
    as ArrayRef[ListExternalStoragesRequest()];

coerce 'RepeatedListExternalStoragesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesRequest'->new($_) } @$_ ] };

declare 'MapStringListExternalStoragesRequest',
    as HashRef[ListExternalStoragesRequest()];

declare 'ListExternalStoragesResponse',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesResponse'];

coerce 'ListExternalStoragesResponse',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesResponse'->new($_) };

declare 'RepeatedListExternalStoragesResponse',
    as ArrayRef[ListExternalStoragesResponse()];

coerce 'RepeatedListExternalStoragesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesResponse'->new($_) } @$_ ] };

declare 'MapStringListExternalStoragesResponse',
    as HashRef[ListExternalStoragesResponse()];

declare 'BackupDescriptorSource',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::BackupDescriptorSource'];

coerce 'BackupDescriptorSource',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::BackupDescriptorSource'->new($_) };

declare 'RepeatedBackupDescriptorSource',
    as ArrayRef[BackupDescriptorSource()];

coerce 'RepeatedBackupDescriptorSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::BackupDescriptorSource'->new($_) } @$_ ] };

declare 'MapStringBackupDescriptorSource',
    as HashRef[BackupDescriptorSource()];

declare 'ImportBackupRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ImportBackupRequest'];

coerce 'ImportBackupRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ImportBackupRequest'->new($_) };

declare 'RepeatedImportBackupRequest',
    as ArrayRef[ImportBackupRequest()];

coerce 'RepeatedImportBackupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ImportBackupRequest'->new($_) } @$_ ] };

declare 'MapStringImportBackupRequest',
    as HashRef[ImportBackupRequest()];

declare 'ImportBackupMetadata',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ImportBackupMetadata'];

coerce 'ImportBackupMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ImportBackupMetadata'->new($_) };

declare 'RepeatedImportBackupMetadata',
    as ArrayRef[ImportBackupMetadata()];

coerce 'RepeatedImportBackupMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ImportBackupMetadata'->new($_) } @$_ ] };

declare 'MapStringImportBackupMetadata',
    as HashRef[ImportBackupMetadata()];

declare 'ListBackupDescriptorsRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsRequest'];

coerce 'ListBackupDescriptorsRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsRequest'->new($_) };

declare 'RepeatedListBackupDescriptorsRequest',
    as ArrayRef[ListBackupDescriptorsRequest()];

coerce 'RepeatedListBackupDescriptorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsRequest'->new($_) } @$_ ] };

declare 'MapStringListBackupDescriptorsRequest',
    as HashRef[ListBackupDescriptorsRequest()];

declare 'ListBackupDescriptorsResponse',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsResponse'];

coerce 'ListBackupDescriptorsResponse',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsResponse'->new($_) };

declare 'RepeatedListBackupDescriptorsResponse',
    as ArrayRef[ListBackupDescriptorsResponse()];

coerce 'RepeatedListBackupDescriptorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsResponse'->new($_) } @$_ ] };

declare 'MapStringListBackupDescriptorsResponse',
    as HashRef[ListBackupDescriptorsResponse()];

declare 'CreateLocationRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateLocationRequest'];

coerce 'CreateLocationRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateLocationRequest'->new($_) };

declare 'RepeatedCreateLocationRequest',
    as ArrayRef[CreateLocationRequest()];

coerce 'RepeatedCreateLocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateLocationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLocationRequest',
    as HashRef[CreateLocationRequest()];

declare 'GetLocationRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetLocationRequest'];

coerce 'GetLocationRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetLocationRequest'->new($_) };

declare 'RepeatedGetLocationRequest',
    as ArrayRef[GetLocationRequest()];

coerce 'RepeatedGetLocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetLocationRequest'->new($_) } @$_ ] };

declare 'MapStringGetLocationRequest',
    as HashRef[GetLocationRequest()];

declare 'ListLocationsRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsRequest'];

coerce 'ListLocationsRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsRequest'->new($_) };

declare 'RepeatedListLocationsRequest',
    as ArrayRef[ListLocationsRequest()];

coerce 'RepeatedListLocationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsRequest'->new($_) } @$_ ] };

declare 'MapStringListLocationsRequest',
    as HashRef[ListLocationsRequest()];

declare 'ListLocationsResponse',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsResponse'];

coerce 'ListLocationsResponse',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsResponse'->new($_) };

declare 'RepeatedListLocationsResponse',
    as ArrayRef[ListLocationsResponse()];

coerce 'RepeatedListLocationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsResponse'->new($_) } @$_ ] };

declare 'MapStringListLocationsResponse',
    as HashRef[ListLocationsResponse()];

declare 'DeleteLocationRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteLocationRequest'];

coerce 'DeleteLocationRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteLocationRequest'->new($_) };

declare 'RepeatedDeleteLocationRequest',
    as ArrayRef[DeleteLocationRequest()];

coerce 'RepeatedDeleteLocationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteLocationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLocationRequest',
    as HashRef[DeleteLocationRequest()];

declare 'CreateLocationDistanceRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateLocationDistanceRequest'];

coerce 'CreateLocationDistanceRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateLocationDistanceRequest'->new($_) };

declare 'RepeatedCreateLocationDistanceRequest',
    as ArrayRef[CreateLocationDistanceRequest()];

coerce 'RepeatedCreateLocationDistanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateLocationDistanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateLocationDistanceRequest',
    as HashRef[CreateLocationDistanceRequest()];

declare 'GetLocationDistanceRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetLocationDistanceRequest'];

coerce 'GetLocationDistanceRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetLocationDistanceRequest'->new($_) };

declare 'RepeatedGetLocationDistanceRequest',
    as ArrayRef[GetLocationDistanceRequest()];

coerce 'RepeatedGetLocationDistanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetLocationDistanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetLocationDistanceRequest',
    as HashRef[GetLocationDistanceRequest()];

declare 'ListLocationDistancesRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesRequest'];

coerce 'ListLocationDistancesRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesRequest'->new($_) };

declare 'RepeatedListLocationDistancesRequest',
    as ArrayRef[ListLocationDistancesRequest()];

coerce 'RepeatedListLocationDistancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesRequest'->new($_) } @$_ ] };

declare 'MapStringListLocationDistancesRequest',
    as HashRef[ListLocationDistancesRequest()];

declare 'ListLocationDistancesResponse',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesResponse'];

coerce 'ListLocationDistancesResponse',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesResponse'->new($_) };

declare 'RepeatedListLocationDistancesResponse',
    as ArrayRef[ListLocationDistancesResponse()];

coerce 'RepeatedListLocationDistancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesResponse'->new($_) } @$_ ] };

declare 'MapStringListLocationDistancesResponse',
    as HashRef[ListLocationDistancesResponse()];

declare 'UpdateLocationDistanceRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::UpdateLocationDistanceRequest'];

coerce 'UpdateLocationDistanceRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::UpdateLocationDistanceRequest'->new($_) };

declare 'RepeatedUpdateLocationDistanceRequest',
    as ArrayRef[UpdateLocationDistanceRequest()];

coerce 'RepeatedUpdateLocationDistanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::UpdateLocationDistanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLocationDistanceRequest',
    as HashRef[UpdateLocationDistanceRequest()];

declare 'DeleteLocationDistanceRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteLocationDistanceRequest'];

coerce 'DeleteLocationDistanceRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteLocationDistanceRequest'->new($_) };

declare 'RepeatedDeleteLocationDistanceRequest',
    as ArrayRef[DeleteLocationDistanceRequest()];

coerce 'RepeatedDeleteLocationDistanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteLocationDistanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteLocationDistanceRequest',
    as HashRef[DeleteLocationDistanceRequest()];

declare 'CreateZoneRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateZoneRequest'];

coerce 'CreateZoneRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateZoneRequest'->new($_) };

declare 'RepeatedCreateZoneRequest',
    as ArrayRef[CreateZoneRequest()];

coerce 'RepeatedCreateZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateZoneRequest'->new($_) } @$_ ] };

declare 'MapStringCreateZoneRequest',
    as HashRef[CreateZoneRequest()];

declare 'GetZoneRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetZoneRequest'];

coerce 'GetZoneRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetZoneRequest'->new($_) };

declare 'RepeatedGetZoneRequest',
    as ArrayRef[GetZoneRequest()];

coerce 'RepeatedGetZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetZoneRequest'->new($_) } @$_ ] };

declare 'MapStringGetZoneRequest',
    as HashRef[GetZoneRequest()];

declare 'ListZonesRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesRequest'];

coerce 'ListZonesRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesRequest'->new($_) };

declare 'RepeatedListZonesRequest',
    as ArrayRef[ListZonesRequest()];

coerce 'RepeatedListZonesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesRequest'->new($_) } @$_ ] };

declare 'MapStringListZonesRequest',
    as HashRef[ListZonesRequest()];

declare 'ListZonesResponse',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesResponse'];

coerce 'ListZonesResponse',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesResponse'->new($_) };

declare 'RepeatedListZonesResponse',
    as ArrayRef[ListZonesResponse()];

coerce 'RepeatedListZonesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesResponse'->new($_) } @$_ ] };

declare 'MapStringListZonesResponse',
    as HashRef[ListZonesResponse()];

declare 'ListZoneOperationsRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsRequest'];

coerce 'ListZoneOperationsRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsRequest'->new($_) };

declare 'RepeatedListZoneOperationsRequest',
    as ArrayRef[ListZoneOperationsRequest()];

coerce 'RepeatedListZoneOperationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsRequest'->new($_) } @$_ ] };

declare 'MapStringListZoneOperationsRequest',
    as HashRef[ListZoneOperationsRequest()];

declare 'ListZoneOperationsResponse',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsResponse'];

coerce 'ListZoneOperationsResponse',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsResponse'->new($_) };

declare 'RepeatedListZoneOperationsResponse',
    as ArrayRef[ListZoneOperationsResponse()];

coerce 'RepeatedListZoneOperationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsResponse'->new($_) } @$_ ] };

declare 'MapStringListZoneOperationsResponse',
    as HashRef[ListZoneOperationsResponse()];

declare 'DeleteZoneRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteZoneRequest'];

coerce 'DeleteZoneRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteZoneRequest'->new($_) };

declare 'RepeatedDeleteZoneRequest',
    as ArrayRef[DeleteZoneRequest()];

coerce 'RepeatedDeleteZoneRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteZoneRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteZoneRequest',
    as HashRef[DeleteZoneRequest()];

declare 'CreateServerRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateServerRequest'];

coerce 'CreateServerRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateServerRequest'->new($_) };

declare 'RepeatedCreateServerRequest',
    as ArrayRef[CreateServerRequest()];

coerce 'RepeatedCreateServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateServerRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServerRequest',
    as HashRef[CreateServerRequest()];

declare 'GetServerRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetServerRequest'];

coerce 'GetServerRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetServerRequest'->new($_) };

declare 'RepeatedGetServerRequest',
    as ArrayRef[GetServerRequest()];

coerce 'RepeatedGetServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetServerRequest'->new($_) } @$_ ] };

declare 'MapStringGetServerRequest',
    as HashRef[GetServerRequest()];

declare 'ListServersRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersRequest'];

coerce 'ListServersRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersRequest'->new($_) };

declare 'RepeatedListServersRequest',
    as ArrayRef[ListServersRequest()];

coerce 'RepeatedListServersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersRequest'->new($_) } @$_ ] };

declare 'MapStringListServersRequest',
    as HashRef[ListServersRequest()];

declare 'ListServersResponse',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersResponse'];

coerce 'ListServersResponse',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersResponse'->new($_) };

declare 'RepeatedListServersResponse',
    as ArrayRef[ListServersResponse()];

coerce 'RepeatedListServersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersResponse'->new($_) } @$_ ] };

declare 'MapStringListServersResponse',
    as HashRef[ListServersResponse()];

declare 'ListServerOperationsRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsRequest'];

coerce 'ListServerOperationsRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsRequest'->new($_) };

declare 'RepeatedListServerOperationsRequest',
    as ArrayRef[ListServerOperationsRequest()];

coerce 'RepeatedListServerOperationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsRequest'->new($_) } @$_ ] };

declare 'MapStringListServerOperationsRequest',
    as HashRef[ListServerOperationsRequest()];

declare 'ListServerOperationsResponse',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsResponse'];

coerce 'ListServerOperationsResponse',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsResponse'->new($_) };

declare 'RepeatedListServerOperationsResponse',
    as ArrayRef[ListServerOperationsResponse()];

coerce 'RepeatedListServerOperationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsResponse'->new($_) } @$_ ] };

declare 'MapStringListServerOperationsResponse',
    as HashRef[ListServerOperationsResponse()];

declare 'DeleteServerRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteServerRequest'];

coerce 'DeleteServerRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteServerRequest'->new($_) };

declare 'RepeatedDeleteServerRequest',
    as ArrayRef[DeleteServerRequest()];

coerce 'RepeatedDeleteServerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteServerRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServerRequest',
    as HashRef[DeleteServerRequest()];

declare 'DeleteServerMetadata',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteServerMetadata'];

coerce 'DeleteServerMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteServerMetadata'->new($_) };

declare 'RepeatedDeleteServerMetadata',
    as ArrayRef[DeleteServerMetadata()];

coerce 'RepeatedDeleteServerMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteServerMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteServerMetadata',
    as HashRef[DeleteServerMetadata()];

declare 'State',
    as (Int | Str);

declare 'CreateServerMetadata',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateServerMetadata'];

coerce 'CreateServerMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateServerMetadata'->new($_) };

declare 'RepeatedCreateServerMetadata',
    as ArrayRef[CreateServerMetadata()];

coerce 'RepeatedCreateServerMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateServerMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateServerMetadata',
    as HashRef[CreateServerMetadata()];

declare 'State',
    as (Int | Str);

declare 'CreateZoneMetadata',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateZoneMetadata'];

coerce 'CreateZoneMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateZoneMetadata'->new($_) };

declare 'RepeatedCreateZoneMetadata',
    as ArrayRef[CreateZoneMetadata()];

coerce 'RepeatedCreateZoneMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateZoneMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateZoneMetadata',
    as HashRef[CreateZoneMetadata()];

declare 'State',
    as (Int | Str);

declare 'DeleteZoneMetadata',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteZoneMetadata'];

coerce 'DeleteZoneMetadata',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteZoneMetadata'->new($_) };

declare 'RepeatedDeleteZoneMetadata',
    as ArrayRef[DeleteZoneMetadata()];

coerce 'RepeatedDeleteZoneMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteZoneMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteZoneMetadata',
    as HashRef[DeleteZoneMetadata()];

declare 'State',
    as (Int | Str);

declare 'Rollout',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout'];

coerce 'Rollout',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout'->new($_) };

declare 'RepeatedRollout',
    as ArrayRef[Rollout()];

coerce 'RepeatedRollout',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout'->new($_) } @$_ ] };

declare 'MapStringRollout',
    as HashRef[Rollout()];

declare 'State',
    as (Int | Str);

declare 'RolloutPhase',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RolloutPhase'];

coerce 'RolloutPhase',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RolloutPhase'->new($_) };

declare 'RepeatedRolloutPhase',
    as ArrayRef[RolloutPhase()];

coerce 'RepeatedRolloutPhase',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RolloutPhase'->new($_) } @$_ ] };

declare 'MapStringRolloutPhase',
    as HashRef[RolloutPhase()];

declare 'ListRolloutsRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsRequest'];

coerce 'ListRolloutsRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsRequest'->new($_) };

declare 'RepeatedListRolloutsRequest',
    as ArrayRef[ListRolloutsRequest()];

coerce 'RepeatedListRolloutsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsRequest'->new($_) } @$_ ] };

declare 'MapStringListRolloutsRequest',
    as HashRef[ListRolloutsRequest()];

declare 'ListRolloutsResponse',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsResponse'];

coerce 'ListRolloutsResponse',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsResponse'->new($_) };

declare 'RepeatedListRolloutsResponse',
    as ArrayRef[ListRolloutsResponse()];

coerce 'RepeatedListRolloutsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsResponse'->new($_) } @$_ ] };

declare 'MapStringListRolloutsResponse',
    as HashRef[ListRolloutsResponse()];

declare 'GetRolloutRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetRolloutRequest'];

coerce 'GetRolloutRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetRolloutRequest'->new($_) };

declare 'RepeatedGetRolloutRequest',
    as ArrayRef[GetRolloutRequest()];

coerce 'RepeatedGetRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringGetRolloutRequest',
    as HashRef[GetRolloutRequest()];

declare 'ScheduleRolloutPhaseRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ScheduleRolloutPhaseRequest'];

coerce 'ScheduleRolloutPhaseRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ScheduleRolloutPhaseRequest'->new($_) };

declare 'RepeatedScheduleRolloutPhaseRequest',
    as ArrayRef[ScheduleRolloutPhaseRequest()];

coerce 'RepeatedScheduleRolloutPhaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ScheduleRolloutPhaseRequest'->new($_) } @$_ ] };

declare 'MapStringScheduleRolloutPhaseRequest',
    as HashRef[ScheduleRolloutPhaseRequest()];

declare 'AbortRolloutRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::AbortRolloutRequest'];

coerce 'AbortRolloutRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::AbortRolloutRequest'->new($_) };

declare 'RepeatedAbortRolloutRequest',
    as ArrayRef[AbortRolloutRequest()];

coerce 'RepeatedAbortRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::AbortRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringAbortRolloutRequest',
    as HashRef[AbortRolloutRequest()];

declare 'RollbackRolloutRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RollbackRolloutRequest'];

coerce 'RollbackRolloutRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RollbackRolloutRequest'->new($_) };

declare 'RepeatedRollbackRolloutRequest',
    as ArrayRef[RollbackRolloutRequest()];

coerce 'RepeatedRollbackRolloutRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RollbackRolloutRequest'->new($_) } @$_ ] };

declare 'MapStringRollbackRolloutRequest',
    as HashRef[RollbackRolloutRequest()];

declare 'RotateInternalKeysRequest',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysRequest'];

coerce 'RotateInternalKeysRequest',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysRequest'->new($_) };

declare 'RepeatedRotateInternalKeysRequest',
    as ArrayRef[RotateInternalKeysRequest()];

coerce 'RepeatedRotateInternalKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysRequest'->new($_) } @$_ ] };

declare 'MapStringRotateInternalKeysRequest',
    as HashRef[RotateInternalKeysRequest()];

declare 'KeyType',
    as (Int | Str);

declare 'RotateInternalKeysResponse',
    as InstanceOf['Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysResponse'];

coerce 'RotateInternalKeysResponse',
    from HashRef, via { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysResponse'->new($_) };

declare 'RepeatedRotateInternalKeysResponse',
    as ArrayRef[RotateInternalKeysResponse()];

coerce 'RepeatedRotateInternalKeysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysResponse'->new($_) } @$_ ] };

declare 'MapStringRotateInternalKeysResponse',
    as HashRef[RotateInternalKeysResponse()];

1;

__END__

=head1 NAME

Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
