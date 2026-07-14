package Google::Cloud::BigQuery::V2::Routine::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Routine',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::Routine'];

coerce 'Routine',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::Routine'->new($_) };

declare 'RepeatedRoutine',
    as ArrayRef[Routine()];

coerce 'RepeatedRoutine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::Routine'->new($_) } @$_ ] };

declare 'MapStringRoutine',
    as HashRef[Routine()];

declare 'RoutineType',
    as (Int | Str);

declare 'Language',
    as (Int | Str);

declare 'DeterminismLevel',
    as (Int | Str);

declare 'SecurityMode',
    as (Int | Str);

declare 'DataGovernanceType',
    as (Int | Str);

declare 'Argument',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::Routine::Argument'];

coerce 'Argument',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::Routine::Argument'->new($_) };

declare 'RepeatedArgument',
    as ArrayRef[Argument()];

coerce 'RepeatedArgument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::Routine::Argument'->new($_) } @$_ ] };

declare 'MapStringArgument',
    as HashRef[Argument()];

declare 'ArgumentKind',
    as (Int | Str);

declare 'Mode',
    as (Int | Str);

declare 'RemoteFunctionOptions',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::Routine::RemoteFunctionOptions'];

coerce 'RemoteFunctionOptions',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::Routine::RemoteFunctionOptions'->new($_) };

declare 'RepeatedRemoteFunctionOptions',
    as ArrayRef[RemoteFunctionOptions()];

coerce 'RepeatedRemoteFunctionOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::Routine::RemoteFunctionOptions'->new($_) } @$_ ] };

declare 'MapStringRemoteFunctionOptions',
    as HashRef[RemoteFunctionOptions()];

declare 'UserDefinedContextEntry',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::Routine::RemoteFunctionOptions::UserDefinedContextEntry'];

coerce 'UserDefinedContextEntry',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::Routine::RemoteFunctionOptions::UserDefinedContextEntry'->new($_) };

declare 'RepeatedUserDefinedContextEntry',
    as ArrayRef[UserDefinedContextEntry()];

coerce 'RepeatedUserDefinedContextEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::Routine::RemoteFunctionOptions::UserDefinedContextEntry'->new($_) } @$_ ] };

declare 'MapStringUserDefinedContextEntry',
    as HashRef[UserDefinedContextEntry()];

declare 'PythonOptions',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::PythonOptions'];

coerce 'PythonOptions',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::PythonOptions'->new($_) };

declare 'RepeatedPythonOptions',
    as ArrayRef[PythonOptions()];

coerce 'RepeatedPythonOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::PythonOptions'->new($_) } @$_ ] };

declare 'MapStringPythonOptions',
    as HashRef[PythonOptions()];

declare 'ExternalRuntimeOptions',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::ExternalRuntimeOptions'];

coerce 'ExternalRuntimeOptions',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::ExternalRuntimeOptions'->new($_) };

declare 'RepeatedExternalRuntimeOptions',
    as ArrayRef[ExternalRuntimeOptions()];

coerce 'RepeatedExternalRuntimeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::ExternalRuntimeOptions'->new($_) } @$_ ] };

declare 'MapStringExternalRuntimeOptions',
    as HashRef[ExternalRuntimeOptions()];

declare 'SparkOptions',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::SparkOptions'];

coerce 'SparkOptions',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::SparkOptions'->new($_) };

declare 'RepeatedSparkOptions',
    as ArrayRef[SparkOptions()];

coerce 'RepeatedSparkOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::SparkOptions'->new($_) } @$_ ] };

declare 'MapStringSparkOptions',
    as HashRef[SparkOptions()];

declare 'PropertiesEntry',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::SparkOptions::PropertiesEntry'];

coerce 'PropertiesEntry',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::SparkOptions::PropertiesEntry'->new($_) };

declare 'RepeatedPropertiesEntry',
    as ArrayRef[PropertiesEntry()];

coerce 'RepeatedPropertiesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::SparkOptions::PropertiesEntry'->new($_) } @$_ ] };

declare 'MapStringPropertiesEntry',
    as HashRef[PropertiesEntry()];

declare 'RoutineBuildStatus',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::RoutineBuildStatus'];

coerce 'RoutineBuildStatus',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::RoutineBuildStatus'->new($_) };

declare 'RepeatedRoutineBuildStatus',
    as ArrayRef[RoutineBuildStatus()];

coerce 'RepeatedRoutineBuildStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::RoutineBuildStatus'->new($_) } @$_ ] };

declare 'MapStringRoutineBuildStatus',
    as HashRef[RoutineBuildStatus()];

declare 'BuildState',
    as (Int | Str);

declare 'GetRoutineRequest',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::GetRoutineRequest'];

coerce 'GetRoutineRequest',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::GetRoutineRequest'->new($_) };

declare 'RepeatedGetRoutineRequest',
    as ArrayRef[GetRoutineRequest()];

coerce 'RepeatedGetRoutineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::GetRoutineRequest'->new($_) } @$_ ] };

declare 'MapStringGetRoutineRequest',
    as HashRef[GetRoutineRequest()];

declare 'InsertRoutineRequest',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::InsertRoutineRequest'];

coerce 'InsertRoutineRequest',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::InsertRoutineRequest'->new($_) };

declare 'RepeatedInsertRoutineRequest',
    as ArrayRef[InsertRoutineRequest()];

coerce 'RepeatedInsertRoutineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::InsertRoutineRequest'->new($_) } @$_ ] };

declare 'MapStringInsertRoutineRequest',
    as HashRef[InsertRoutineRequest()];

declare 'UpdateRoutineRequest',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::UpdateRoutineRequest'];

coerce 'UpdateRoutineRequest',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::UpdateRoutineRequest'->new($_) };

declare 'RepeatedUpdateRoutineRequest',
    as ArrayRef[UpdateRoutineRequest()];

coerce 'RepeatedUpdateRoutineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::UpdateRoutineRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRoutineRequest',
    as HashRef[UpdateRoutineRequest()];

declare 'DeleteRoutineRequest',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::DeleteRoutineRequest'];

coerce 'DeleteRoutineRequest',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::DeleteRoutineRequest'->new($_) };

declare 'RepeatedDeleteRoutineRequest',
    as ArrayRef[DeleteRoutineRequest()];

coerce 'RepeatedDeleteRoutineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::DeleteRoutineRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRoutineRequest',
    as HashRef[DeleteRoutineRequest()];

declare 'ListRoutinesRequest',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::ListRoutinesRequest'];

coerce 'ListRoutinesRequest',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::ListRoutinesRequest'->new($_) };

declare 'RepeatedListRoutinesRequest',
    as ArrayRef[ListRoutinesRequest()];

coerce 'RepeatedListRoutinesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::ListRoutinesRequest'->new($_) } @$_ ] };

declare 'MapStringListRoutinesRequest',
    as HashRef[ListRoutinesRequest()];

declare 'ListRoutinesResponse',
    as InstanceOf['Google::Cloud::BigQuery::V2::Routine::ListRoutinesResponse'];

coerce 'ListRoutinesResponse',
    from HashRef, via { 'Google::Cloud::BigQuery::V2::Routine::ListRoutinesResponse'->new($_) };

declare 'RepeatedListRoutinesResponse',
    as ArrayRef[ListRoutinesResponse()];

coerce 'RepeatedListRoutinesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::BigQuery::V2::Routine::ListRoutinesResponse'->new($_) } @$_ ] };

declare 'MapStringListRoutinesResponse',
    as HashRef[ListRoutinesResponse()];

1;
