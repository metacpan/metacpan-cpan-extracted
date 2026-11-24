package Google::Cloud::Biglake::V1::IcebergRestCatalog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'IcebergCatalog',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog'];

coerce 'IcebergCatalog',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog'->new($_) };

declare 'RepeatedIcebergCatalog',
    as ArrayRef[IcebergCatalog()];

coerce 'RepeatedIcebergCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog'->new($_) } @$_ ] };

declare 'MapStringIcebergCatalog',
    as HashRef[IcebergCatalog()];

declare 'CatalogType',
    as (Int | Str);

declare 'CredentialMode',
    as (Int | Str);

declare 'Replica',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::Replica'];

coerce 'Replica',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::Replica'->new($_) };

declare 'RepeatedReplica',
    as ArrayRef[Replica()];

coerce 'RepeatedReplica',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::Replica'->new($_) } @$_ ] };

declare 'MapStringReplica',
    as HashRef[Replica()];

declare 'State',
    as (Int | Str);

declare 'RestrictedLocationsConfig',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::RestrictedLocationsConfig'];

coerce 'RestrictedLocationsConfig',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::RestrictedLocationsConfig'->new($_) };

declare 'RepeatedRestrictedLocationsConfig',
    as ArrayRef[RestrictedLocationsConfig()];

coerce 'RepeatedRestrictedLocationsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::RestrictedLocationsConfig'->new($_) } @$_ ] };

declare 'MapStringRestrictedLocationsConfig',
    as HashRef[RestrictedLocationsConfig()];

declare 'FederatedCatalogOptions',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions'];

coerce 'FederatedCatalogOptions',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions'->new($_) };

declare 'RepeatedFederatedCatalogOptions',
    as ArrayRef[FederatedCatalogOptions()];

coerce 'RepeatedFederatedCatalogOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions'->new($_) } @$_ ] };

declare 'MapStringFederatedCatalogOptions',
    as HashRef[FederatedCatalogOptions()];

declare 'UnityCatalogInfo',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::UnityCatalogInfo'];

coerce 'UnityCatalogInfo',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::UnityCatalogInfo'->new($_) };

declare 'RepeatedUnityCatalogInfo',
    as ArrayRef[UnityCatalogInfo()];

coerce 'RepeatedUnityCatalogInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::UnityCatalogInfo'->new($_) } @$_ ] };

declare 'MapStringUnityCatalogInfo',
    as HashRef[UnityCatalogInfo()];

declare 'GlueCatalogInfo',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::GlueCatalogInfo'];

coerce 'GlueCatalogInfo',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::GlueCatalogInfo'->new($_) };

declare 'RepeatedGlueCatalogInfo',
    as ArrayRef[GlueCatalogInfo()];

coerce 'RepeatedGlueCatalogInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::GlueCatalogInfo'->new($_) } @$_ ] };

declare 'MapStringGlueCatalogInfo',
    as HashRef[GlueCatalogInfo()];

declare 'SnowflakeCatalogInfo',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::SnowflakeCatalogInfo'];

coerce 'SnowflakeCatalogInfo',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::SnowflakeCatalogInfo'->new($_) };

declare 'RepeatedSnowflakeCatalogInfo',
    as ArrayRef[SnowflakeCatalogInfo()];

coerce 'RepeatedSnowflakeCatalogInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::SnowflakeCatalogInfo'->new($_) } @$_ ] };

declare 'MapStringSnowflakeCatalogInfo',
    as HashRef[SnowflakeCatalogInfo()];

declare 'RefreshSchedule',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::RefreshSchedule'];

coerce 'RefreshSchedule',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::RefreshSchedule'->new($_) };

declare 'RepeatedRefreshSchedule',
    as ArrayRef[RefreshSchedule()];

coerce 'RepeatedRefreshSchedule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::RefreshSchedule'->new($_) } @$_ ] };

declare 'MapStringRefreshSchedule',
    as HashRef[RefreshSchedule()];

declare 'RefreshScope',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::RefreshScope'];

coerce 'RefreshScope',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::RefreshScope'->new($_) };

declare 'RepeatedRefreshScope',
    as ArrayRef[RefreshScope()];

coerce 'RepeatedRefreshScope',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::RefreshScope'->new($_) } @$_ ] };

declare 'MapStringRefreshScope',
    as HashRef[RefreshScope()];

declare 'RefreshOptions',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::RefreshOptions'];

coerce 'RefreshOptions',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::RefreshOptions'->new($_) };

declare 'RepeatedRefreshOptions',
    as ArrayRef[RefreshOptions()];

coerce 'RepeatedRefreshOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::RefreshOptions'->new($_) } @$_ ] };

declare 'MapStringRefreshOptions',
    as HashRef[RefreshOptions()];

declare 'RefreshStatus',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::RefreshStatus'];

coerce 'RefreshStatus',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::RefreshStatus'->new($_) };

declare 'RepeatedRefreshStatus',
    as ArrayRef[RefreshStatus()];

coerce 'RepeatedRefreshStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalog::FederatedCatalogOptions::RefreshStatus'->new($_) } @$_ ] };

declare 'MapStringRefreshStatus',
    as HashRef[RefreshStatus()];

declare 'CreateIcebergCatalogRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::CreateIcebergCatalogRequest'];

coerce 'CreateIcebergCatalogRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::CreateIcebergCatalogRequest'->new($_) };

declare 'RepeatedCreateIcebergCatalogRequest',
    as ArrayRef[CreateIcebergCatalogRequest()];

coerce 'RepeatedCreateIcebergCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::CreateIcebergCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIcebergCatalogRequest',
    as HashRef[CreateIcebergCatalogRequest()];

declare 'DeleteIcebergCatalogRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::DeleteIcebergCatalogRequest'];

coerce 'DeleteIcebergCatalogRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::DeleteIcebergCatalogRequest'->new($_) };

declare 'RepeatedDeleteIcebergCatalogRequest',
    as ArrayRef[DeleteIcebergCatalogRequest()];

coerce 'RepeatedDeleteIcebergCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::DeleteIcebergCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIcebergCatalogRequest',
    as HashRef[DeleteIcebergCatalogRequest()];

declare 'UpdateIcebergCatalogRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::UpdateIcebergCatalogRequest'];

coerce 'UpdateIcebergCatalogRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::UpdateIcebergCatalogRequest'->new($_) };

declare 'RepeatedUpdateIcebergCatalogRequest',
    as ArrayRef[UpdateIcebergCatalogRequest()];

coerce 'RepeatedUpdateIcebergCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::UpdateIcebergCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIcebergCatalogRequest',
    as HashRef[UpdateIcebergCatalogRequest()];

declare 'GetIcebergCatalogRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::GetIcebergCatalogRequest'];

coerce 'GetIcebergCatalogRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::GetIcebergCatalogRequest'->new($_) };

declare 'RepeatedGetIcebergCatalogRequest',
    as ArrayRef[GetIcebergCatalogRequest()];

coerce 'RepeatedGetIcebergCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::GetIcebergCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringGetIcebergCatalogRequest',
    as HashRef[GetIcebergCatalogRequest()];

declare 'ListIcebergCatalogsRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergCatalogsRequest'];

coerce 'ListIcebergCatalogsRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergCatalogsRequest'->new($_) };

declare 'RepeatedListIcebergCatalogsRequest',
    as ArrayRef[ListIcebergCatalogsRequest()];

coerce 'RepeatedListIcebergCatalogsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergCatalogsRequest'->new($_) } @$_ ] };

declare 'MapStringListIcebergCatalogsRequest',
    as HashRef[ListIcebergCatalogsRequest()];

declare 'CatalogView',
    as (Int | Str);

declare 'ListIcebergCatalogsResponse',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergCatalogsResponse'];

coerce 'ListIcebergCatalogsResponse',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergCatalogsResponse'->new($_) };

declare 'RepeatedListIcebergCatalogsResponse',
    as ArrayRef[ListIcebergCatalogsResponse()];

coerce 'RepeatedListIcebergCatalogsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergCatalogsResponse'->new($_) } @$_ ] };

declare 'MapStringListIcebergCatalogsResponse',
    as HashRef[ListIcebergCatalogsResponse()];

declare 'FailoverIcebergCatalogRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::FailoverIcebergCatalogRequest'];

coerce 'FailoverIcebergCatalogRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::FailoverIcebergCatalogRequest'->new($_) };

declare 'RepeatedFailoverIcebergCatalogRequest',
    as ArrayRef[FailoverIcebergCatalogRequest()];

coerce 'RepeatedFailoverIcebergCatalogRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::FailoverIcebergCatalogRequest'->new($_) } @$_ ] };

declare 'MapStringFailoverIcebergCatalogRequest',
    as HashRef[FailoverIcebergCatalogRequest()];

declare 'FailoverIcebergCatalogResponse',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::FailoverIcebergCatalogResponse'];

coerce 'FailoverIcebergCatalogResponse',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::FailoverIcebergCatalogResponse'->new($_) };

declare 'RepeatedFailoverIcebergCatalogResponse',
    as ArrayRef[FailoverIcebergCatalogResponse()];

coerce 'RepeatedFailoverIcebergCatalogResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::FailoverIcebergCatalogResponse'->new($_) } @$_ ] };

declare 'MapStringFailoverIcebergCatalogResponse',
    as HashRef[FailoverIcebergCatalogResponse()];

declare 'UpdateIcebergTableRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::UpdateIcebergTableRequest'];

coerce 'UpdateIcebergTableRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::UpdateIcebergTableRequest'->new($_) };

declare 'RepeatedUpdateIcebergTableRequest',
    as ArrayRef[UpdateIcebergTableRequest()];

coerce 'RepeatedUpdateIcebergTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::UpdateIcebergTableRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIcebergTableRequest',
    as HashRef[UpdateIcebergTableRequest()];

declare 'GetIcebergTableRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::GetIcebergTableRequest'];

coerce 'GetIcebergTableRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::GetIcebergTableRequest'->new($_) };

declare 'RepeatedGetIcebergTableRequest',
    as ArrayRef[GetIcebergTableRequest()];

coerce 'RepeatedGetIcebergTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::GetIcebergTableRequest'->new($_) } @$_ ] };

declare 'MapStringGetIcebergTableRequest',
    as HashRef[GetIcebergTableRequest()];

declare 'DeleteIcebergTableRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::DeleteIcebergTableRequest'];

coerce 'DeleteIcebergTableRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::DeleteIcebergTableRequest'->new($_) };

declare 'RepeatedDeleteIcebergTableRequest',
    as ArrayRef[DeleteIcebergTableRequest()];

coerce 'RepeatedDeleteIcebergTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::DeleteIcebergTableRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIcebergTableRequest',
    as HashRef[DeleteIcebergTableRequest()];

declare 'CreateIcebergTableRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::CreateIcebergTableRequest'];

coerce 'CreateIcebergTableRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::CreateIcebergTableRequest'->new($_) };

declare 'RepeatedCreateIcebergTableRequest',
    as ArrayRef[CreateIcebergTableRequest()];

coerce 'RepeatedCreateIcebergTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::CreateIcebergTableRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIcebergTableRequest',
    as HashRef[CreateIcebergTableRequest()];

declare 'RegisterIcebergTableRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::RegisterIcebergTableRequest'];

coerce 'RegisterIcebergTableRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::RegisterIcebergTableRequest'->new($_) };

declare 'RepeatedRegisterIcebergTableRequest',
    as ArrayRef[RegisterIcebergTableRequest()];

coerce 'RepeatedRegisterIcebergTableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::RegisterIcebergTableRequest'->new($_) } @$_ ] };

declare 'MapStringRegisterIcebergTableRequest',
    as HashRef[RegisterIcebergTableRequest()];

declare 'ReportIcebergTableMetricsRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::ReportIcebergTableMetricsRequest'];

coerce 'ReportIcebergTableMetricsRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ReportIcebergTableMetricsRequest'->new($_) };

declare 'RepeatedReportIcebergTableMetricsRequest',
    as ArrayRef[ReportIcebergTableMetricsRequest()];

coerce 'RepeatedReportIcebergTableMetricsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ReportIcebergTableMetricsRequest'->new($_) } @$_ ] };

declare 'MapStringReportIcebergTableMetricsRequest',
    as HashRef[ReportIcebergTableMetricsRequest()];

declare 'ListIcebergTableIdentifiersRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergTableIdentifiersRequest'];

coerce 'ListIcebergTableIdentifiersRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergTableIdentifiersRequest'->new($_) };

declare 'RepeatedListIcebergTableIdentifiersRequest',
    as ArrayRef[ListIcebergTableIdentifiersRequest()];

coerce 'RepeatedListIcebergTableIdentifiersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergTableIdentifiersRequest'->new($_) } @$_ ] };

declare 'MapStringListIcebergTableIdentifiersRequest',
    as HashRef[ListIcebergTableIdentifiersRequest()];

declare 'TableIdentifier',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::TableIdentifier'];

coerce 'TableIdentifier',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::TableIdentifier'->new($_) };

declare 'RepeatedTableIdentifier',
    as ArrayRef[TableIdentifier()];

coerce 'RepeatedTableIdentifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::TableIdentifier'->new($_) } @$_ ] };

declare 'MapStringTableIdentifier',
    as HashRef[TableIdentifier()];

declare 'ListIcebergTableIdentifiersResponse',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergTableIdentifiersResponse'];

coerce 'ListIcebergTableIdentifiersResponse',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergTableIdentifiersResponse'->new($_) };

declare 'RepeatedListIcebergTableIdentifiersResponse',
    as ArrayRef[ListIcebergTableIdentifiersResponse()];

coerce 'RepeatedListIcebergTableIdentifiersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergTableIdentifiersResponse'->new($_) } @$_ ] };

declare 'MapStringListIcebergTableIdentifiersResponse',
    as HashRef[ListIcebergTableIdentifiersResponse()];

declare 'IcebergNamespaceUpdate',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergNamespaceUpdate'];

coerce 'IcebergNamespaceUpdate',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergNamespaceUpdate'->new($_) };

declare 'RepeatedIcebergNamespaceUpdate',
    as ArrayRef[IcebergNamespaceUpdate()];

coerce 'RepeatedIcebergNamespaceUpdate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergNamespaceUpdate'->new($_) } @$_ ] };

declare 'MapStringIcebergNamespaceUpdate',
    as HashRef[IcebergNamespaceUpdate()];

declare 'UpdatesEntry',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergNamespaceUpdate::UpdatesEntry'];

coerce 'UpdatesEntry',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergNamespaceUpdate::UpdatesEntry'->new($_) };

declare 'RepeatedUpdatesEntry',
    as ArrayRef[UpdatesEntry()];

coerce 'RepeatedUpdatesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergNamespaceUpdate::UpdatesEntry'->new($_) } @$_ ] };

declare 'MapStringUpdatesEntry',
    as HashRef[UpdatesEntry()];

declare 'UpdateIcebergNamespaceRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::UpdateIcebergNamespaceRequest'];

coerce 'UpdateIcebergNamespaceRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::UpdateIcebergNamespaceRequest'->new($_) };

declare 'RepeatedUpdateIcebergNamespaceRequest',
    as ArrayRef[UpdateIcebergNamespaceRequest()];

coerce 'RepeatedUpdateIcebergNamespaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::UpdateIcebergNamespaceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIcebergNamespaceRequest',
    as HashRef[UpdateIcebergNamespaceRequest()];

declare 'UpdateIcebergNamespaceResponse',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::UpdateIcebergNamespaceResponse'];

coerce 'UpdateIcebergNamespaceResponse',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::UpdateIcebergNamespaceResponse'->new($_) };

declare 'RepeatedUpdateIcebergNamespaceResponse',
    as ArrayRef[UpdateIcebergNamespaceResponse()];

coerce 'RepeatedUpdateIcebergNamespaceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::UpdateIcebergNamespaceResponse'->new($_) } @$_ ] };

declare 'MapStringUpdateIcebergNamespaceResponse',
    as HashRef[UpdateIcebergNamespaceResponse()];

declare 'DeleteIcebergNamespaceRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::DeleteIcebergNamespaceRequest'];

coerce 'DeleteIcebergNamespaceRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::DeleteIcebergNamespaceRequest'->new($_) };

declare 'RepeatedDeleteIcebergNamespaceRequest',
    as ArrayRef[DeleteIcebergNamespaceRequest()];

coerce 'RepeatedDeleteIcebergNamespaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::DeleteIcebergNamespaceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIcebergNamespaceRequest',
    as HashRef[DeleteIcebergNamespaceRequest()];

declare 'IcebergNamespace',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergNamespace'];

coerce 'IcebergNamespace',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergNamespace'->new($_) };

declare 'RepeatedIcebergNamespace',
    as ArrayRef[IcebergNamespace()];

coerce 'RepeatedIcebergNamespace',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergNamespace'->new($_) } @$_ ] };

declare 'MapStringIcebergNamespace',
    as HashRef[IcebergNamespace()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergNamespace::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergNamespace::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergNamespace::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'CreateIcebergNamespaceRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::CreateIcebergNamespaceRequest'];

coerce 'CreateIcebergNamespaceRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::CreateIcebergNamespaceRequest'->new($_) };

declare 'RepeatedCreateIcebergNamespaceRequest',
    as ArrayRef[CreateIcebergNamespaceRequest()];

coerce 'RepeatedCreateIcebergNamespaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::CreateIcebergNamespaceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIcebergNamespaceRequest',
    as HashRef[CreateIcebergNamespaceRequest()];

declare 'GetIcebergCatalogConfigRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::GetIcebergCatalogConfigRequest'];

coerce 'GetIcebergCatalogConfigRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::GetIcebergCatalogConfigRequest'->new($_) };

declare 'RepeatedGetIcebergCatalogConfigRequest',
    as ArrayRef[GetIcebergCatalogConfigRequest()];

coerce 'RepeatedGetIcebergCatalogConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::GetIcebergCatalogConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetIcebergCatalogConfigRequest',
    as HashRef[GetIcebergCatalogConfigRequest()];

declare 'IcebergCatalogConfig',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalogConfig'];

coerce 'IcebergCatalogConfig',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalogConfig'->new($_) };

declare 'RepeatedIcebergCatalogConfig',
    as ArrayRef[IcebergCatalogConfig()];

coerce 'RepeatedIcebergCatalogConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalogConfig'->new($_) } @$_ ] };

declare 'MapStringIcebergCatalogConfig',
    as HashRef[IcebergCatalogConfig()];

declare 'OverridesEntry',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalogConfig::OverridesEntry'];

coerce 'OverridesEntry',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalogConfig::OverridesEntry'->new($_) };

declare 'RepeatedOverridesEntry',
    as ArrayRef[OverridesEntry()];

coerce 'RepeatedOverridesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalogConfig::OverridesEntry'->new($_) } @$_ ] };

declare 'MapStringOverridesEntry',
    as HashRef[OverridesEntry()];

declare 'DefaultsEntry',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalogConfig::DefaultsEntry'];

coerce 'DefaultsEntry',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalogConfig::DefaultsEntry'->new($_) };

declare 'RepeatedDefaultsEntry',
    as ArrayRef[DefaultsEntry()];

coerce 'RepeatedDefaultsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::IcebergCatalogConfig::DefaultsEntry'->new($_) } @$_ ] };

declare 'MapStringDefaultsEntry',
    as HashRef[DefaultsEntry()];

declare 'GetIcebergNamespaceRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::GetIcebergNamespaceRequest'];

coerce 'GetIcebergNamespaceRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::GetIcebergNamespaceRequest'->new($_) };

declare 'RepeatedGetIcebergNamespaceRequest',
    as ArrayRef[GetIcebergNamespaceRequest()];

coerce 'RepeatedGetIcebergNamespaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::GetIcebergNamespaceRequest'->new($_) } @$_ ] };

declare 'MapStringGetIcebergNamespaceRequest',
    as HashRef[GetIcebergNamespaceRequest()];

declare 'ListIcebergNamespacesRequest',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergNamespacesRequest'];

coerce 'ListIcebergNamespacesRequest',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergNamespacesRequest'->new($_) };

declare 'RepeatedListIcebergNamespacesRequest',
    as ArrayRef[ListIcebergNamespacesRequest()];

coerce 'RepeatedListIcebergNamespacesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergNamespacesRequest'->new($_) } @$_ ] };

declare 'MapStringListIcebergNamespacesRequest',
    as HashRef[ListIcebergNamespacesRequest()];

declare 'ListIcebergNamespacesResponse',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergNamespacesResponse'];

coerce 'ListIcebergNamespacesResponse',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergNamespacesResponse'->new($_) };

declare 'RepeatedListIcebergNamespacesResponse',
    as ArrayRef[ListIcebergNamespacesResponse()];

coerce 'RepeatedListIcebergNamespacesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::ListIcebergNamespacesResponse'->new($_) } @$_ ] };

declare 'MapStringListIcebergNamespacesResponse',
    as HashRef[ListIcebergNamespacesResponse()];

declare 'StorageCredential',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::StorageCredential'];

coerce 'StorageCredential',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::StorageCredential'->new($_) };

declare 'RepeatedStorageCredential',
    as ArrayRef[StorageCredential()];

coerce 'RepeatedStorageCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::StorageCredential'->new($_) } @$_ ] };

declare 'MapStringStorageCredential',
    as HashRef[StorageCredential()];

declare 'ConfigEntry',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::StorageCredential::ConfigEntry'];

coerce 'ConfigEntry',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::StorageCredential::ConfigEntry'->new($_) };

declare 'RepeatedConfigEntry',
    as ArrayRef[ConfigEntry()];

coerce 'RepeatedConfigEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::StorageCredential::ConfigEntry'->new($_) } @$_ ] };

declare 'MapStringConfigEntry',
    as HashRef[ConfigEntry()];

declare 'LoadIcebergTableCredentialsResponse',
    as InstanceOf['Google::Cloud::Biglake::V1::IcebergRestCatalog::LoadIcebergTableCredentialsResponse'];

coerce 'LoadIcebergTableCredentialsResponse',
    from HashRef, via { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::LoadIcebergTableCredentialsResponse'->new($_) };

declare 'RepeatedLoadIcebergTableCredentialsResponse',
    as ArrayRef[LoadIcebergTableCredentialsResponse()];

coerce 'RepeatedLoadIcebergTableCredentialsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Biglake::V1::IcebergRestCatalog::LoadIcebergTableCredentialsResponse'->new($_) } @$_ ] };

declare 'MapStringLoadIcebergTableCredentialsResponse',
    as HashRef[LoadIcebergTableCredentialsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Biglake::V1::IcebergRestCatalog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
