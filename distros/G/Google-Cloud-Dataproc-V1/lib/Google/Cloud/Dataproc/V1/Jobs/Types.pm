package Google::Cloud::Dataproc::V1::Jobs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LoggingConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::LoggingConfig'];

coerce 'LoggingConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::LoggingConfig'->new($_) };

declare 'RepeatedLoggingConfig',
    as ArrayRef[LoggingConfig()];

coerce 'RepeatedLoggingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::LoggingConfig'->new($_) } @$_ ] };

declare 'MapStringLoggingConfig',
    as HashRef[LoggingConfig()];

declare 'Level',
    as (Int | Str);

declare 'DriverLogLevelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::LoggingConfig::DriverLogLevelsEntry'];

coerce 'DriverLogLevelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::LoggingConfig::DriverLogLevelsEntry'->new($_) };

declare 'RepeatedDriverLogLevelsEntry',
    as ArrayRef[DriverLogLevelsEntry()];

coerce 'RepeatedDriverLogLevelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::LoggingConfig::DriverLogLevelsEntry'->new($_) } @$_ ] };

declare 'MapStringDriverLogLevelsEntry',
    as HashRef[DriverLogLevelsEntry()];

declare 'HadoopJob',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::HadoopJob'];

coerce 'HadoopJob',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::HadoopJob'->new($_) };

declare 'RepeatedHadoopJob',
    as ArrayRef[HadoopJob()];

coerce 'RepeatedHadoopJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::HadoopJob'->new($_) } @$_ ] };

declare 'MapStringHadoopJob',
    as HashRef[HadoopJob()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::HadoopJob::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::HadoopJob::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::HadoopJob::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'SparkJob',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::SparkJob'];

coerce 'SparkJob',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::SparkJob'->new($_) };

declare 'RepeatedSparkJob',
    as ArrayRef[SparkJob()];

coerce 'RepeatedSparkJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::SparkJob'->new($_) } @$_ ] };

declare 'MapStringSparkJob',
    as HashRef[SparkJob()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::SparkJob::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::SparkJob::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::SparkJob::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'PySparkJob',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::PySparkJob'];

coerce 'PySparkJob',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::PySparkJob'->new($_) };

declare 'RepeatedPySparkJob',
    as ArrayRef[PySparkJob()];

coerce 'RepeatedPySparkJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::PySparkJob'->new($_) } @$_ ] };

declare 'MapStringPySparkJob',
    as HashRef[PySparkJob()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::PySparkJob::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::PySparkJob::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::PySparkJob::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'QueryList',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::QueryList'];

coerce 'QueryList',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::QueryList'->new($_) };

declare 'RepeatedQueryList',
    as ArrayRef[QueryList()];

coerce 'RepeatedQueryList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::QueryList'->new($_) } @$_ ] };

declare 'MapStringQueryList',
    as HashRef[QueryList()];

declare 'HiveJob',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::HiveJob'];

coerce 'HiveJob',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::HiveJob'->new($_) };

declare 'RepeatedHiveJob',
    as ArrayRef[HiveJob()];

coerce 'RepeatedHiveJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::HiveJob'->new($_) } @$_ ] };

declare 'MapStringHiveJob',
    as HashRef[HiveJob()];

declare 'ScriptVariablesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::HiveJob::ScriptVariablesEntry'];

coerce 'ScriptVariablesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::HiveJob::ScriptVariablesEntry'->new($_) };

declare 'RepeatedScriptVariablesEntry',
    as ArrayRef[ScriptVariablesEntry()];

coerce 'RepeatedScriptVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::HiveJob::ScriptVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringScriptVariablesEntry',
    as HashRef[ScriptVariablesEntry()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::HiveJob::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::HiveJob::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::HiveJob::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'SparkSqlJob',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::SparkSqlJob'];

coerce 'SparkSqlJob',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::SparkSqlJob'->new($_) };

declare 'RepeatedSparkSqlJob',
    as ArrayRef[SparkSqlJob()];

coerce 'RepeatedSparkSqlJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::SparkSqlJob'->new($_) } @$_ ] };

declare 'MapStringSparkSqlJob',
    as HashRef[SparkSqlJob()];

declare 'ScriptVariablesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::SparkSqlJob::ScriptVariablesEntry'];

coerce 'ScriptVariablesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::SparkSqlJob::ScriptVariablesEntry'->new($_) };

declare 'RepeatedScriptVariablesEntry',
    as ArrayRef[ScriptVariablesEntry()];

coerce 'RepeatedScriptVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::SparkSqlJob::ScriptVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringScriptVariablesEntry',
    as HashRef[ScriptVariablesEntry()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::SparkSqlJob::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::SparkSqlJob::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::SparkSqlJob::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'PigJob',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::PigJob'];

coerce 'PigJob',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::PigJob'->new($_) };

declare 'RepeatedPigJob',
    as ArrayRef[PigJob()];

coerce 'RepeatedPigJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::PigJob'->new($_) } @$_ ] };

declare 'MapStringPigJob',
    as HashRef[PigJob()];

declare 'ScriptVariablesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::PigJob::ScriptVariablesEntry'];

coerce 'ScriptVariablesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::PigJob::ScriptVariablesEntry'->new($_) };

declare 'RepeatedScriptVariablesEntry',
    as ArrayRef[ScriptVariablesEntry()];

coerce 'RepeatedScriptVariablesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::PigJob::ScriptVariablesEntry'->new($_) } @$_ ] };

declare 'MapStringScriptVariablesEntry',
    as HashRef[ScriptVariablesEntry()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::PigJob::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::PigJob::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::PigJob::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'SparkRJob',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::SparkRJob'];

coerce 'SparkRJob',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::SparkRJob'->new($_) };

declare 'RepeatedSparkRJob',
    as ArrayRef[SparkRJob()];

coerce 'RepeatedSparkRJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::SparkRJob'->new($_) } @$_ ] };

declare 'MapStringSparkRJob',
    as HashRef[SparkRJob()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::SparkRJob::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::SparkRJob::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::SparkRJob::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'PrestoJob',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::PrestoJob'];

coerce 'PrestoJob',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::PrestoJob'->new($_) };

declare 'RepeatedPrestoJob',
    as ArrayRef[PrestoJob()];

coerce 'RepeatedPrestoJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::PrestoJob'->new($_) } @$_ ] };

declare 'MapStringPrestoJob',
    as HashRef[PrestoJob()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::PrestoJob::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::PrestoJob::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::PrestoJob::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'TrinoJob',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::TrinoJob'];

coerce 'TrinoJob',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::TrinoJob'->new($_) };

declare 'RepeatedTrinoJob',
    as ArrayRef[TrinoJob()];

coerce 'RepeatedTrinoJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::TrinoJob'->new($_) } @$_ ] };

declare 'MapStringTrinoJob',
    as HashRef[TrinoJob()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::TrinoJob::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::TrinoJob::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::TrinoJob::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'FlinkJob',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::FlinkJob'];

coerce 'FlinkJob',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::FlinkJob'->new($_) };

declare 'RepeatedFlinkJob',
    as ArrayRef[FlinkJob()];

coerce 'RepeatedFlinkJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::FlinkJob'->new($_) } @$_ ] };

declare 'MapStringFlinkJob',
    as HashRef[FlinkJob()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::FlinkJob::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::FlinkJob::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::FlinkJob::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'JobPlacement',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::JobPlacement'];

coerce 'JobPlacement',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::JobPlacement'->new($_) };

declare 'RepeatedJobPlacement',
    as ArrayRef[JobPlacement()];

coerce 'RepeatedJobPlacement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::JobPlacement'->new($_) } @$_ ] };

declare 'MapStringJobPlacement',
    as HashRef[JobPlacement()];

declare 'ClusterLabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::JobPlacement::ClusterLabelsEntry'];

coerce 'ClusterLabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::JobPlacement::ClusterLabelsEntry'->new($_) };

declare 'RepeatedClusterLabelsEntry',
    as ArrayRef[ClusterLabelsEntry()];

coerce 'RepeatedClusterLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::JobPlacement::ClusterLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringClusterLabelsEntry',
    as HashRef[ClusterLabelsEntry()];

declare 'JobStatus',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::JobStatus'];

coerce 'JobStatus',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::JobStatus'->new($_) };

declare 'RepeatedJobStatus',
    as ArrayRef[JobStatus()];

coerce 'RepeatedJobStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::JobStatus'->new($_) } @$_ ] };

declare 'MapStringJobStatus',
    as HashRef[JobStatus()];

declare 'State',
    as (Int | Str);

declare 'Substate',
    as (Int | Str);

declare 'JobReference',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::JobReference'];

coerce 'JobReference',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::JobReference'->new($_) };

declare 'RepeatedJobReference',
    as ArrayRef[JobReference()];

coerce 'RepeatedJobReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::JobReference'->new($_) } @$_ ] };

declare 'MapStringJobReference',
    as HashRef[JobReference()];

declare 'YarnApplication',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::YarnApplication'];

coerce 'YarnApplication',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::YarnApplication'->new($_) };

declare 'RepeatedYarnApplication',
    as ArrayRef[YarnApplication()];

coerce 'RepeatedYarnApplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::YarnApplication'->new($_) } @$_ ] };

declare 'MapStringYarnApplication',
    as HashRef[YarnApplication()];

declare 'State',
    as (Int | Str);

declare 'Job',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::Job'];

coerce 'Job',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::Job'->new($_) };

declare 'RepeatedJob',
    as ArrayRef[Job()];

coerce 'RepeatedJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::Job'->new($_) } @$_ ] };

declare 'MapStringJob',
    as HashRef[Job()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::Job::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::Job::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::Job::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DriverSchedulingConfig',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::DriverSchedulingConfig'];

coerce 'DriverSchedulingConfig',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::DriverSchedulingConfig'->new($_) };

declare 'RepeatedDriverSchedulingConfig',
    as ArrayRef[DriverSchedulingConfig()];

coerce 'RepeatedDriverSchedulingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::DriverSchedulingConfig'->new($_) } @$_ ] };

declare 'MapStringDriverSchedulingConfig',
    as HashRef[DriverSchedulingConfig()];

declare 'JobScheduling',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::JobScheduling'];

coerce 'JobScheduling',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::JobScheduling'->new($_) };

declare 'RepeatedJobScheduling',
    as ArrayRef[JobScheduling()];

coerce 'RepeatedJobScheduling',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::JobScheduling'->new($_) } @$_ ] };

declare 'MapStringJobScheduling',
    as HashRef[JobScheduling()];

declare 'SubmitJobRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::SubmitJobRequest'];

coerce 'SubmitJobRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::SubmitJobRequest'->new($_) };

declare 'RepeatedSubmitJobRequest',
    as ArrayRef[SubmitJobRequest()];

coerce 'RepeatedSubmitJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::SubmitJobRequest'->new($_) } @$_ ] };

declare 'MapStringSubmitJobRequest',
    as HashRef[SubmitJobRequest()];

declare 'JobMetadata',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::JobMetadata'];

coerce 'JobMetadata',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::JobMetadata'->new($_) };

declare 'RepeatedJobMetadata',
    as ArrayRef[JobMetadata()];

coerce 'RepeatedJobMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::JobMetadata'->new($_) } @$_ ] };

declare 'MapStringJobMetadata',
    as HashRef[JobMetadata()];

declare 'GetJobRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::GetJobRequest'];

coerce 'GetJobRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::GetJobRequest'->new($_) };

declare 'RepeatedGetJobRequest',
    as ArrayRef[GetJobRequest()];

coerce 'RepeatedGetJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::GetJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobRequest',
    as HashRef[GetJobRequest()];

declare 'ListJobsRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::ListJobsRequest'];

coerce 'ListJobsRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::ListJobsRequest'->new($_) };

declare 'RepeatedListJobsRequest',
    as ArrayRef[ListJobsRequest()];

coerce 'RepeatedListJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::ListJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListJobsRequest',
    as HashRef[ListJobsRequest()];

declare 'JobStateMatcher',
    as (Int | Str);

declare 'UpdateJobRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::UpdateJobRequest'];

coerce 'UpdateJobRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::UpdateJobRequest'->new($_) };

declare 'RepeatedUpdateJobRequest',
    as ArrayRef[UpdateJobRequest()];

coerce 'RepeatedUpdateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::UpdateJobRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateJobRequest',
    as HashRef[UpdateJobRequest()];

declare 'ListJobsResponse',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::ListJobsResponse'];

coerce 'ListJobsResponse',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::ListJobsResponse'->new($_) };

declare 'RepeatedListJobsResponse',
    as ArrayRef[ListJobsResponse()];

coerce 'RepeatedListJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::ListJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListJobsResponse',
    as HashRef[ListJobsResponse()];

declare 'CancelJobRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::CancelJobRequest'];

coerce 'CancelJobRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::CancelJobRequest'->new($_) };

declare 'RepeatedCancelJobRequest',
    as ArrayRef[CancelJobRequest()];

coerce 'RepeatedCancelJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::CancelJobRequest'->new($_) } @$_ ] };

declare 'MapStringCancelJobRequest',
    as HashRef[CancelJobRequest()];

declare 'DeleteJobRequest',
    as InstanceOf['Google::Cloud::Dataproc::V1::Jobs::DeleteJobRequest'];

coerce 'DeleteJobRequest',
    from HashRef, via { 'Google::Cloud::Dataproc::V1::Jobs::DeleteJobRequest'->new($_) };

declare 'RepeatedDeleteJobRequest',
    as ArrayRef[DeleteJobRequest()];

coerce 'RepeatedDeleteJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dataproc::V1::Jobs::DeleteJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteJobRequest',
    as HashRef[DeleteJobRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::Jobs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
