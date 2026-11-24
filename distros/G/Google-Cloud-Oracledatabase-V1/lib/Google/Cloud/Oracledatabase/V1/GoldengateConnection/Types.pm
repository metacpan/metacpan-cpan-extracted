package Google::Cloud::Oracledatabase::V1::GoldengateConnection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GoldengateConnection',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateConnection'];

coerce 'GoldengateConnection',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateConnection'->new($_) };

declare 'RepeatedGoldengateConnection',
    as ArrayRef[GoldengateConnection()];

coerce 'RepeatedGoldengateConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateConnection'->new($_) } @$_ ] };

declare 'MapStringGoldengateConnection',
    as HashRef[GoldengateConnection()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateConnection::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateConnection::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateConnection::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'GoldengateConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateConnectionProperties'];

coerce 'GoldengateConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateConnectionProperties'->new($_) };

declare 'RepeatedGoldengateConnectionProperties',
    as ArrayRef[GoldengateConnectionProperties()];

coerce 'RepeatedGoldengateConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateConnectionProperties',
    as HashRef[GoldengateConnectionProperties()];

declare 'GoldengateConnectionType',
    as (Int | Str);

declare 'GoldengateConnectionLifecycleState',
    as (Int | Str);

declare 'GoldengateConnectionRoutingMethod',
    as (Int | Str);

declare 'GoldengateOracleConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateOracleConnectionProperties'];

coerce 'GoldengateOracleConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateOracleConnectionProperties'->new($_) };

declare 'RepeatedGoldengateOracleConnectionProperties',
    as ArrayRef[GoldengateOracleConnectionProperties()];

coerce 'RepeatedGoldengateOracleConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateOracleConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateOracleConnectionProperties',
    as HashRef[GoldengateOracleConnectionProperties()];

declare 'OracleAuthenticationMode',
    as (Int | Str);

declare 'SessionMode',
    as (Int | Str);

declare 'GoldengateGoldengateConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGoldengateConnectionProperties'];

coerce 'GoldengateGoldengateConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGoldengateConnectionProperties'->new($_) };

declare 'RepeatedGoldengateGoldengateConnectionProperties',
    as ArrayRef[GoldengateGoldengateConnectionProperties()];

coerce 'RepeatedGoldengateGoldengateConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGoldengateConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateGoldengateConnectionProperties',
    as HashRef[GoldengateGoldengateConnectionProperties()];

declare 'GoldengateGenericConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGenericConnectionProperties'];

coerce 'GoldengateGenericConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGenericConnectionProperties'->new($_) };

declare 'RepeatedGoldengateGenericConnectionProperties',
    as ArrayRef[GoldengateGenericConnectionProperties()];

coerce 'RepeatedGoldengateGenericConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGenericConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateGenericConnectionProperties',
    as HashRef[GoldengateGenericConnectionProperties()];

declare 'GoldengateGoogleCloudStorageConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGoogleCloudStorageConnectionProperties'];

coerce 'GoldengateGoogleCloudStorageConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGoogleCloudStorageConnectionProperties'->new($_) };

declare 'RepeatedGoldengateGoogleCloudStorageConnectionProperties',
    as ArrayRef[GoldengateGoogleCloudStorageConnectionProperties()];

coerce 'RepeatedGoldengateGoogleCloudStorageConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGoogleCloudStorageConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateGoogleCloudStorageConnectionProperties',
    as HashRef[GoldengateGoogleCloudStorageConnectionProperties()];

declare 'GoldengateGoogleBigQueryConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGoogleBigQueryConnectionProperties'];

coerce 'GoldengateGoogleBigQueryConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGoogleBigQueryConnectionProperties'->new($_) };

declare 'RepeatedGoldengateGoogleBigQueryConnectionProperties',
    as ArrayRef[GoldengateGoogleBigQueryConnectionProperties()];

coerce 'RepeatedGoldengateGoogleBigQueryConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGoogleBigQueryConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateGoogleBigQueryConnectionProperties',
    as HashRef[GoldengateGoogleBigQueryConnectionProperties()];

declare 'GoldengateMysqlConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateMysqlConnectionProperties'];

coerce 'GoldengateMysqlConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateMysqlConnectionProperties'->new($_) };

declare 'RepeatedGoldengateMysqlConnectionProperties',
    as ArrayRef[GoldengateMysqlConnectionProperties()];

coerce 'RepeatedGoldengateMysqlConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateMysqlConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateMysqlConnectionProperties',
    as HashRef[GoldengateMysqlConnectionProperties()];

declare 'MysqlSecurityProtocol',
    as (Int | Str);

declare 'SSLMode',
    as (Int | Str);

declare 'GoldengateKafkaConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateKafkaConnectionProperties'];

coerce 'GoldengateKafkaConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateKafkaConnectionProperties'->new($_) };

declare 'RepeatedGoldengateKafkaConnectionProperties',
    as ArrayRef[GoldengateKafkaConnectionProperties()];

coerce 'RepeatedGoldengateKafkaConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateKafkaConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateKafkaConnectionProperties',
    as HashRef[GoldengateKafkaConnectionProperties()];

declare 'KafkaSecurityProtocol',
    as (Int | Str);

declare 'GoldengateKafkaSchemaRegistryConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateKafkaSchemaRegistryConnectionProperties'];

coerce 'GoldengateKafkaSchemaRegistryConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateKafkaSchemaRegistryConnectionProperties'->new($_) };

declare 'RepeatedGoldengateKafkaSchemaRegistryConnectionProperties',
    as ArrayRef[GoldengateKafkaSchemaRegistryConnectionProperties()];

coerce 'RepeatedGoldengateKafkaSchemaRegistryConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateKafkaSchemaRegistryConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateKafkaSchemaRegistryConnectionProperties',
    as HashRef[GoldengateKafkaSchemaRegistryConnectionProperties()];

declare 'AuthenticationType',
    as (Int | Str);

declare 'GoldengateOciObjectStorageConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateOciObjectStorageConnectionProperties'];

coerce 'GoldengateOciObjectStorageConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateOciObjectStorageConnectionProperties'->new($_) };

declare 'RepeatedGoldengateOciObjectStorageConnectionProperties',
    as ArrayRef[GoldengateOciObjectStorageConnectionProperties()];

coerce 'RepeatedGoldengateOciObjectStorageConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateOciObjectStorageConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateOciObjectStorageConnectionProperties',
    as HashRef[GoldengateOciObjectStorageConnectionProperties()];

declare 'GoldengateAzureDataLakeStorageConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAzureDataLakeStorageConnectionProperties'];

coerce 'GoldengateAzureDataLakeStorageConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAzureDataLakeStorageConnectionProperties'->new($_) };

declare 'RepeatedGoldengateAzureDataLakeStorageConnectionProperties',
    as ArrayRef[GoldengateAzureDataLakeStorageConnectionProperties()];

coerce 'RepeatedGoldengateAzureDataLakeStorageConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAzureDataLakeStorageConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateAzureDataLakeStorageConnectionProperties',
    as HashRef[GoldengateAzureDataLakeStorageConnectionProperties()];

declare 'AuthenticationType',
    as (Int | Str);

declare 'GoldengateAzureSynapseAnalyticsConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAzureSynapseAnalyticsConnectionProperties'];

coerce 'GoldengateAzureSynapseAnalyticsConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAzureSynapseAnalyticsConnectionProperties'->new($_) };

declare 'RepeatedGoldengateAzureSynapseAnalyticsConnectionProperties',
    as ArrayRef[GoldengateAzureSynapseAnalyticsConnectionProperties()];

coerce 'RepeatedGoldengateAzureSynapseAnalyticsConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAzureSynapseAnalyticsConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateAzureSynapseAnalyticsConnectionProperties',
    as HashRef[GoldengateAzureSynapseAnalyticsConnectionProperties()];

declare 'GoldengatePostgresqlConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengatePostgresqlConnectionProperties'];

coerce 'GoldengatePostgresqlConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengatePostgresqlConnectionProperties'->new($_) };

declare 'RepeatedGoldengatePostgresqlConnectionProperties',
    as ArrayRef[GoldengatePostgresqlConnectionProperties()];

coerce 'RepeatedGoldengatePostgresqlConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengatePostgresqlConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengatePostgresqlConnectionProperties',
    as HashRef[GoldengatePostgresqlConnectionProperties()];

declare 'PostgresqlSecurityProtocol',
    as (Int | Str);

declare 'PostgresqlSslMode',
    as (Int | Str);

declare 'GoldengateMicrosoftSqlserverConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateMicrosoftSqlserverConnectionProperties'];

coerce 'GoldengateMicrosoftSqlserverConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateMicrosoftSqlserverConnectionProperties'->new($_) };

declare 'RepeatedGoldengateMicrosoftSqlserverConnectionProperties',
    as ArrayRef[GoldengateMicrosoftSqlserverConnectionProperties()];

coerce 'RepeatedGoldengateMicrosoftSqlserverConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateMicrosoftSqlserverConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateMicrosoftSqlserverConnectionProperties',
    as HashRef[GoldengateMicrosoftSqlserverConnectionProperties()];

declare 'MicrosoftSqlserverSecurityProtocol',
    as (Int | Str);

declare 'GoldengateAmazonS3ConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAmazonS3ConnectionProperties'];

coerce 'GoldengateAmazonS3ConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAmazonS3ConnectionProperties'->new($_) };

declare 'RepeatedGoldengateAmazonS3ConnectionProperties',
    as ArrayRef[GoldengateAmazonS3ConnectionProperties()];

coerce 'RepeatedGoldengateAmazonS3ConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAmazonS3ConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateAmazonS3ConnectionProperties',
    as HashRef[GoldengateAmazonS3ConnectionProperties()];

declare 'GoldengateHdfsConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateHdfsConnectionProperties'];

coerce 'GoldengateHdfsConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateHdfsConnectionProperties'->new($_) };

declare 'RepeatedGoldengateHdfsConnectionProperties',
    as ArrayRef[GoldengateHdfsConnectionProperties()];

coerce 'RepeatedGoldengateHdfsConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateHdfsConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateHdfsConnectionProperties',
    as HashRef[GoldengateHdfsConnectionProperties()];

declare 'GoldengateJavaMessageServiceConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateJavaMessageServiceConnectionProperties'];

coerce 'GoldengateJavaMessageServiceConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateJavaMessageServiceConnectionProperties'->new($_) };

declare 'RepeatedGoldengateJavaMessageServiceConnectionProperties',
    as ArrayRef[GoldengateJavaMessageServiceConnectionProperties()];

coerce 'RepeatedGoldengateJavaMessageServiceConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateJavaMessageServiceConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateJavaMessageServiceConnectionProperties',
    as HashRef[GoldengateJavaMessageServiceConnectionProperties()];

declare 'JmsSecurityProtocol',
    as (Int | Str);

declare 'JmsAuthenticationType',
    as (Int | Str);

declare 'GoldengateMongodbConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateMongodbConnectionProperties'];

coerce 'GoldengateMongodbConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateMongodbConnectionProperties'->new($_) };

declare 'RepeatedGoldengateMongodbConnectionProperties',
    as ArrayRef[GoldengateMongodbConnectionProperties()];

coerce 'RepeatedGoldengateMongodbConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateMongodbConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateMongodbConnectionProperties',
    as HashRef[GoldengateMongodbConnectionProperties()];

declare 'MongodbSecurityProtocol',
    as (Int | Str);

declare 'GoldengateOracleNosqlConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateOracleNosqlConnectionProperties'];

coerce 'GoldengateOracleNosqlConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateOracleNosqlConnectionProperties'->new($_) };

declare 'RepeatedGoldengateOracleNosqlConnectionProperties',
    as ArrayRef[GoldengateOracleNosqlConnectionProperties()];

coerce 'RepeatedGoldengateOracleNosqlConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateOracleNosqlConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateOracleNosqlConnectionProperties',
    as HashRef[GoldengateOracleNosqlConnectionProperties()];

declare 'GoldengateSnowflakeConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateSnowflakeConnectionProperties'];

coerce 'GoldengateSnowflakeConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateSnowflakeConnectionProperties'->new($_) };

declare 'RepeatedGoldengateSnowflakeConnectionProperties',
    as ArrayRef[GoldengateSnowflakeConnectionProperties()];

coerce 'RepeatedGoldengateSnowflakeConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateSnowflakeConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateSnowflakeConnectionProperties',
    as HashRef[GoldengateSnowflakeConnectionProperties()];

declare 'AuthenticationType',
    as (Int | Str);

declare 'GoldengateAmazonRedshiftConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAmazonRedshiftConnectionProperties'];

coerce 'GoldengateAmazonRedshiftConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAmazonRedshiftConnectionProperties'->new($_) };

declare 'RepeatedGoldengateAmazonRedshiftConnectionProperties',
    as ArrayRef[GoldengateAmazonRedshiftConnectionProperties()];

coerce 'RepeatedGoldengateAmazonRedshiftConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAmazonRedshiftConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateAmazonRedshiftConnectionProperties',
    as HashRef[GoldengateAmazonRedshiftConnectionProperties()];

declare 'GoldengateElasticsearchConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateElasticsearchConnectionProperties'];

coerce 'GoldengateElasticsearchConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateElasticsearchConnectionProperties'->new($_) };

declare 'RepeatedGoldengateElasticsearchConnectionProperties',
    as ArrayRef[GoldengateElasticsearchConnectionProperties()];

coerce 'RepeatedGoldengateElasticsearchConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateElasticsearchConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateElasticsearchConnectionProperties',
    as HashRef[GoldengateElasticsearchConnectionProperties()];

declare 'ElasticsearchSecurityProtocol',
    as (Int | Str);

declare 'ElasticsearchAuthenticationType',
    as (Int | Str);

declare 'GoldengateAmazonKinesisConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAmazonKinesisConnectionProperties'];

coerce 'GoldengateAmazonKinesisConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAmazonKinesisConnectionProperties'->new($_) };

declare 'RepeatedGoldengateAmazonKinesisConnectionProperties',
    as ArrayRef[GoldengateAmazonKinesisConnectionProperties()];

coerce 'RepeatedGoldengateAmazonKinesisConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateAmazonKinesisConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateAmazonKinesisConnectionProperties',
    as HashRef[GoldengateAmazonKinesisConnectionProperties()];

declare 'GoldengateDb2ConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateDb2ConnectionProperties'];

coerce 'GoldengateDb2ConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateDb2ConnectionProperties'->new($_) };

declare 'RepeatedGoldengateDb2ConnectionProperties',
    as ArrayRef[GoldengateDb2ConnectionProperties()];

coerce 'RepeatedGoldengateDb2ConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateDb2ConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateDb2ConnectionProperties',
    as HashRef[GoldengateDb2ConnectionProperties()];

declare 'Db2SecurityProtocol',
    as (Int | Str);

declare 'GoldengateRedisConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateRedisConnectionProperties'];

coerce 'GoldengateRedisConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateRedisConnectionProperties'->new($_) };

declare 'RepeatedGoldengateRedisConnectionProperties',
    as ArrayRef[GoldengateRedisConnectionProperties()];

coerce 'RepeatedGoldengateRedisConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateRedisConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateRedisConnectionProperties',
    as HashRef[GoldengateRedisConnectionProperties()];

declare 'RedisSecurityProtocol',
    as (Int | Str);

declare 'RedisAuthenticationType',
    as (Int | Str);

declare 'GoldengateDatabricksConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateDatabricksConnectionProperties'];

coerce 'GoldengateDatabricksConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateDatabricksConnectionProperties'->new($_) };

declare 'RepeatedGoldengateDatabricksConnectionProperties',
    as ArrayRef[GoldengateDatabricksConnectionProperties()];

coerce 'RepeatedGoldengateDatabricksConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateDatabricksConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateDatabricksConnectionProperties',
    as HashRef[GoldengateDatabricksConnectionProperties()];

declare 'DatabricksAuthenticationType',
    as (Int | Str);

declare 'GoldengateGooglePubsubConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGooglePubsubConnectionProperties'];

coerce 'GoldengateGooglePubsubConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGooglePubsubConnectionProperties'->new($_) };

declare 'RepeatedGoldengateGooglePubsubConnectionProperties',
    as ArrayRef[GoldengateGooglePubsubConnectionProperties()];

coerce 'RepeatedGoldengateGooglePubsubConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateGooglePubsubConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateGooglePubsubConnectionProperties',
    as HashRef[GoldengateGooglePubsubConnectionProperties()];

declare 'GoldengateMicrosoftFabricConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateMicrosoftFabricConnectionProperties'];

coerce 'GoldengateMicrosoftFabricConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateMicrosoftFabricConnectionProperties'->new($_) };

declare 'RepeatedGoldengateMicrosoftFabricConnectionProperties',
    as ArrayRef[GoldengateMicrosoftFabricConnectionProperties()];

coerce 'RepeatedGoldengateMicrosoftFabricConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateMicrosoftFabricConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateMicrosoftFabricConnectionProperties',
    as HashRef[GoldengateMicrosoftFabricConnectionProperties()];

declare 'GoldengateOracleAIDataPlatformConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateOracleAIDataPlatformConnectionProperties'];

coerce 'GoldengateOracleAIDataPlatformConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateOracleAIDataPlatformConnectionProperties'->new($_) };

declare 'RepeatedGoldengateOracleAIDataPlatformConnectionProperties',
    as ArrayRef[GoldengateOracleAIDataPlatformConnectionProperties()];

coerce 'RepeatedGoldengateOracleAIDataPlatformConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateOracleAIDataPlatformConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateOracleAIDataPlatformConnectionProperties',
    as HashRef[GoldengateOracleAIDataPlatformConnectionProperties()];

declare 'GlueIcebergCatalog',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GlueIcebergCatalog'];

coerce 'GlueIcebergCatalog',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GlueIcebergCatalog'->new($_) };

declare 'RepeatedGlueIcebergCatalog',
    as ArrayRef[GlueIcebergCatalog()];

coerce 'RepeatedGlueIcebergCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GlueIcebergCatalog'->new($_) } @$_ ] };

declare 'MapStringGlueIcebergCatalog',
    as HashRef[GlueIcebergCatalog()];

declare 'NessieIcebergCatalog',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::NessieIcebergCatalog'];

coerce 'NessieIcebergCatalog',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::NessieIcebergCatalog'->new($_) };

declare 'RepeatedNessieIcebergCatalog',
    as ArrayRef[NessieIcebergCatalog()];

coerce 'RepeatedNessieIcebergCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::NessieIcebergCatalog'->new($_) } @$_ ] };

declare 'MapStringNessieIcebergCatalog',
    as HashRef[NessieIcebergCatalog()];

declare 'PolarisIcebergCatalog',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::PolarisIcebergCatalog'];

coerce 'PolarisIcebergCatalog',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::PolarisIcebergCatalog'->new($_) };

declare 'RepeatedPolarisIcebergCatalog',
    as ArrayRef[PolarisIcebergCatalog()];

coerce 'RepeatedPolarisIcebergCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::PolarisIcebergCatalog'->new($_) } @$_ ] };

declare 'MapStringPolarisIcebergCatalog',
    as HashRef[PolarisIcebergCatalog()];

declare 'RestIcebergCatalog',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::RestIcebergCatalog'];

coerce 'RestIcebergCatalog',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::RestIcebergCatalog'->new($_) };

declare 'RepeatedRestIcebergCatalog',
    as ArrayRef[RestIcebergCatalog()];

coerce 'RepeatedRestIcebergCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::RestIcebergCatalog'->new($_) } @$_ ] };

declare 'MapStringRestIcebergCatalog',
    as HashRef[RestIcebergCatalog()];

declare 'IcebergCatalog',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::IcebergCatalog'];

coerce 'IcebergCatalog',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::IcebergCatalog'->new($_) };

declare 'RepeatedIcebergCatalog',
    as ArrayRef[IcebergCatalog()];

coerce 'RepeatedIcebergCatalog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::IcebergCatalog'->new($_) } @$_ ] };

declare 'MapStringIcebergCatalog',
    as HashRef[IcebergCatalog()];

declare 'CatalogType',
    as (Int | Str);

declare 'AmazonS3IcebergStorage',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::AmazonS3IcebergStorage'];

coerce 'AmazonS3IcebergStorage',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::AmazonS3IcebergStorage'->new($_) };

declare 'RepeatedAmazonS3IcebergStorage',
    as ArrayRef[AmazonS3IcebergStorage()];

coerce 'RepeatedAmazonS3IcebergStorage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::AmazonS3IcebergStorage'->new($_) } @$_ ] };

declare 'MapStringAmazonS3IcebergStorage',
    as HashRef[AmazonS3IcebergStorage()];

declare 'SchemeType',
    as (Int | Str);

declare 'GoogleCloudStorageIcebergStorage',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoogleCloudStorageIcebergStorage'];

coerce 'GoogleCloudStorageIcebergStorage',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoogleCloudStorageIcebergStorage'->new($_) };

declare 'RepeatedGoogleCloudStorageIcebergStorage',
    as ArrayRef[GoogleCloudStorageIcebergStorage()];

coerce 'RepeatedGoogleCloudStorageIcebergStorage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoogleCloudStorageIcebergStorage'->new($_) } @$_ ] };

declare 'MapStringGoogleCloudStorageIcebergStorage',
    as HashRef[GoogleCloudStorageIcebergStorage()];

declare 'AzureDataLakeStorageIcebergStorage',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::AzureDataLakeStorageIcebergStorage'];

coerce 'AzureDataLakeStorageIcebergStorage',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::AzureDataLakeStorageIcebergStorage'->new($_) };

declare 'RepeatedAzureDataLakeStorageIcebergStorage',
    as ArrayRef[AzureDataLakeStorageIcebergStorage()];

coerce 'RepeatedAzureDataLakeStorageIcebergStorage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::AzureDataLakeStorageIcebergStorage'->new($_) } @$_ ] };

declare 'MapStringAzureDataLakeStorageIcebergStorage',
    as HashRef[AzureDataLakeStorageIcebergStorage()];

declare 'IcebergStorage',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::IcebergStorage'];

coerce 'IcebergStorage',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::IcebergStorage'->new($_) };

declare 'RepeatedIcebergStorage',
    as ArrayRef[IcebergStorage()];

coerce 'RepeatedIcebergStorage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::IcebergStorage'->new($_) } @$_ ] };

declare 'MapStringIcebergStorage',
    as HashRef[IcebergStorage()];

declare 'StorageType',
    as (Int | Str);

declare 'GoldengateIcebergConnectionProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateIcebergConnectionProperties'];

coerce 'GoldengateIcebergConnectionProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateIcebergConnectionProperties'->new($_) };

declare 'RepeatedGoldengateIcebergConnectionProperties',
    as ArrayRef[GoldengateIcebergConnectionProperties()];

coerce 'RepeatedGoldengateIcebergConnectionProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GoldengateIcebergConnectionProperties'->new($_) } @$_ ] };

declare 'MapStringGoldengateIcebergConnectionProperties',
    as HashRef[GoldengateIcebergConnectionProperties()];

declare 'CreateGoldengateConnectionRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::CreateGoldengateConnectionRequest'];

coerce 'CreateGoldengateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::CreateGoldengateConnectionRequest'->new($_) };

declare 'RepeatedCreateGoldengateConnectionRequest',
    as ArrayRef[CreateGoldengateConnectionRequest()];

coerce 'RepeatedCreateGoldengateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::CreateGoldengateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGoldengateConnectionRequest',
    as HashRef[CreateGoldengateConnectionRequest()];

declare 'UpdateGoldengateConnectionRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::UpdateGoldengateConnectionRequest'];

coerce 'UpdateGoldengateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::UpdateGoldengateConnectionRequest'->new($_) };

declare 'RepeatedUpdateGoldengateConnectionRequest',
    as ArrayRef[UpdateGoldengateConnectionRequest()];

coerce 'RepeatedUpdateGoldengateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::UpdateGoldengateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGoldengateConnectionRequest',
    as HashRef[UpdateGoldengateConnectionRequest()];

declare 'DeleteGoldengateConnectionRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::DeleteGoldengateConnectionRequest'];

coerce 'DeleteGoldengateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::DeleteGoldengateConnectionRequest'->new($_) };

declare 'RepeatedDeleteGoldengateConnectionRequest',
    as ArrayRef[DeleteGoldengateConnectionRequest()];

coerce 'RepeatedDeleteGoldengateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::DeleteGoldengateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGoldengateConnectionRequest',
    as HashRef[DeleteGoldengateConnectionRequest()];

declare 'GetGoldengateConnectionRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::GetGoldengateConnectionRequest'];

coerce 'GetGoldengateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GetGoldengateConnectionRequest'->new($_) };

declare 'RepeatedGetGoldengateConnectionRequest',
    as ArrayRef[GetGoldengateConnectionRequest()];

coerce 'RepeatedGetGoldengateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::GetGoldengateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetGoldengateConnectionRequest',
    as HashRef[GetGoldengateConnectionRequest()];

declare 'ListGoldengateConnectionsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::ListGoldengateConnectionsRequest'];

coerce 'ListGoldengateConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::ListGoldengateConnectionsRequest'->new($_) };

declare 'RepeatedListGoldengateConnectionsRequest',
    as ArrayRef[ListGoldengateConnectionsRequest()];

coerce 'RepeatedListGoldengateConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::ListGoldengateConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListGoldengateConnectionsRequest',
    as HashRef[ListGoldengateConnectionsRequest()];

declare 'ListGoldengateConnectionsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::ListGoldengateConnectionsResponse'];

coerce 'ListGoldengateConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::ListGoldengateConnectionsResponse'->new($_) };

declare 'RepeatedListGoldengateConnectionsResponse',
    as ArrayRef[ListGoldengateConnectionsResponse()];

coerce 'RepeatedListGoldengateConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::ListGoldengateConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListGoldengateConnectionsResponse',
    as HashRef[ListGoldengateConnectionsResponse()];

declare 'NameValuePair',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::NameValuePair'];

coerce 'NameValuePair',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::NameValuePair'->new($_) };

declare 'RepeatedNameValuePair',
    as ArrayRef[NameValuePair()];

coerce 'RepeatedNameValuePair',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::NameValuePair'->new($_) } @$_ ] };

declare 'MapStringNameValuePair',
    as HashRef[NameValuePair()];

declare 'KafkaBootstrapServer',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::GoldengateConnection::KafkaBootstrapServer'];

coerce 'KafkaBootstrapServer',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::KafkaBootstrapServer'->new($_) };

declare 'RepeatedKafkaBootstrapServer',
    as ArrayRef[KafkaBootstrapServer()];

coerce 'RepeatedKafkaBootstrapServer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::GoldengateConnection::KafkaBootstrapServer'->new($_) } @$_ ] };

declare 'MapStringKafkaBootstrapServer',
    as HashRef[KafkaBootstrapServer()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::GoldengateConnection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
