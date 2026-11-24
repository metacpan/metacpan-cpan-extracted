package Google::Cloud::Datastream::V1::DatastreamResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MongodbJsonMode',
    as (Int | Str);

declare 'PartitioningTimeGranularity',
    as (Int | Str);

declare 'OracleProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleProfile'];

coerce 'OracleProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleProfile'->new($_) };

declare 'RepeatedOracleProfile',
    as ArrayRef[OracleProfile()];

coerce 'RepeatedOracleProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleProfile'->new($_) } @$_ ] };

declare 'MapStringOracleProfile',
    as HashRef[OracleProfile()];

declare 'ConnectionAttributesEntry',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleProfile::ConnectionAttributesEntry'];

coerce 'ConnectionAttributesEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleProfile::ConnectionAttributesEntry'->new($_) };

declare 'RepeatedConnectionAttributesEntry',
    as ArrayRef[ConnectionAttributesEntry()];

coerce 'RepeatedConnectionAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleProfile::ConnectionAttributesEntry'->new($_) } @$_ ] };

declare 'MapStringConnectionAttributesEntry',
    as HashRef[ConnectionAttributesEntry()];

declare 'OracleAsmConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleAsmConfig'];

coerce 'OracleAsmConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleAsmConfig'->new($_) };

declare 'RepeatedOracleAsmConfig',
    as ArrayRef[OracleAsmConfig()];

coerce 'RepeatedOracleAsmConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleAsmConfig'->new($_) } @$_ ] };

declare 'MapStringOracleAsmConfig',
    as HashRef[OracleAsmConfig()];

declare 'ConnectionAttributesEntry',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleAsmConfig::ConnectionAttributesEntry'];

coerce 'ConnectionAttributesEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleAsmConfig::ConnectionAttributesEntry'->new($_) };

declare 'RepeatedConnectionAttributesEntry',
    as ArrayRef[ConnectionAttributesEntry()];

coerce 'RepeatedConnectionAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleAsmConfig::ConnectionAttributesEntry'->new($_) } @$_ ] };

declare 'MapStringConnectionAttributesEntry',
    as HashRef[ConnectionAttributesEntry()];

declare 'MysqlProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MysqlProfile'];

coerce 'MysqlProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlProfile'->new($_) };

declare 'RepeatedMysqlProfile',
    as ArrayRef[MysqlProfile()];

coerce 'RepeatedMysqlProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlProfile'->new($_) } @$_ ] };

declare 'MapStringMysqlProfile',
    as HashRef[MysqlProfile()];

declare 'PostgresqlProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlProfile'];

coerce 'PostgresqlProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlProfile'->new($_) };

declare 'RepeatedPostgresqlProfile',
    as ArrayRef[PostgresqlProfile()];

coerce 'RepeatedPostgresqlProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlProfile'->new($_) } @$_ ] };

declare 'MapStringPostgresqlProfile',
    as HashRef[PostgresqlProfile()];

declare 'SqlServerProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerProfile'];

coerce 'SqlServerProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerProfile'->new($_) };

declare 'RepeatedSqlServerProfile',
    as ArrayRef[SqlServerProfile()];

coerce 'RepeatedSqlServerProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerProfile'->new($_) } @$_ ] };

declare 'MapStringSqlServerProfile',
    as HashRef[SqlServerProfile()];

declare 'SalesforceProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SalesforceProfile'];

coerce 'SalesforceProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceProfile'->new($_) };

declare 'RepeatedSalesforceProfile',
    as ArrayRef[SalesforceProfile()];

coerce 'RepeatedSalesforceProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceProfile'->new($_) } @$_ ] };

declare 'MapStringSalesforceProfile',
    as HashRef[SalesforceProfile()];

declare 'UserCredentials',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SalesforceProfile::UserCredentials'];

coerce 'UserCredentials',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceProfile::UserCredentials'->new($_) };

declare 'RepeatedUserCredentials',
    as ArrayRef[UserCredentials()];

coerce 'RepeatedUserCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceProfile::UserCredentials'->new($_) } @$_ ] };

declare 'MapStringUserCredentials',
    as HashRef[UserCredentials()];

declare 'Oauth2ClientCredentials',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SalesforceProfile::Oauth2ClientCredentials'];

coerce 'Oauth2ClientCredentials',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceProfile::Oauth2ClientCredentials'->new($_) };

declare 'RepeatedOauth2ClientCredentials',
    as ArrayRef[Oauth2ClientCredentials()];

coerce 'RepeatedOauth2ClientCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceProfile::Oauth2ClientCredentials'->new($_) } @$_ ] };

declare 'MapStringOauth2ClientCredentials',
    as HashRef[Oauth2ClientCredentials()];

declare 'MongodbProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MongodbProfile'];

coerce 'MongodbProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbProfile'->new($_) };

declare 'RepeatedMongodbProfile',
    as ArrayRef[MongodbProfile()];

coerce 'RepeatedMongodbProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbProfile'->new($_) } @$_ ] };

declare 'MapStringMongodbProfile',
    as HashRef[MongodbProfile()];

declare 'AdditionalOptionsEntry',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MongodbProfile::AdditionalOptionsEntry'];

coerce 'AdditionalOptionsEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbProfile::AdditionalOptionsEntry'->new($_) };

declare 'RepeatedAdditionalOptionsEntry',
    as ArrayRef[AdditionalOptionsEntry()];

coerce 'RepeatedAdditionalOptionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbProfile::AdditionalOptionsEntry'->new($_) } @$_ ] };

declare 'MapStringAdditionalOptionsEntry',
    as HashRef[AdditionalOptionsEntry()];

declare 'HostAddress',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::HostAddress'];

coerce 'HostAddress',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::HostAddress'->new($_) };

declare 'RepeatedHostAddress',
    as ArrayRef[HostAddress()];

coerce 'RepeatedHostAddress',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::HostAddress'->new($_) } @$_ ] };

declare 'MapStringHostAddress',
    as HashRef[HostAddress()];

declare 'SpannerProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SpannerProfile'];

coerce 'SpannerProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerProfile'->new($_) };

declare 'RepeatedSpannerProfile',
    as ArrayRef[SpannerProfile()];

coerce 'RepeatedSpannerProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerProfile'->new($_) } @$_ ] };

declare 'MapStringSpannerProfile',
    as HashRef[SpannerProfile()];

declare 'OauthClientCredentials',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OauthClientCredentials'];

coerce 'OauthClientCredentials',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OauthClientCredentials'->new($_) };

declare 'RepeatedOauthClientCredentials',
    as ArrayRef[OauthClientCredentials()];

coerce 'RepeatedOauthClientCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OauthClientCredentials'->new($_) } @$_ ] };

declare 'MapStringOauthClientCredentials',
    as HashRef[OauthClientCredentials()];

declare 'OauthRefreshTokenCredentials',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OauthRefreshTokenCredentials'];

coerce 'OauthRefreshTokenCredentials',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OauthRefreshTokenCredentials'->new($_) };

declare 'RepeatedOauthRefreshTokenCredentials',
    as ArrayRef[OauthRefreshTokenCredentials()];

coerce 'RepeatedOauthRefreshTokenCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OauthRefreshTokenCredentials'->new($_) } @$_ ] };

declare 'MapStringOauthRefreshTokenCredentials',
    as HashRef[OauthRefreshTokenCredentials()];

declare 'UserPasswordCredentials',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::UserPasswordCredentials'];

coerce 'UserPasswordCredentials',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::UserPasswordCredentials'->new($_) };

declare 'RepeatedUserPasswordCredentials',
    as ArrayRef[UserPasswordCredentials()];

coerce 'RepeatedUserPasswordCredentials',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::UserPasswordCredentials'->new($_) } @$_ ] };

declare 'MapStringUserPasswordCredentials',
    as HashRef[UserPasswordCredentials()];

declare 'SalesforceMarketingCloudProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SalesforceMarketingCloudProfile'];

coerce 'SalesforceMarketingCloudProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceMarketingCloudProfile'->new($_) };

declare 'RepeatedSalesforceMarketingCloudProfile',
    as ArrayRef[SalesforceMarketingCloudProfile()];

coerce 'RepeatedSalesforceMarketingCloudProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceMarketingCloudProfile'->new($_) } @$_ ] };

declare 'MapStringSalesforceMarketingCloudProfile',
    as HashRef[SalesforceMarketingCloudProfile()];

declare 'DataverseProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::DataverseProfile'];

coerce 'DataverseProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::DataverseProfile'->new($_) };

declare 'RepeatedDataverseProfile',
    as ArrayRef[DataverseProfile()];

coerce 'RepeatedDataverseProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::DataverseProfile'->new($_) } @$_ ] };

declare 'MapStringDataverseProfile',
    as HashRef[DataverseProfile()];

declare 'ServiceNowProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::ServiceNowProfile'];

coerce 'ServiceNowProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::ServiceNowProfile'->new($_) };

declare 'RepeatedServiceNowProfile',
    as ArrayRef[ServiceNowProfile()];

coerce 'RepeatedServiceNowProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::ServiceNowProfile'->new($_) } @$_ ] };

declare 'MapStringServiceNowProfile',
    as HashRef[ServiceNowProfile()];

declare 'WorkdayProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::WorkdayProfile'];

coerce 'WorkdayProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::WorkdayProfile'->new($_) };

declare 'RepeatedWorkdayProfile',
    as ArrayRef[WorkdayProfile()];

coerce 'RepeatedWorkdayProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::WorkdayProfile'->new($_) } @$_ ] };

declare 'MapStringWorkdayProfile',
    as HashRef[WorkdayProfile()];

declare 'SrvConnectionFormat',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SrvConnectionFormat'];

coerce 'SrvConnectionFormat',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SrvConnectionFormat'->new($_) };

declare 'RepeatedSrvConnectionFormat',
    as ArrayRef[SrvConnectionFormat()];

coerce 'RepeatedSrvConnectionFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SrvConnectionFormat'->new($_) } @$_ ] };

declare 'MapStringSrvConnectionFormat',
    as HashRef[SrvConnectionFormat()];

declare 'StandardConnectionFormat',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::StandardConnectionFormat'];

coerce 'StandardConnectionFormat',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::StandardConnectionFormat'->new($_) };

declare 'RepeatedStandardConnectionFormat',
    as ArrayRef[StandardConnectionFormat()];

coerce 'RepeatedStandardConnectionFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::StandardConnectionFormat'->new($_) } @$_ ] };

declare 'MapStringStandardConnectionFormat',
    as HashRef[StandardConnectionFormat()];

declare 'GcsProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::GcsProfile'];

coerce 'GcsProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::GcsProfile'->new($_) };

declare 'RepeatedGcsProfile',
    as ArrayRef[GcsProfile()];

coerce 'RepeatedGcsProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::GcsProfile'->new($_) } @$_ ] };

declare 'MapStringGcsProfile',
    as HashRef[GcsProfile()];

declare 'BigQueryProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::BigQueryProfile'];

coerce 'BigQueryProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryProfile'->new($_) };

declare 'RepeatedBigQueryProfile',
    as ArrayRef[BigQueryProfile()];

coerce 'RepeatedBigQueryProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryProfile'->new($_) } @$_ ] };

declare 'MapStringBigQueryProfile',
    as HashRef[BigQueryProfile()];

declare 'StaticServiceIpConnectivity',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::StaticServiceIpConnectivity'];

coerce 'StaticServiceIpConnectivity',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::StaticServiceIpConnectivity'->new($_) };

declare 'RepeatedStaticServiceIpConnectivity',
    as ArrayRef[StaticServiceIpConnectivity()];

coerce 'RepeatedStaticServiceIpConnectivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::StaticServiceIpConnectivity'->new($_) } @$_ ] };

declare 'MapStringStaticServiceIpConnectivity',
    as HashRef[StaticServiceIpConnectivity()];

declare 'ForwardSshTunnelConnectivity',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::ForwardSshTunnelConnectivity'];

coerce 'ForwardSshTunnelConnectivity',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::ForwardSshTunnelConnectivity'->new($_) };

declare 'RepeatedForwardSshTunnelConnectivity',
    as ArrayRef[ForwardSshTunnelConnectivity()];

coerce 'RepeatedForwardSshTunnelConnectivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::ForwardSshTunnelConnectivity'->new($_) } @$_ ] };

declare 'MapStringForwardSshTunnelConnectivity',
    as HashRef[ForwardSshTunnelConnectivity()];

declare 'VpcPeeringConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::VpcPeeringConfig'];

coerce 'VpcPeeringConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::VpcPeeringConfig'->new($_) };

declare 'RepeatedVpcPeeringConfig',
    as ArrayRef[VpcPeeringConfig()];

coerce 'RepeatedVpcPeeringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::VpcPeeringConfig'->new($_) } @$_ ] };

declare 'MapStringVpcPeeringConfig',
    as HashRef[VpcPeeringConfig()];

declare 'PscInterfaceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::PscInterfaceConfig'];

coerce 'PscInterfaceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::PscInterfaceConfig'->new($_) };

declare 'RepeatedPscInterfaceConfig',
    as ArrayRef[PscInterfaceConfig()];

coerce 'RepeatedPscInterfaceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::PscInterfaceConfig'->new($_) } @$_ ] };

declare 'MapStringPscInterfaceConfig',
    as HashRef[PscInterfaceConfig()];

declare 'PrivateConnection',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::PrivateConnection'];

coerce 'PrivateConnection',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::PrivateConnection'->new($_) };

declare 'RepeatedPrivateConnection',
    as ArrayRef[PrivateConnection()];

coerce 'RepeatedPrivateConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::PrivateConnection'->new($_) } @$_ ] };

declare 'MapStringPrivateConnection',
    as HashRef[PrivateConnection()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::PrivateConnection::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::PrivateConnection::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::PrivateConnection::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'PrivateConnectivity',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::PrivateConnectivity'];

coerce 'PrivateConnectivity',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::PrivateConnectivity'->new($_) };

declare 'RepeatedPrivateConnectivity',
    as ArrayRef[PrivateConnectivity()];

coerce 'RepeatedPrivateConnectivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::PrivateConnectivity'->new($_) } @$_ ] };

declare 'MapStringPrivateConnectivity',
    as HashRef[PrivateConnectivity()];

declare 'Route',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::Route'];

coerce 'Route',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::Route'->new($_) };

declare 'RepeatedRoute',
    as ArrayRef[Route()];

coerce 'RepeatedRoute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::Route'->new($_) } @$_ ] };

declare 'MapStringRoute',
    as HashRef[Route()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::Route::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::Route::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::Route::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Secret',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::Secret'];

coerce 'Secret',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::Secret'->new($_) };

declare 'RepeatedSecret',
    as ArrayRef[Secret()];

coerce 'RepeatedSecret',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::Secret'->new($_) } @$_ ] };

declare 'MapStringSecret',
    as HashRef[Secret()];

declare 'MongodbSslConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MongodbSslConfig'];

coerce 'MongodbSslConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbSslConfig'->new($_) };

declare 'RepeatedMongodbSslConfig',
    as ArrayRef[MongodbSslConfig()];

coerce 'RepeatedMongodbSslConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbSslConfig'->new($_) } @$_ ] };

declare 'MapStringMongodbSslConfig',
    as HashRef[MongodbSslConfig()];

declare 'MysqlSslConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MysqlSslConfig'];

coerce 'MysqlSslConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlSslConfig'->new($_) };

declare 'RepeatedMysqlSslConfig',
    as ArrayRef[MysqlSslConfig()];

coerce 'RepeatedMysqlSslConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlSslConfig'->new($_) } @$_ ] };

declare 'MapStringMysqlSslConfig',
    as HashRef[MysqlSslConfig()];

declare 'OracleSslConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleSslConfig'];

coerce 'OracleSslConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSslConfig'->new($_) };

declare 'RepeatedOracleSslConfig',
    as ArrayRef[OracleSslConfig()];

coerce 'RepeatedOracleSslConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSslConfig'->new($_) } @$_ ] };

declare 'MapStringOracleSslConfig',
    as HashRef[OracleSslConfig()];

declare 'SqlServerSslConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSslConfig'];

coerce 'SqlServerSslConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSslConfig'->new($_) };

declare 'RepeatedSqlServerSslConfig',
    as ArrayRef[SqlServerSslConfig()];

coerce 'RepeatedSqlServerSslConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSslConfig'->new($_) } @$_ ] };

declare 'MapStringSqlServerSslConfig',
    as HashRef[SqlServerSslConfig()];

declare 'EncryptionNotEnforced',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSslConfig::EncryptionNotEnforced'];

coerce 'EncryptionNotEnforced',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSslConfig::EncryptionNotEnforced'->new($_) };

declare 'RepeatedEncryptionNotEnforced',
    as ArrayRef[EncryptionNotEnforced()];

coerce 'RepeatedEncryptionNotEnforced',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSslConfig::EncryptionNotEnforced'->new($_) } @$_ ] };

declare 'MapStringEncryptionNotEnforced',
    as HashRef[EncryptionNotEnforced()];

declare 'BasicEncryption',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSslConfig::BasicEncryption'];

coerce 'BasicEncryption',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSslConfig::BasicEncryption'->new($_) };

declare 'RepeatedBasicEncryption',
    as ArrayRef[BasicEncryption()];

coerce 'RepeatedBasicEncryption',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSslConfig::BasicEncryption'->new($_) } @$_ ] };

declare 'MapStringBasicEncryption',
    as HashRef[BasicEncryption()];

declare 'EncryptionAndServerValidation',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSslConfig::EncryptionAndServerValidation'];

coerce 'EncryptionAndServerValidation',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSslConfig::EncryptionAndServerValidation'->new($_) };

declare 'RepeatedEncryptionAndServerValidation',
    as ArrayRef[EncryptionAndServerValidation()];

coerce 'RepeatedEncryptionAndServerValidation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSslConfig::EncryptionAndServerValidation'->new($_) } @$_ ] };

declare 'MapStringEncryptionAndServerValidation',
    as HashRef[EncryptionAndServerValidation()];

declare 'PostgresqlSslConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSslConfig'];

coerce 'PostgresqlSslConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSslConfig'->new($_) };

declare 'RepeatedPostgresqlSslConfig',
    as ArrayRef[PostgresqlSslConfig()];

coerce 'RepeatedPostgresqlSslConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSslConfig'->new($_) } @$_ ] };

declare 'MapStringPostgresqlSslConfig',
    as HashRef[PostgresqlSslConfig()];

declare 'ServerVerification',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSslConfig::ServerVerification'];

coerce 'ServerVerification',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSslConfig::ServerVerification'->new($_) };

declare 'RepeatedServerVerification',
    as ArrayRef[ServerVerification()];

coerce 'RepeatedServerVerification',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSslConfig::ServerVerification'->new($_) } @$_ ] };

declare 'MapStringServerVerification',
    as HashRef[ServerVerification()];

declare 'ServerAndClientVerification',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSslConfig::ServerAndClientVerification'];

coerce 'ServerAndClientVerification',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSslConfig::ServerAndClientVerification'->new($_) };

declare 'RepeatedServerAndClientVerification',
    as ArrayRef[ServerAndClientVerification()];

coerce 'RepeatedServerAndClientVerification',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSslConfig::ServerAndClientVerification'->new($_) } @$_ ] };

declare 'MapStringServerAndClientVerification',
    as HashRef[ServerAndClientVerification()];

declare 'ConnectionProfile',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::ConnectionProfile'];

coerce 'ConnectionProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::ConnectionProfile'->new($_) };

declare 'RepeatedConnectionProfile',
    as ArrayRef[ConnectionProfile()];

coerce 'RepeatedConnectionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::ConnectionProfile'->new($_) } @$_ ] };

declare 'MapStringConnectionProfile',
    as HashRef[ConnectionProfile()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::ConnectionProfile::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::ConnectionProfile::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::ConnectionProfile::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'OracleColumn',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleColumn'];

coerce 'OracleColumn',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleColumn'->new($_) };

declare 'RepeatedOracleColumn',
    as ArrayRef[OracleColumn()];

coerce 'RepeatedOracleColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleColumn'->new($_) } @$_ ] };

declare 'MapStringOracleColumn',
    as HashRef[OracleColumn()];

declare 'OracleTable',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleTable'];

coerce 'OracleTable',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleTable'->new($_) };

declare 'RepeatedOracleTable',
    as ArrayRef[OracleTable()];

coerce 'RepeatedOracleTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleTable'->new($_) } @$_ ] };

declare 'MapStringOracleTable',
    as HashRef[OracleTable()];

declare 'OracleSchema',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleSchema'];

coerce 'OracleSchema',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSchema'->new($_) };

declare 'RepeatedOracleSchema',
    as ArrayRef[OracleSchema()];

coerce 'RepeatedOracleSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSchema'->new($_) } @$_ ] };

declare 'MapStringOracleSchema',
    as HashRef[OracleSchema()];

declare 'OracleRdbms',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleRdbms'];

coerce 'OracleRdbms',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleRdbms'->new($_) };

declare 'RepeatedOracleRdbms',
    as ArrayRef[OracleRdbms()];

coerce 'RepeatedOracleRdbms',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleRdbms'->new($_) } @$_ ] };

declare 'MapStringOracleRdbms',
    as HashRef[OracleRdbms()];

declare 'OracleSourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig'];

coerce 'OracleSourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig'->new($_) };

declare 'RepeatedOracleSourceConfig',
    as ArrayRef[OracleSourceConfig()];

coerce 'RepeatedOracleSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig'->new($_) } @$_ ] };

declare 'MapStringOracleSourceConfig',
    as HashRef[OracleSourceConfig()];

declare 'DropLargeObjects',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::DropLargeObjects'];

coerce 'DropLargeObjects',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::DropLargeObjects'->new($_) };

declare 'RepeatedDropLargeObjects',
    as ArrayRef[DropLargeObjects()];

coerce 'RepeatedDropLargeObjects',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::DropLargeObjects'->new($_) } @$_ ] };

declare 'MapStringDropLargeObjects',
    as HashRef[DropLargeObjects()];

declare 'StreamLargeObjects',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::StreamLargeObjects'];

coerce 'StreamLargeObjects',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::StreamLargeObjects'->new($_) };

declare 'RepeatedStreamLargeObjects',
    as ArrayRef[StreamLargeObjects()];

coerce 'RepeatedStreamLargeObjects',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::StreamLargeObjects'->new($_) } @$_ ] };

declare 'MapStringStreamLargeObjects',
    as HashRef[StreamLargeObjects()];

declare 'LogMiner',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::LogMiner'];

coerce 'LogMiner',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::LogMiner'->new($_) };

declare 'RepeatedLogMiner',
    as ArrayRef[LogMiner()];

coerce 'RepeatedLogMiner',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::LogMiner'->new($_) } @$_ ] };

declare 'MapStringLogMiner',
    as HashRef[LogMiner()];

declare 'BinaryLogParser',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::BinaryLogParser'];

coerce 'BinaryLogParser',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::BinaryLogParser'->new($_) };

declare 'RepeatedBinaryLogParser',
    as ArrayRef[BinaryLogParser()];

coerce 'RepeatedBinaryLogParser',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::BinaryLogParser'->new($_) } @$_ ] };

declare 'MapStringBinaryLogParser',
    as HashRef[BinaryLogParser()];

declare 'OracleAsmLogFileAccess',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::BinaryLogParser::OracleAsmLogFileAccess'];

coerce 'OracleAsmLogFileAccess',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::BinaryLogParser::OracleAsmLogFileAccess'->new($_) };

declare 'RepeatedOracleAsmLogFileAccess',
    as ArrayRef[OracleAsmLogFileAccess()];

coerce 'RepeatedOracleAsmLogFileAccess',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::BinaryLogParser::OracleAsmLogFileAccess'->new($_) } @$_ ] };

declare 'MapStringOracleAsmLogFileAccess',
    as HashRef[OracleAsmLogFileAccess()];

declare 'LogFileDirectories',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::BinaryLogParser::LogFileDirectories'];

coerce 'LogFileDirectories',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::BinaryLogParser::LogFileDirectories'->new($_) };

declare 'RepeatedLogFileDirectories',
    as ArrayRef[LogFileDirectories()];

coerce 'RepeatedLogFileDirectories',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleSourceConfig::BinaryLogParser::LogFileDirectories'->new($_) } @$_ ] };

declare 'MapStringLogFileDirectories',
    as HashRef[LogFileDirectories()];

declare 'PostgresqlColumn',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlColumn'];

coerce 'PostgresqlColumn',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlColumn'->new($_) };

declare 'RepeatedPostgresqlColumn',
    as ArrayRef[PostgresqlColumn()];

coerce 'RepeatedPostgresqlColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlColumn'->new($_) } @$_ ] };

declare 'MapStringPostgresqlColumn',
    as HashRef[PostgresqlColumn()];

declare 'PostgresqlTable',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlTable'];

coerce 'PostgresqlTable',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlTable'->new($_) };

declare 'RepeatedPostgresqlTable',
    as ArrayRef[PostgresqlTable()];

coerce 'RepeatedPostgresqlTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlTable'->new($_) } @$_ ] };

declare 'MapStringPostgresqlTable',
    as HashRef[PostgresqlTable()];

declare 'PostgresqlSchema',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSchema'];

coerce 'PostgresqlSchema',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSchema'->new($_) };

declare 'RepeatedPostgresqlSchema',
    as ArrayRef[PostgresqlSchema()];

coerce 'RepeatedPostgresqlSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSchema'->new($_) } @$_ ] };

declare 'MapStringPostgresqlSchema',
    as HashRef[PostgresqlSchema()];

declare 'PostgresqlRdbms',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlRdbms'];

coerce 'PostgresqlRdbms',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlRdbms'->new($_) };

declare 'RepeatedPostgresqlRdbms',
    as ArrayRef[PostgresqlRdbms()];

coerce 'RepeatedPostgresqlRdbms',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlRdbms'->new($_) } @$_ ] };

declare 'MapStringPostgresqlRdbms',
    as HashRef[PostgresqlRdbms()];

declare 'PostgresqlSourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSourceConfig'];

coerce 'PostgresqlSourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSourceConfig'->new($_) };

declare 'RepeatedPostgresqlSourceConfig',
    as ArrayRef[PostgresqlSourceConfig()];

coerce 'RepeatedPostgresqlSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::PostgresqlSourceConfig'->new($_) } @$_ ] };

declare 'MapStringPostgresqlSourceConfig',
    as HashRef[PostgresqlSourceConfig()];

declare 'SqlServerColumn',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerColumn'];

coerce 'SqlServerColumn',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerColumn'->new($_) };

declare 'RepeatedSqlServerColumn',
    as ArrayRef[SqlServerColumn()];

coerce 'RepeatedSqlServerColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerColumn'->new($_) } @$_ ] };

declare 'MapStringSqlServerColumn',
    as HashRef[SqlServerColumn()];

declare 'SqlServerTable',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerTable'];

coerce 'SqlServerTable',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerTable'->new($_) };

declare 'RepeatedSqlServerTable',
    as ArrayRef[SqlServerTable()];

coerce 'RepeatedSqlServerTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerTable'->new($_) } @$_ ] };

declare 'MapStringSqlServerTable',
    as HashRef[SqlServerTable()];

declare 'SqlServerSchema',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSchema'];

coerce 'SqlServerSchema',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSchema'->new($_) };

declare 'RepeatedSqlServerSchema',
    as ArrayRef[SqlServerSchema()];

coerce 'RepeatedSqlServerSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSchema'->new($_) } @$_ ] };

declare 'MapStringSqlServerSchema',
    as HashRef[SqlServerSchema()];

declare 'SqlServerRdbms',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerRdbms'];

coerce 'SqlServerRdbms',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerRdbms'->new($_) };

declare 'RepeatedSqlServerRdbms',
    as ArrayRef[SqlServerRdbms()];

coerce 'RepeatedSqlServerRdbms',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerRdbms'->new($_) } @$_ ] };

declare 'MapStringSqlServerRdbms',
    as HashRef[SqlServerRdbms()];

declare 'SqlServerSourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSourceConfig'];

coerce 'SqlServerSourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSourceConfig'->new($_) };

declare 'RepeatedSqlServerSourceConfig',
    as ArrayRef[SqlServerSourceConfig()];

coerce 'RepeatedSqlServerSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerSourceConfig'->new($_) } @$_ ] };

declare 'MapStringSqlServerSourceConfig',
    as HashRef[SqlServerSourceConfig()];

declare 'SqlServerTransactionLogs',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerTransactionLogs'];

coerce 'SqlServerTransactionLogs',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerTransactionLogs'->new($_) };

declare 'RepeatedSqlServerTransactionLogs',
    as ArrayRef[SqlServerTransactionLogs()];

coerce 'RepeatedSqlServerTransactionLogs',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerTransactionLogs'->new($_) } @$_ ] };

declare 'MapStringSqlServerTransactionLogs',
    as HashRef[SqlServerTransactionLogs()];

declare 'SqlServerChangeTables',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerChangeTables'];

coerce 'SqlServerChangeTables',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerChangeTables'->new($_) };

declare 'RepeatedSqlServerChangeTables',
    as ArrayRef[SqlServerChangeTables()];

coerce 'RepeatedSqlServerChangeTables',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerChangeTables'->new($_) } @$_ ] };

declare 'MapStringSqlServerChangeTables',
    as HashRef[SqlServerChangeTables()];

declare 'SqlServerDdlConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerChangeTables::SqlServerDdlConfig'];

coerce 'SqlServerDdlConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerChangeTables::SqlServerDdlConfig'->new($_) };

declare 'RepeatedSqlServerDdlConfig',
    as ArrayRef[SqlServerDdlConfig()];

coerce 'RepeatedSqlServerDdlConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerChangeTables::SqlServerDdlConfig'->new($_) } @$_ ] };

declare 'MapStringSqlServerDdlConfig',
    as HashRef[SqlServerDdlConfig()];

declare 'MysqlColumn',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MysqlColumn'];

coerce 'MysqlColumn',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlColumn'->new($_) };

declare 'RepeatedMysqlColumn',
    as ArrayRef[MysqlColumn()];

coerce 'RepeatedMysqlColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlColumn'->new($_) } @$_ ] };

declare 'MapStringMysqlColumn',
    as HashRef[MysqlColumn()];

declare 'MysqlTable',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MysqlTable'];

coerce 'MysqlTable',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlTable'->new($_) };

declare 'RepeatedMysqlTable',
    as ArrayRef[MysqlTable()];

coerce 'RepeatedMysqlTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlTable'->new($_) } @$_ ] };

declare 'MapStringMysqlTable',
    as HashRef[MysqlTable()];

declare 'MysqlDatabase',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MysqlDatabase'];

coerce 'MysqlDatabase',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlDatabase'->new($_) };

declare 'RepeatedMysqlDatabase',
    as ArrayRef[MysqlDatabase()];

coerce 'RepeatedMysqlDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlDatabase'->new($_) } @$_ ] };

declare 'MapStringMysqlDatabase',
    as HashRef[MysqlDatabase()];

declare 'MysqlRdbms',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MysqlRdbms'];

coerce 'MysqlRdbms',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlRdbms'->new($_) };

declare 'RepeatedMysqlRdbms',
    as ArrayRef[MysqlRdbms()];

coerce 'RepeatedMysqlRdbms',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlRdbms'->new($_) } @$_ ] };

declare 'MapStringMysqlRdbms',
    as HashRef[MysqlRdbms()];

declare 'MysqlSourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MysqlSourceConfig'];

coerce 'MysqlSourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlSourceConfig'->new($_) };

declare 'RepeatedMysqlSourceConfig',
    as ArrayRef[MysqlSourceConfig()];

coerce 'RepeatedMysqlSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlSourceConfig'->new($_) } @$_ ] };

declare 'MapStringMysqlSourceConfig',
    as HashRef[MysqlSourceConfig()];

declare 'BinaryLogPosition',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MysqlSourceConfig::BinaryLogPosition'];

coerce 'BinaryLogPosition',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlSourceConfig::BinaryLogPosition'->new($_) };

declare 'RepeatedBinaryLogPosition',
    as ArrayRef[BinaryLogPosition()];

coerce 'RepeatedBinaryLogPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlSourceConfig::BinaryLogPosition'->new($_) } @$_ ] };

declare 'MapStringBinaryLogPosition',
    as HashRef[BinaryLogPosition()];

declare 'Gtid',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MysqlSourceConfig::Gtid'];

coerce 'Gtid',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlSourceConfig::Gtid'->new($_) };

declare 'RepeatedGtid',
    as ArrayRef[Gtid()];

coerce 'RepeatedGtid',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlSourceConfig::Gtid'->new($_) } @$_ ] };

declare 'MapStringGtid',
    as HashRef[Gtid()];

declare 'SalesforceSourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SalesforceSourceConfig'];

coerce 'SalesforceSourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceSourceConfig'->new($_) };

declare 'RepeatedSalesforceSourceConfig',
    as ArrayRef[SalesforceSourceConfig()];

coerce 'RepeatedSalesforceSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceSourceConfig'->new($_) } @$_ ] };

declare 'MapStringSalesforceSourceConfig',
    as HashRef[SalesforceSourceConfig()];

declare 'SalesforceOrg',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SalesforceOrg'];

coerce 'SalesforceOrg',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceOrg'->new($_) };

declare 'RepeatedSalesforceOrg',
    as ArrayRef[SalesforceOrg()];

coerce 'RepeatedSalesforceOrg',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceOrg'->new($_) } @$_ ] };

declare 'MapStringSalesforceOrg',
    as HashRef[SalesforceOrg()];

declare 'SalesforceObject',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SalesforceObject'];

coerce 'SalesforceObject',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceObject'->new($_) };

declare 'RepeatedSalesforceObject',
    as ArrayRef[SalesforceObject()];

coerce 'RepeatedSalesforceObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceObject'->new($_) } @$_ ] };

declare 'MapStringSalesforceObject',
    as HashRef[SalesforceObject()];

declare 'SalesforceField',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SalesforceField'];

coerce 'SalesforceField',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceField'->new($_) };

declare 'RepeatedSalesforceField',
    as ArrayRef[SalesforceField()];

coerce 'RepeatedSalesforceField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceField'->new($_) } @$_ ] };

declare 'MapStringSalesforceField',
    as HashRef[SalesforceField()];

declare 'MongodbSourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MongodbSourceConfig'];

coerce 'MongodbSourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbSourceConfig'->new($_) };

declare 'RepeatedMongodbSourceConfig',
    as ArrayRef[MongodbSourceConfig()];

coerce 'RepeatedMongodbSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbSourceConfig'->new($_) } @$_ ] };

declare 'MapStringMongodbSourceConfig',
    as HashRef[MongodbSourceConfig()];

declare 'MongodbCluster',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MongodbCluster'];

coerce 'MongodbCluster',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbCluster'->new($_) };

declare 'RepeatedMongodbCluster',
    as ArrayRef[MongodbCluster()];

coerce 'RepeatedMongodbCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbCluster'->new($_) } @$_ ] };

declare 'MapStringMongodbCluster',
    as HashRef[MongodbCluster()];

declare 'MongodbDatabase',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MongodbDatabase'];

coerce 'MongodbDatabase',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbDatabase'->new($_) };

declare 'RepeatedMongodbDatabase',
    as ArrayRef[MongodbDatabase()];

coerce 'RepeatedMongodbDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbDatabase'->new($_) } @$_ ] };

declare 'MapStringMongodbDatabase',
    as HashRef[MongodbDatabase()];

declare 'MongodbCollection',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MongodbCollection'];

coerce 'MongodbCollection',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbCollection'->new($_) };

declare 'RepeatedMongodbCollection',
    as ArrayRef[MongodbCollection()];

coerce 'RepeatedMongodbCollection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbCollection'->new($_) } @$_ ] };

declare 'MapStringMongodbCollection',
    as HashRef[MongodbCollection()];

declare 'MongodbField',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MongodbField'];

coerce 'MongodbField',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbField'->new($_) };

declare 'RepeatedMongodbField',
    as ArrayRef[MongodbField()];

coerce 'RepeatedMongodbField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbField'->new($_) } @$_ ] };

declare 'MapStringMongodbField',
    as HashRef[MongodbField()];

declare 'SpannerSourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SpannerSourceConfig'];

coerce 'SpannerSourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerSourceConfig'->new($_) };

declare 'RepeatedSpannerSourceConfig',
    as ArrayRef[SpannerSourceConfig()];

coerce 'RepeatedSpannerSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerSourceConfig'->new($_) } @$_ ] };

declare 'MapStringSpannerSourceConfig',
    as HashRef[SpannerSourceConfig()];

declare 'SpannerRpcPriority',
    as (Int | Str);

declare 'SpannerDatabase',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SpannerDatabase'];

coerce 'SpannerDatabase',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerDatabase'->new($_) };

declare 'RepeatedSpannerDatabase',
    as ArrayRef[SpannerDatabase()];

coerce 'RepeatedSpannerDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerDatabase'->new($_) } @$_ ] };

declare 'MapStringSpannerDatabase',
    as HashRef[SpannerDatabase()];

declare 'SpannerSchema',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SpannerSchema'];

coerce 'SpannerSchema',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerSchema'->new($_) };

declare 'RepeatedSpannerSchema',
    as ArrayRef[SpannerSchema()];

coerce 'RepeatedSpannerSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerSchema'->new($_) } @$_ ] };

declare 'MapStringSpannerSchema',
    as HashRef[SpannerSchema()];

declare 'SpannerTable',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SpannerTable'];

coerce 'SpannerTable',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerTable'->new($_) };

declare 'RepeatedSpannerTable',
    as ArrayRef[SpannerTable()];

coerce 'RepeatedSpannerTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerTable'->new($_) } @$_ ] };

declare 'MapStringSpannerTable',
    as HashRef[SpannerTable()];

declare 'SpannerColumn',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SpannerColumn'];

coerce 'SpannerColumn',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerColumn'->new($_) };

declare 'RepeatedSpannerColumn',
    as ArrayRef[SpannerColumn()];

coerce 'RepeatedSpannerColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerColumn'->new($_) } @$_ ] };

declare 'MapStringSpannerColumn',
    as HashRef[SpannerColumn()];

declare 'DataverseSourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::DataverseSourceConfig'];

coerce 'DataverseSourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::DataverseSourceConfig'->new($_) };

declare 'RepeatedDataverseSourceConfig',
    as ArrayRef[DataverseSourceConfig()];

coerce 'RepeatedDataverseSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::DataverseSourceConfig'->new($_) } @$_ ] };

declare 'MapStringDataverseSourceConfig',
    as HashRef[DataverseSourceConfig()];

declare 'SalesforceMarketingCloudSourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SalesforceMarketingCloudSourceConfig'];

coerce 'SalesforceMarketingCloudSourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceMarketingCloudSourceConfig'->new($_) };

declare 'RepeatedSalesforceMarketingCloudSourceConfig',
    as ArrayRef[SalesforceMarketingCloudSourceConfig()];

coerce 'RepeatedSalesforceMarketingCloudSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SalesforceMarketingCloudSourceConfig'->new($_) } @$_ ] };

declare 'MapStringSalesforceMarketingCloudSourceConfig',
    as HashRef[SalesforceMarketingCloudSourceConfig()];

declare 'ServiceNowSourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::ServiceNowSourceConfig'];

coerce 'ServiceNowSourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::ServiceNowSourceConfig'->new($_) };

declare 'RepeatedServiceNowSourceConfig',
    as ArrayRef[ServiceNowSourceConfig()];

coerce 'RepeatedServiceNowSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::ServiceNowSourceConfig'->new($_) } @$_ ] };

declare 'MapStringServiceNowSourceConfig',
    as HashRef[ServiceNowSourceConfig()];

declare 'WorkdaySourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::WorkdaySourceConfig'];

coerce 'WorkdaySourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::WorkdaySourceConfig'->new($_) };

declare 'RepeatedWorkdaySourceConfig',
    as ArrayRef[WorkdaySourceConfig()];

coerce 'RepeatedWorkdaySourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::WorkdaySourceConfig'->new($_) } @$_ ] };

declare 'MapStringWorkdaySourceConfig',
    as HashRef[WorkdaySourceConfig()];

declare 'SourceCatalog',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SourceCatalog'];

coerce 'SourceCatalog',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceCatalog'->new($_) };

declare 'RepeatedSourceCatalog',
    as ArrayRef[SourceCatalog()];

coerce 'RepeatedSourceCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceCatalog'->new($_) } @$_ ] };

declare 'MapStringSourceCatalog',
    as HashRef[SourceCatalog()];

declare 'SourceObject',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SourceObject'];

coerce 'SourceObject',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObject'->new($_) };

declare 'RepeatedSourceObject',
    as ArrayRef[SourceObject()];

coerce 'RepeatedSourceObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObject'->new($_) } @$_ ] };

declare 'MapStringSourceObject',
    as HashRef[SourceObject()];

declare 'SourceProperty',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SourceProperty'];

coerce 'SourceProperty',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceProperty'->new($_) };

declare 'RepeatedSourceProperty',
    as ArrayRef[SourceProperty()];

coerce 'RepeatedSourceProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceProperty'->new($_) } @$_ ] };

declare 'MapStringSourceProperty',
    as HashRef[SourceProperty()];

declare 'SourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SourceConfig'];

coerce 'SourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceConfig'->new($_) };

declare 'RepeatedSourceConfig',
    as ArrayRef[SourceConfig()];

coerce 'RepeatedSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceConfig'->new($_) } @$_ ] };

declare 'MapStringSourceConfig',
    as HashRef[SourceConfig()];

declare 'AvroFileFormat',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::AvroFileFormat'];

coerce 'AvroFileFormat',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::AvroFileFormat'->new($_) };

declare 'RepeatedAvroFileFormat',
    as ArrayRef[AvroFileFormat()];

coerce 'RepeatedAvroFileFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::AvroFileFormat'->new($_) } @$_ ] };

declare 'MapStringAvroFileFormat',
    as HashRef[AvroFileFormat()];

declare 'JsonFileFormat',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::JsonFileFormat'];

coerce 'JsonFileFormat',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::JsonFileFormat'->new($_) };

declare 'RepeatedJsonFileFormat',
    as ArrayRef[JsonFileFormat()];

coerce 'RepeatedJsonFileFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::JsonFileFormat'->new($_) } @$_ ] };

declare 'MapStringJsonFileFormat',
    as HashRef[JsonFileFormat()];

declare 'SchemaFileFormat',
    as (Int | Str);

declare 'JsonCompression',
    as (Int | Str);

declare 'BigQueryClustering',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::BigQueryClustering'];

coerce 'BigQueryClustering',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryClustering'->new($_) };

declare 'RepeatedBigQueryClustering',
    as ArrayRef[BigQueryClustering()];

coerce 'RepeatedBigQueryClustering',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryClustering'->new($_) } @$_ ] };

declare 'MapStringBigQueryClustering',
    as HashRef[BigQueryClustering()];

declare 'IngestionTimePartition',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::IngestionTimePartition'];

coerce 'IngestionTimePartition',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::IngestionTimePartition'->new($_) };

declare 'RepeatedIngestionTimePartition',
    as ArrayRef[IngestionTimePartition()];

coerce 'RepeatedIngestionTimePartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::IngestionTimePartition'->new($_) } @$_ ] };

declare 'MapStringIngestionTimePartition',
    as HashRef[IngestionTimePartition()];

declare 'TimeUnitPartition',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::TimeUnitPartition'];

coerce 'TimeUnitPartition',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::TimeUnitPartition'->new($_) };

declare 'RepeatedTimeUnitPartition',
    as ArrayRef[TimeUnitPartition()];

coerce 'RepeatedTimeUnitPartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::TimeUnitPartition'->new($_) } @$_ ] };

declare 'MapStringTimeUnitPartition',
    as HashRef[TimeUnitPartition()];

declare 'IntegerRangePartition',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::IntegerRangePartition'];

coerce 'IntegerRangePartition',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::IntegerRangePartition'->new($_) };

declare 'RepeatedIntegerRangePartition',
    as ArrayRef[IntegerRangePartition()];

coerce 'RepeatedIntegerRangePartition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::IntegerRangePartition'->new($_) } @$_ ] };

declare 'MapStringIntegerRangePartition',
    as HashRef[IntegerRangePartition()];

declare 'BigQueryPartitioning',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::BigQueryPartitioning'];

coerce 'BigQueryPartitioning',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryPartitioning'->new($_) };

declare 'RepeatedBigQueryPartitioning',
    as ArrayRef[BigQueryPartitioning()];

coerce 'RepeatedBigQueryPartitioning',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryPartitioning'->new($_) } @$_ ] };

declare 'MapStringBigQueryPartitioning',
    as HashRef[BigQueryPartitioning()];

declare 'GcsDestinationConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::GcsDestinationConfig'];

coerce 'GcsDestinationConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::GcsDestinationConfig'->new($_) };

declare 'RepeatedGcsDestinationConfig',
    as ArrayRef[GcsDestinationConfig()];

coerce 'RepeatedGcsDestinationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::GcsDestinationConfig'->new($_) } @$_ ] };

declare 'MapStringGcsDestinationConfig',
    as HashRef[GcsDestinationConfig()];

declare 'BigQueryDestinationConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig'];

coerce 'BigQueryDestinationConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig'->new($_) };

declare 'RepeatedBigQueryDestinationConfig',
    as ArrayRef[BigQueryDestinationConfig()];

coerce 'RepeatedBigQueryDestinationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig'->new($_) } @$_ ] };

declare 'MapStringBigQueryDestinationConfig',
    as HashRef[BigQueryDestinationConfig()];

declare 'SingleTargetDataset',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::SingleTargetDataset'];

coerce 'SingleTargetDataset',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::SingleTargetDataset'->new($_) };

declare 'RepeatedSingleTargetDataset',
    as ArrayRef[SingleTargetDataset()];

coerce 'RepeatedSingleTargetDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::SingleTargetDataset'->new($_) } @$_ ] };

declare 'MapStringSingleTargetDataset',
    as HashRef[SingleTargetDataset()];

declare 'SourceHierarchyDatasets',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::SourceHierarchyDatasets'];

coerce 'SourceHierarchyDatasets',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::SourceHierarchyDatasets'->new($_) };

declare 'RepeatedSourceHierarchyDatasets',
    as ArrayRef[SourceHierarchyDatasets()];

coerce 'RepeatedSourceHierarchyDatasets',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::SourceHierarchyDatasets'->new($_) } @$_ ] };

declare 'MapStringSourceHierarchyDatasets',
    as HashRef[SourceHierarchyDatasets()];

declare 'DatasetTemplate',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::SourceHierarchyDatasets::DatasetTemplate'];

coerce 'DatasetTemplate',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::SourceHierarchyDatasets::DatasetTemplate'->new($_) };

declare 'RepeatedDatasetTemplate',
    as ArrayRef[DatasetTemplate()];

coerce 'RepeatedDatasetTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::SourceHierarchyDatasets::DatasetTemplate'->new($_) } @$_ ] };

declare 'MapStringDatasetTemplate',
    as HashRef[DatasetTemplate()];

declare 'BlmtConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::BlmtConfig'];

coerce 'BlmtConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::BlmtConfig'->new($_) };

declare 'RepeatedBlmtConfig',
    as ArrayRef[BlmtConfig()];

coerce 'RepeatedBlmtConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::BlmtConfig'->new($_) } @$_ ] };

declare 'MapStringBlmtConfig',
    as HashRef[BlmtConfig()];

declare 'FileFormat',
    as (Int | Str);

declare 'TableFormat',
    as (Int | Str);

declare 'AppendOnly',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::AppendOnly'];

coerce 'AppendOnly',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::AppendOnly'->new($_) };

declare 'RepeatedAppendOnly',
    as ArrayRef[AppendOnly()];

coerce 'RepeatedAppendOnly',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::AppendOnly'->new($_) } @$_ ] };

declare 'MapStringAppendOnly',
    as HashRef[AppendOnly()];

declare 'Merge',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::Merge'];

coerce 'Merge',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::Merge'->new($_) };

declare 'RepeatedMerge',
    as ArrayRef[Merge()];

coerce 'RepeatedMerge',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::BigQueryDestinationConfig::Merge'->new($_) } @$_ ] };

declare 'MapStringMerge',
    as HashRef[Merge()];

declare 'DestinationConfig',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::DestinationConfig'];

coerce 'DestinationConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::DestinationConfig'->new($_) };

declare 'RepeatedDestinationConfig',
    as ArrayRef[DestinationConfig()];

coerce 'RepeatedDestinationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::DestinationConfig'->new($_) } @$_ ] };

declare 'MapStringDestinationConfig',
    as HashRef[DestinationConfig()];

declare 'Stream',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::Stream'];

coerce 'Stream',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream'->new($_) };

declare 'RepeatedStream',
    as ArrayRef[Stream()];

coerce 'RepeatedStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream'->new($_) } @$_ ] };

declare 'MapStringStream',
    as HashRef[Stream()];

declare 'State',
    as (Int | Str);

declare 'BackfillAllStrategy',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::Stream::BackfillAllStrategy'];

coerce 'BackfillAllStrategy',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream::BackfillAllStrategy'->new($_) };

declare 'RepeatedBackfillAllStrategy',
    as ArrayRef[BackfillAllStrategy()];

coerce 'RepeatedBackfillAllStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream::BackfillAllStrategy'->new($_) } @$_ ] };

declare 'MapStringBackfillAllStrategy',
    as HashRef[BackfillAllStrategy()];

declare 'BackfillNoneStrategy',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::Stream::BackfillNoneStrategy'];

coerce 'BackfillNoneStrategy',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream::BackfillNoneStrategy'->new($_) };

declare 'RepeatedBackfillNoneStrategy',
    as ArrayRef[BackfillNoneStrategy()];

coerce 'RepeatedBackfillNoneStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream::BackfillNoneStrategy'->new($_) } @$_ ] };

declare 'MapStringBackfillNoneStrategy',
    as HashRef[BackfillNoneStrategy()];

declare 'RuleSet',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::Stream::RuleSet'];

coerce 'RuleSet',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream::RuleSet'->new($_) };

declare 'RepeatedRuleSet',
    as ArrayRef[RuleSet()];

coerce 'RepeatedRuleSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream::RuleSet'->new($_) } @$_ ] };

declare 'MapStringRuleSet',
    as HashRef[RuleSet()];

declare 'ObjectFilter',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::Stream::RuleSet::ObjectFilter'];

coerce 'ObjectFilter',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream::RuleSet::ObjectFilter'->new($_) };

declare 'RepeatedObjectFilter',
    as ArrayRef[ObjectFilter()];

coerce 'RepeatedObjectFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream::RuleSet::ObjectFilter'->new($_) } @$_ ] };

declare 'MapStringObjectFilter',
    as HashRef[ObjectFilter()];

declare 'CustomizationRule',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::Stream::RuleSet::CustomizationRule'];

coerce 'CustomizationRule',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream::RuleSet::CustomizationRule'->new($_) };

declare 'RepeatedCustomizationRule',
    as ArrayRef[CustomizationRule()];

coerce 'RepeatedCustomizationRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream::RuleSet::CustomizationRule'->new($_) } @$_ ] };

declare 'MapStringCustomizationRule',
    as HashRef[CustomizationRule()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::Stream::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::Stream::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'StreamObject',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::StreamObject'];

coerce 'StreamObject',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::StreamObject'->new($_) };

declare 'RepeatedStreamObject',
    as ArrayRef[StreamObject()];

coerce 'RepeatedStreamObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::StreamObject'->new($_) } @$_ ] };

declare 'MapStringStreamObject',
    as HashRef[StreamObject()];

declare 'SourceObjectIdentifier',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier'];

coerce 'SourceObjectIdentifier',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier'->new($_) };

declare 'RepeatedSourceObjectIdentifier',
    as ArrayRef[SourceObjectIdentifier()];

coerce 'RepeatedSourceObjectIdentifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier'->new($_) } @$_ ] };

declare 'MapStringSourceObjectIdentifier',
    as HashRef[SourceObjectIdentifier()];

declare 'OracleObjectIdentifier',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::OracleObjectIdentifier'];

coerce 'OracleObjectIdentifier',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::OracleObjectIdentifier'->new($_) };

declare 'RepeatedOracleObjectIdentifier',
    as ArrayRef[OracleObjectIdentifier()];

coerce 'RepeatedOracleObjectIdentifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::OracleObjectIdentifier'->new($_) } @$_ ] };

declare 'MapStringOracleObjectIdentifier',
    as HashRef[OracleObjectIdentifier()];

declare 'PostgresqlObjectIdentifier',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::PostgresqlObjectIdentifier'];

coerce 'PostgresqlObjectIdentifier',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::PostgresqlObjectIdentifier'->new($_) };

declare 'RepeatedPostgresqlObjectIdentifier',
    as ArrayRef[PostgresqlObjectIdentifier()];

coerce 'RepeatedPostgresqlObjectIdentifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::PostgresqlObjectIdentifier'->new($_) } @$_ ] };

declare 'MapStringPostgresqlObjectIdentifier',
    as HashRef[PostgresqlObjectIdentifier()];

declare 'MysqlObjectIdentifier',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::MysqlObjectIdentifier'];

coerce 'MysqlObjectIdentifier',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::MysqlObjectIdentifier'->new($_) };

declare 'RepeatedMysqlObjectIdentifier',
    as ArrayRef[MysqlObjectIdentifier()];

coerce 'RepeatedMysqlObjectIdentifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::MysqlObjectIdentifier'->new($_) } @$_ ] };

declare 'MapStringMysqlObjectIdentifier',
    as HashRef[MysqlObjectIdentifier()];

declare 'SqlServerObjectIdentifier',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::SqlServerObjectIdentifier'];

coerce 'SqlServerObjectIdentifier',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::SqlServerObjectIdentifier'->new($_) };

declare 'RepeatedSqlServerObjectIdentifier',
    as ArrayRef[SqlServerObjectIdentifier()];

coerce 'RepeatedSqlServerObjectIdentifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::SqlServerObjectIdentifier'->new($_) } @$_ ] };

declare 'MapStringSqlServerObjectIdentifier',
    as HashRef[SqlServerObjectIdentifier()];

declare 'SalesforceObjectIdentifier',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::SalesforceObjectIdentifier'];

coerce 'SalesforceObjectIdentifier',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::SalesforceObjectIdentifier'->new($_) };

declare 'RepeatedSalesforceObjectIdentifier',
    as ArrayRef[SalesforceObjectIdentifier()];

coerce 'RepeatedSalesforceObjectIdentifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::SalesforceObjectIdentifier'->new($_) } @$_ ] };

declare 'MapStringSalesforceObjectIdentifier',
    as HashRef[SalesforceObjectIdentifier()];

declare 'MongodbObjectIdentifier',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::MongodbObjectIdentifier'];

coerce 'MongodbObjectIdentifier',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::MongodbObjectIdentifier'->new($_) };

declare 'RepeatedMongodbObjectIdentifier',
    as ArrayRef[MongodbObjectIdentifier()];

coerce 'RepeatedMongodbObjectIdentifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::MongodbObjectIdentifier'->new($_) } @$_ ] };

declare 'MapStringMongodbObjectIdentifier',
    as HashRef[MongodbObjectIdentifier()];

declare 'SpannerObjectIdentifier',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::SpannerObjectIdentifier'];

coerce 'SpannerObjectIdentifier',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::SpannerObjectIdentifier'->new($_) };

declare 'RepeatedSpannerObjectIdentifier',
    as ArrayRef[SpannerObjectIdentifier()];

coerce 'RepeatedSpannerObjectIdentifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SourceObjectIdentifier::SpannerObjectIdentifier'->new($_) } @$_ ] };

declare 'MapStringSpannerObjectIdentifier',
    as HashRef[SpannerObjectIdentifier()];

declare 'BackfillJob',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::BackfillJob'];

coerce 'BackfillJob',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::BackfillJob'->new($_) };

declare 'RepeatedBackfillJob',
    as ArrayRef[BackfillJob()];

coerce 'RepeatedBackfillJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::BackfillJob'->new($_) } @$_ ] };

declare 'MapStringBackfillJob',
    as HashRef[BackfillJob()];

declare 'State',
    as (Int | Str);

declare 'Trigger',
    as (Int | Str);

declare 'EventFilter',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::EventFilter'];

coerce 'EventFilter',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::EventFilter'->new($_) };

declare 'RepeatedEventFilter',
    as ArrayRef[EventFilter()];

coerce 'RepeatedEventFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::EventFilter'->new($_) } @$_ ] };

declare 'MapStringEventFilter',
    as HashRef[EventFilter()];

declare 'Error',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::Error'];

coerce 'Error',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::Error'->new($_) };

declare 'RepeatedError',
    as ArrayRef[Error()];

coerce 'RepeatedError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::Error'->new($_) } @$_ ] };

declare 'MapStringError',
    as HashRef[Error()];

declare 'DetailsEntry',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::Error::DetailsEntry'];

coerce 'DetailsEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::Error::DetailsEntry'->new($_) };

declare 'RepeatedDetailsEntry',
    as ArrayRef[DetailsEntry()];

coerce 'RepeatedDetailsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::Error::DetailsEntry'->new($_) } @$_ ] };

declare 'MapStringDetailsEntry',
    as HashRef[DetailsEntry()];

declare 'ValidationResult',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::ValidationResult'];

coerce 'ValidationResult',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::ValidationResult'->new($_) };

declare 'RepeatedValidationResult',
    as ArrayRef[ValidationResult()];

coerce 'RepeatedValidationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::ValidationResult'->new($_) } @$_ ] };

declare 'MapStringValidationResult',
    as HashRef[ValidationResult()];

declare 'Validation',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::Validation'];

coerce 'Validation',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::Validation'->new($_) };

declare 'RepeatedValidation',
    as ArrayRef[Validation()];

coerce 'RepeatedValidation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::Validation'->new($_) } @$_ ] };

declare 'MapStringValidation',
    as HashRef[Validation()];

declare 'State',
    as (Int | Str);

declare 'ValidationMessage',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::ValidationMessage'];

coerce 'ValidationMessage',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::ValidationMessage'->new($_) };

declare 'RepeatedValidationMessage',
    as ArrayRef[ValidationMessage()];

coerce 'RepeatedValidationMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::ValidationMessage'->new($_) } @$_ ] };

declare 'MapStringValidationMessage',
    as HashRef[ValidationMessage()];

declare 'Level',
    as (Int | Str);

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::ValidationMessage::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::ValidationMessage::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::ValidationMessage::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'CdcStrategy',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::CdcStrategy'];

coerce 'CdcStrategy',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::CdcStrategy'->new($_) };

declare 'RepeatedCdcStrategy',
    as ArrayRef[CdcStrategy()];

coerce 'RepeatedCdcStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::CdcStrategy'->new($_) } @$_ ] };

declare 'MapStringCdcStrategy',
    as HashRef[CdcStrategy()];

declare 'MostRecentStartPosition',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::CdcStrategy::MostRecentStartPosition'];

coerce 'MostRecentStartPosition',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::CdcStrategy::MostRecentStartPosition'->new($_) };

declare 'RepeatedMostRecentStartPosition',
    as ArrayRef[MostRecentStartPosition()];

coerce 'RepeatedMostRecentStartPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::CdcStrategy::MostRecentStartPosition'->new($_) } @$_ ] };

declare 'MapStringMostRecentStartPosition',
    as HashRef[MostRecentStartPosition()];

declare 'NextAvailableStartPosition',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::CdcStrategy::NextAvailableStartPosition'];

coerce 'NextAvailableStartPosition',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::CdcStrategy::NextAvailableStartPosition'->new($_) };

declare 'RepeatedNextAvailableStartPosition',
    as ArrayRef[NextAvailableStartPosition()];

coerce 'RepeatedNextAvailableStartPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::CdcStrategy::NextAvailableStartPosition'->new($_) } @$_ ] };

declare 'MapStringNextAvailableStartPosition',
    as HashRef[NextAvailableStartPosition()];

declare 'SpecificStartPosition',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::CdcStrategy::SpecificStartPosition'];

coerce 'SpecificStartPosition',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::CdcStrategy::SpecificStartPosition'->new($_) };

declare 'RepeatedSpecificStartPosition',
    as ArrayRef[SpecificStartPosition()];

coerce 'RepeatedSpecificStartPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::CdcStrategy::SpecificStartPosition'->new($_) } @$_ ] };

declare 'MapStringSpecificStartPosition',
    as HashRef[SpecificStartPosition()];

declare 'SqlServerLsnPosition',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SqlServerLsnPosition'];

coerce 'SqlServerLsnPosition',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerLsnPosition'->new($_) };

declare 'RepeatedSqlServerLsnPosition',
    as ArrayRef[SqlServerLsnPosition()];

coerce 'RepeatedSqlServerLsnPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SqlServerLsnPosition'->new($_) } @$_ ] };

declare 'MapStringSqlServerLsnPosition',
    as HashRef[SqlServerLsnPosition()];

declare 'OracleScnPosition',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::OracleScnPosition'];

coerce 'OracleScnPosition',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleScnPosition'->new($_) };

declare 'RepeatedOracleScnPosition',
    as ArrayRef[OracleScnPosition()];

coerce 'RepeatedOracleScnPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::OracleScnPosition'->new($_) } @$_ ] };

declare 'MapStringOracleScnPosition',
    as HashRef[OracleScnPosition()];

declare 'MysqlLogPosition',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MysqlLogPosition'];

coerce 'MysqlLogPosition',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlLogPosition'->new($_) };

declare 'RepeatedMysqlLogPosition',
    as ArrayRef[MysqlLogPosition()];

coerce 'RepeatedMysqlLogPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlLogPosition'->new($_) } @$_ ] };

declare 'MapStringMysqlLogPosition',
    as HashRef[MysqlLogPosition()];

declare 'MysqlGtidPosition',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MysqlGtidPosition'];

coerce 'MysqlGtidPosition',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlGtidPosition'->new($_) };

declare 'RepeatedMysqlGtidPosition',
    as ArrayRef[MysqlGtidPosition()];

coerce 'RepeatedMysqlGtidPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MysqlGtidPosition'->new($_) } @$_ ] };

declare 'MapStringMysqlGtidPosition',
    as HashRef[MysqlGtidPosition()];

declare 'MongodbChangeStreamPosition',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::MongodbChangeStreamPosition'];

coerce 'MongodbChangeStreamPosition',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbChangeStreamPosition'->new($_) };

declare 'RepeatedMongodbChangeStreamPosition',
    as ArrayRef[MongodbChangeStreamPosition()];

coerce 'RepeatedMongodbChangeStreamPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::MongodbChangeStreamPosition'->new($_) } @$_ ] };

declare 'MapStringMongodbChangeStreamPosition',
    as HashRef[MongodbChangeStreamPosition()];

declare 'SpannerChangeStreamPosition',
    as InstanceOf['Google::Cloud::Datastream::V1::DatastreamResources::SpannerChangeStreamPosition'];

coerce 'SpannerChangeStreamPosition',
    from HashRef, via { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerChangeStreamPosition'->new($_) };

declare 'RepeatedSpannerChangeStreamPosition',
    as ArrayRef[SpannerChangeStreamPosition()];

coerce 'RepeatedSpannerChangeStreamPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1::DatastreamResources::SpannerChangeStreamPosition'->new($_) } @$_ ] };

declare 'MapStringSpannerChangeStreamPosition',
    as HashRef[SpannerChangeStreamPosition()];

1;

__END__

=head1 NAME

Google::Cloud::Datastream::V1::DatastreamResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
