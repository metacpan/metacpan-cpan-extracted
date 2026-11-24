package Google::Cloud::Datastream::V1alpha1::DatastreamResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GcsFileFormat',
    as (Int | Str);

declare 'SchemaFileFormat',
    as (Int | Str);

declare 'OracleProfile',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleProfile'];

coerce 'OracleProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleProfile'->new($_) };

declare 'RepeatedOracleProfile',
    as ArrayRef[OracleProfile()];

coerce 'RepeatedOracleProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleProfile'->new($_) } @$_ ] };

declare 'MapStringOracleProfile',
    as HashRef[OracleProfile()];

declare 'ConnectionAttributesEntry',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleProfile::ConnectionAttributesEntry'];

coerce 'ConnectionAttributesEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleProfile::ConnectionAttributesEntry'->new($_) };

declare 'RepeatedConnectionAttributesEntry',
    as ArrayRef[ConnectionAttributesEntry()];

coerce 'RepeatedConnectionAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleProfile::ConnectionAttributesEntry'->new($_) } @$_ ] };

declare 'MapStringConnectionAttributesEntry',
    as HashRef[ConnectionAttributesEntry()];

declare 'MysqlProfile',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlProfile'];

coerce 'MysqlProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlProfile'->new($_) };

declare 'RepeatedMysqlProfile',
    as ArrayRef[MysqlProfile()];

coerce 'RepeatedMysqlProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlProfile'->new($_) } @$_ ] };

declare 'MapStringMysqlProfile',
    as HashRef[MysqlProfile()];

declare 'GcsProfile',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::GcsProfile'];

coerce 'GcsProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::GcsProfile'->new($_) };

declare 'RepeatedGcsProfile',
    as ArrayRef[GcsProfile()];

coerce 'RepeatedGcsProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::GcsProfile'->new($_) } @$_ ] };

declare 'MapStringGcsProfile',
    as HashRef[GcsProfile()];

declare 'NoConnectivitySettings',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::NoConnectivitySettings'];

coerce 'NoConnectivitySettings',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::NoConnectivitySettings'->new($_) };

declare 'RepeatedNoConnectivitySettings',
    as ArrayRef[NoConnectivitySettings()];

coerce 'RepeatedNoConnectivitySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::NoConnectivitySettings'->new($_) } @$_ ] };

declare 'MapStringNoConnectivitySettings',
    as HashRef[NoConnectivitySettings()];

declare 'StaticServiceIpConnectivity',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::StaticServiceIpConnectivity'];

coerce 'StaticServiceIpConnectivity',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::StaticServiceIpConnectivity'->new($_) };

declare 'RepeatedStaticServiceIpConnectivity',
    as ArrayRef[StaticServiceIpConnectivity()];

coerce 'RepeatedStaticServiceIpConnectivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::StaticServiceIpConnectivity'->new($_) } @$_ ] };

declare 'MapStringStaticServiceIpConnectivity',
    as HashRef[StaticServiceIpConnectivity()];

declare 'ForwardSshTunnelConnectivity',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::ForwardSshTunnelConnectivity'];

coerce 'ForwardSshTunnelConnectivity',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::ForwardSshTunnelConnectivity'->new($_) };

declare 'RepeatedForwardSshTunnelConnectivity',
    as ArrayRef[ForwardSshTunnelConnectivity()];

coerce 'RepeatedForwardSshTunnelConnectivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::ForwardSshTunnelConnectivity'->new($_) } @$_ ] };

declare 'MapStringForwardSshTunnelConnectivity',
    as HashRef[ForwardSshTunnelConnectivity()];

declare 'VpcPeeringConfig',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::VpcPeeringConfig'];

coerce 'VpcPeeringConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::VpcPeeringConfig'->new($_) };

declare 'RepeatedVpcPeeringConfig',
    as ArrayRef[VpcPeeringConfig()];

coerce 'RepeatedVpcPeeringConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::VpcPeeringConfig'->new($_) } @$_ ] };

declare 'MapStringVpcPeeringConfig',
    as HashRef[VpcPeeringConfig()];

declare 'PrivateConnection',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::PrivateConnection'];

coerce 'PrivateConnection',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::PrivateConnection'->new($_) };

declare 'RepeatedPrivateConnection',
    as ArrayRef[PrivateConnection()];

coerce 'RepeatedPrivateConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::PrivateConnection'->new($_) } @$_ ] };

declare 'MapStringPrivateConnection',
    as HashRef[PrivateConnection()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::PrivateConnection::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::PrivateConnection::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::PrivateConnection::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'PrivateConnectivity',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::PrivateConnectivity'];

coerce 'PrivateConnectivity',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::PrivateConnectivity'->new($_) };

declare 'RepeatedPrivateConnectivity',
    as ArrayRef[PrivateConnectivity()];

coerce 'RepeatedPrivateConnectivity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::PrivateConnectivity'->new($_) } @$_ ] };

declare 'MapStringPrivateConnectivity',
    as HashRef[PrivateConnectivity()];

declare 'Route',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::Route'];

coerce 'Route',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Route'->new($_) };

declare 'RepeatedRoute',
    as ArrayRef[Route()];

coerce 'RepeatedRoute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Route'->new($_) } @$_ ] };

declare 'MapStringRoute',
    as HashRef[Route()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::Route::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Route::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Route::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'MysqlSslConfig',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlSslConfig'];

coerce 'MysqlSslConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlSslConfig'->new($_) };

declare 'RepeatedMysqlSslConfig',
    as ArrayRef[MysqlSslConfig()];

coerce 'RepeatedMysqlSslConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlSslConfig'->new($_) } @$_ ] };

declare 'MapStringMysqlSslConfig',
    as HashRef[MysqlSslConfig()];

declare 'ConnectionProfile',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::ConnectionProfile'];

coerce 'ConnectionProfile',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::ConnectionProfile'->new($_) };

declare 'RepeatedConnectionProfile',
    as ArrayRef[ConnectionProfile()];

coerce 'RepeatedConnectionProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::ConnectionProfile'->new($_) } @$_ ] };

declare 'MapStringConnectionProfile',
    as HashRef[ConnectionProfile()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::ConnectionProfile::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::ConnectionProfile::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::ConnectionProfile::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'OracleColumn',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleColumn'];

coerce 'OracleColumn',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleColumn'->new($_) };

declare 'RepeatedOracleColumn',
    as ArrayRef[OracleColumn()];

coerce 'RepeatedOracleColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleColumn'->new($_) } @$_ ] };

declare 'MapStringOracleColumn',
    as HashRef[OracleColumn()];

declare 'OracleTable',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleTable'];

coerce 'OracleTable',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleTable'->new($_) };

declare 'RepeatedOracleTable',
    as ArrayRef[OracleTable()];

coerce 'RepeatedOracleTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleTable'->new($_) } @$_ ] };

declare 'MapStringOracleTable',
    as HashRef[OracleTable()];

declare 'OracleSchema',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleSchema'];

coerce 'OracleSchema',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleSchema'->new($_) };

declare 'RepeatedOracleSchema',
    as ArrayRef[OracleSchema()];

coerce 'RepeatedOracleSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleSchema'->new($_) } @$_ ] };

declare 'MapStringOracleSchema',
    as HashRef[OracleSchema()];

declare 'OracleRdbms',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleRdbms'];

coerce 'OracleRdbms',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleRdbms'->new($_) };

declare 'RepeatedOracleRdbms',
    as ArrayRef[OracleRdbms()];

coerce 'RepeatedOracleRdbms',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleRdbms'->new($_) } @$_ ] };

declare 'MapStringOracleRdbms',
    as HashRef[OracleRdbms()];

declare 'OracleSourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleSourceConfig'];

coerce 'OracleSourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleSourceConfig'->new($_) };

declare 'RepeatedOracleSourceConfig',
    as ArrayRef[OracleSourceConfig()];

coerce 'RepeatedOracleSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::OracleSourceConfig'->new($_) } @$_ ] };

declare 'MapStringOracleSourceConfig',
    as HashRef[OracleSourceConfig()];

declare 'MysqlColumn',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlColumn'];

coerce 'MysqlColumn',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlColumn'->new($_) };

declare 'RepeatedMysqlColumn',
    as ArrayRef[MysqlColumn()];

coerce 'RepeatedMysqlColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlColumn'->new($_) } @$_ ] };

declare 'MapStringMysqlColumn',
    as HashRef[MysqlColumn()];

declare 'MysqlTable',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlTable'];

coerce 'MysqlTable',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlTable'->new($_) };

declare 'RepeatedMysqlTable',
    as ArrayRef[MysqlTable()];

coerce 'RepeatedMysqlTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlTable'->new($_) } @$_ ] };

declare 'MapStringMysqlTable',
    as HashRef[MysqlTable()];

declare 'MysqlDatabase',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlDatabase'];

coerce 'MysqlDatabase',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlDatabase'->new($_) };

declare 'RepeatedMysqlDatabase',
    as ArrayRef[MysqlDatabase()];

coerce 'RepeatedMysqlDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlDatabase'->new($_) } @$_ ] };

declare 'MapStringMysqlDatabase',
    as HashRef[MysqlDatabase()];

declare 'MysqlRdbms',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlRdbms'];

coerce 'MysqlRdbms',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlRdbms'->new($_) };

declare 'RepeatedMysqlRdbms',
    as ArrayRef[MysqlRdbms()];

coerce 'RepeatedMysqlRdbms',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlRdbms'->new($_) } @$_ ] };

declare 'MapStringMysqlRdbms',
    as HashRef[MysqlRdbms()];

declare 'MysqlSourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlSourceConfig'];

coerce 'MysqlSourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlSourceConfig'->new($_) };

declare 'RepeatedMysqlSourceConfig',
    as ArrayRef[MysqlSourceConfig()];

coerce 'RepeatedMysqlSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::MysqlSourceConfig'->new($_) } @$_ ] };

declare 'MapStringMysqlSourceConfig',
    as HashRef[MysqlSourceConfig()];

declare 'SourceConfig',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::SourceConfig'];

coerce 'SourceConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::SourceConfig'->new($_) };

declare 'RepeatedSourceConfig',
    as ArrayRef[SourceConfig()];

coerce 'RepeatedSourceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::SourceConfig'->new($_) } @$_ ] };

declare 'MapStringSourceConfig',
    as HashRef[SourceConfig()];

declare 'AvroFileFormat',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::AvroFileFormat'];

coerce 'AvroFileFormat',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::AvroFileFormat'->new($_) };

declare 'RepeatedAvroFileFormat',
    as ArrayRef[AvroFileFormat()];

coerce 'RepeatedAvroFileFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::AvroFileFormat'->new($_) } @$_ ] };

declare 'MapStringAvroFileFormat',
    as HashRef[AvroFileFormat()];

declare 'JsonFileFormat',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::JsonFileFormat'];

coerce 'JsonFileFormat',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::JsonFileFormat'->new($_) };

declare 'RepeatedJsonFileFormat',
    as ArrayRef[JsonFileFormat()];

coerce 'RepeatedJsonFileFormat',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::JsonFileFormat'->new($_) } @$_ ] };

declare 'MapStringJsonFileFormat',
    as HashRef[JsonFileFormat()];

declare 'JsonCompression',
    as (Int | Str);

declare 'GcsDestinationConfig',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::GcsDestinationConfig'];

coerce 'GcsDestinationConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::GcsDestinationConfig'->new($_) };

declare 'RepeatedGcsDestinationConfig',
    as ArrayRef[GcsDestinationConfig()];

coerce 'RepeatedGcsDestinationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::GcsDestinationConfig'->new($_) } @$_ ] };

declare 'MapStringGcsDestinationConfig',
    as HashRef[GcsDestinationConfig()];

declare 'DestinationConfig',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::DestinationConfig'];

coerce 'DestinationConfig',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::DestinationConfig'->new($_) };

declare 'RepeatedDestinationConfig',
    as ArrayRef[DestinationConfig()];

coerce 'RepeatedDestinationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::DestinationConfig'->new($_) } @$_ ] };

declare 'MapStringDestinationConfig',
    as HashRef[DestinationConfig()];

declare 'Stream',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::Stream'];

coerce 'Stream',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Stream'->new($_) };

declare 'RepeatedStream',
    as ArrayRef[Stream()];

coerce 'RepeatedStream',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Stream'->new($_) } @$_ ] };

declare 'MapStringStream',
    as HashRef[Stream()];

declare 'State',
    as (Int | Str);

declare 'BackfillAllStrategy',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::Stream::BackfillAllStrategy'];

coerce 'BackfillAllStrategy',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Stream::BackfillAllStrategy'->new($_) };

declare 'RepeatedBackfillAllStrategy',
    as ArrayRef[BackfillAllStrategy()];

coerce 'RepeatedBackfillAllStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Stream::BackfillAllStrategy'->new($_) } @$_ ] };

declare 'MapStringBackfillAllStrategy',
    as HashRef[BackfillAllStrategy()];

declare 'BackfillNoneStrategy',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::Stream::BackfillNoneStrategy'];

coerce 'BackfillNoneStrategy',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Stream::BackfillNoneStrategy'->new($_) };

declare 'RepeatedBackfillNoneStrategy',
    as ArrayRef[BackfillNoneStrategy()];

coerce 'RepeatedBackfillNoneStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Stream::BackfillNoneStrategy'->new($_) } @$_ ] };

declare 'MapStringBackfillNoneStrategy',
    as HashRef[BackfillNoneStrategy()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::Stream::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Stream::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Stream::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'Error',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::Error'];

coerce 'Error',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Error'->new($_) };

declare 'RepeatedError',
    as ArrayRef[Error()];

coerce 'RepeatedError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Error'->new($_) } @$_ ] };

declare 'MapStringError',
    as HashRef[Error()];

declare 'DetailsEntry',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::Error::DetailsEntry'];

coerce 'DetailsEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Error::DetailsEntry'->new($_) };

declare 'RepeatedDetailsEntry',
    as ArrayRef[DetailsEntry()];

coerce 'RepeatedDetailsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Error::DetailsEntry'->new($_) } @$_ ] };

declare 'MapStringDetailsEntry',
    as HashRef[DetailsEntry()];

declare 'ValidationResult',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::ValidationResult'];

coerce 'ValidationResult',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::ValidationResult'->new($_) };

declare 'RepeatedValidationResult',
    as ArrayRef[ValidationResult()];

coerce 'RepeatedValidationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::ValidationResult'->new($_) } @$_ ] };

declare 'MapStringValidationResult',
    as HashRef[ValidationResult()];

declare 'Validation',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::Validation'];

coerce 'Validation',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Validation'->new($_) };

declare 'RepeatedValidation',
    as ArrayRef[Validation()];

coerce 'RepeatedValidation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::Validation'->new($_) } @$_ ] };

declare 'MapStringValidation',
    as HashRef[Validation()];

declare 'Status',
    as (Int | Str);

declare 'ValidationMessage',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::ValidationMessage'];

coerce 'ValidationMessage',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::ValidationMessage'->new($_) };

declare 'RepeatedValidationMessage',
    as ArrayRef[ValidationMessage()];

coerce 'RepeatedValidationMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::ValidationMessage'->new($_) } @$_ ] };

declare 'MapStringValidationMessage',
    as HashRef[ValidationMessage()];

declare 'Level',
    as (Int | Str);

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Datastream::V1alpha1::DatastreamResources::ValidationMessage::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::ValidationMessage::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datastream::V1alpha1::DatastreamResources::ValidationMessage::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Datastream::V1alpha1::DatastreamResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
