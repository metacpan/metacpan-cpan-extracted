package Google::Api::Client::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ClientLibraryOrganization',
    as (Int | Str);

declare 'ClientLibraryDestination',
    as (Int | Str);

declare 'FlowControlLimitExceededBehaviorProto',
    as (Int | Str);

declare 'CommonLanguageSettings',
    as InstanceOf['Google::Api::Client::CommonLanguageSettings'];

coerce 'CommonLanguageSettings',
    from HashRef, via { 'Google::Api::Client::CommonLanguageSettings'->new($_) };

declare 'RepeatedCommonLanguageSettings',
    as ArrayRef[CommonLanguageSettings()];

coerce 'RepeatedCommonLanguageSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::CommonLanguageSettings'->new($_) } @$_ ] };

declare 'MapStringCommonLanguageSettings',
    as HashRef[CommonLanguageSettings()];

declare 'ClientLibrarySettings',
    as InstanceOf['Google::Api::Client::ClientLibrarySettings'];

coerce 'ClientLibrarySettings',
    from HashRef, via { 'Google::Api::Client::ClientLibrarySettings'->new($_) };

declare 'RepeatedClientLibrarySettings',
    as ArrayRef[ClientLibrarySettings()];

coerce 'RepeatedClientLibrarySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::ClientLibrarySettings'->new($_) } @$_ ] };

declare 'MapStringClientLibrarySettings',
    as HashRef[ClientLibrarySettings()];

declare 'Publishing',
    as InstanceOf['Google::Api::Client::Publishing'];

coerce 'Publishing',
    from HashRef, via { 'Google::Api::Client::Publishing'->new($_) };

declare 'RepeatedPublishing',
    as ArrayRef[Publishing()];

coerce 'RepeatedPublishing',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::Publishing'->new($_) } @$_ ] };

declare 'MapStringPublishing',
    as HashRef[Publishing()];

declare 'JavaSettings',
    as InstanceOf['Google::Api::Client::JavaSettings'];

coerce 'JavaSettings',
    from HashRef, via { 'Google::Api::Client::JavaSettings'->new($_) };

declare 'RepeatedJavaSettings',
    as ArrayRef[JavaSettings()];

coerce 'RepeatedJavaSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::JavaSettings'->new($_) } @$_ ] };

declare 'MapStringJavaSettings',
    as HashRef[JavaSettings()];

declare 'ServiceClassNamesEntry',
    as InstanceOf['Google::Api::Client::JavaSettings::ServiceClassNamesEntry'];

coerce 'ServiceClassNamesEntry',
    from HashRef, via { 'Google::Api::Client::JavaSettings::ServiceClassNamesEntry'->new($_) };

declare 'RepeatedServiceClassNamesEntry',
    as ArrayRef[ServiceClassNamesEntry()];

coerce 'RepeatedServiceClassNamesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::JavaSettings::ServiceClassNamesEntry'->new($_) } @$_ ] };

declare 'MapStringServiceClassNamesEntry',
    as HashRef[ServiceClassNamesEntry()];

declare 'CppSettings',
    as InstanceOf['Google::Api::Client::CppSettings'];

coerce 'CppSettings',
    from HashRef, via { 'Google::Api::Client::CppSettings'->new($_) };

declare 'RepeatedCppSettings',
    as ArrayRef[CppSettings()];

coerce 'RepeatedCppSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::CppSettings'->new($_) } @$_ ] };

declare 'MapStringCppSettings',
    as HashRef[CppSettings()];

declare 'PhpSettings',
    as InstanceOf['Google::Api::Client::PhpSettings'];

coerce 'PhpSettings',
    from HashRef, via { 'Google::Api::Client::PhpSettings'->new($_) };

declare 'RepeatedPhpSettings',
    as ArrayRef[PhpSettings()];

coerce 'RepeatedPhpSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::PhpSettings'->new($_) } @$_ ] };

declare 'MapStringPhpSettings',
    as HashRef[PhpSettings()];

declare 'PythonSettings',
    as InstanceOf['Google::Api::Client::PythonSettings'];

coerce 'PythonSettings',
    from HashRef, via { 'Google::Api::Client::PythonSettings'->new($_) };

declare 'RepeatedPythonSettings',
    as ArrayRef[PythonSettings()];

coerce 'RepeatedPythonSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::PythonSettings'->new($_) } @$_ ] };

declare 'MapStringPythonSettings',
    as HashRef[PythonSettings()];

declare 'ExperimentalFeatures',
    as InstanceOf['Google::Api::Client::PythonSettings::ExperimentalFeatures'];

coerce 'ExperimentalFeatures',
    from HashRef, via { 'Google::Api::Client::PythonSettings::ExperimentalFeatures'->new($_) };

declare 'RepeatedExperimentalFeatures',
    as ArrayRef[ExperimentalFeatures()];

coerce 'RepeatedExperimentalFeatures',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::PythonSettings::ExperimentalFeatures'->new($_) } @$_ ] };

declare 'MapStringExperimentalFeatures',
    as HashRef[ExperimentalFeatures()];

declare 'NodeSettings',
    as InstanceOf['Google::Api::Client::NodeSettings'];

coerce 'NodeSettings',
    from HashRef, via { 'Google::Api::Client::NodeSettings'->new($_) };

declare 'RepeatedNodeSettings',
    as ArrayRef[NodeSettings()];

coerce 'RepeatedNodeSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::NodeSettings'->new($_) } @$_ ] };

declare 'MapStringNodeSettings',
    as HashRef[NodeSettings()];

declare 'DotnetSettings',
    as InstanceOf['Google::Api::Client::DotnetSettings'];

coerce 'DotnetSettings',
    from HashRef, via { 'Google::Api::Client::DotnetSettings'->new($_) };

declare 'RepeatedDotnetSettings',
    as ArrayRef[DotnetSettings()];

coerce 'RepeatedDotnetSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::DotnetSettings'->new($_) } @$_ ] };

declare 'MapStringDotnetSettings',
    as HashRef[DotnetSettings()];

declare 'RenamedServicesEntry',
    as InstanceOf['Google::Api::Client::DotnetSettings::RenamedServicesEntry'];

coerce 'RenamedServicesEntry',
    from HashRef, via { 'Google::Api::Client::DotnetSettings::RenamedServicesEntry'->new($_) };

declare 'RepeatedRenamedServicesEntry',
    as ArrayRef[RenamedServicesEntry()];

coerce 'RepeatedRenamedServicesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::DotnetSettings::RenamedServicesEntry'->new($_) } @$_ ] };

declare 'MapStringRenamedServicesEntry',
    as HashRef[RenamedServicesEntry()];

declare 'RenamedResourcesEntry',
    as InstanceOf['Google::Api::Client::DotnetSettings::RenamedResourcesEntry'];

coerce 'RenamedResourcesEntry',
    from HashRef, via { 'Google::Api::Client::DotnetSettings::RenamedResourcesEntry'->new($_) };

declare 'RepeatedRenamedResourcesEntry',
    as ArrayRef[RenamedResourcesEntry()];

coerce 'RepeatedRenamedResourcesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::DotnetSettings::RenamedResourcesEntry'->new($_) } @$_ ] };

declare 'MapStringRenamedResourcesEntry',
    as HashRef[RenamedResourcesEntry()];

declare 'RubySettings',
    as InstanceOf['Google::Api::Client::RubySettings'];

coerce 'RubySettings',
    from HashRef, via { 'Google::Api::Client::RubySettings'->new($_) };

declare 'RepeatedRubySettings',
    as ArrayRef[RubySettings()];

coerce 'RepeatedRubySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::RubySettings'->new($_) } @$_ ] };

declare 'MapStringRubySettings',
    as HashRef[RubySettings()];

declare 'GoSettings',
    as InstanceOf['Google::Api::Client::GoSettings'];

coerce 'GoSettings',
    from HashRef, via { 'Google::Api::Client::GoSettings'->new($_) };

declare 'RepeatedGoSettings',
    as ArrayRef[GoSettings()];

coerce 'RepeatedGoSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::GoSettings'->new($_) } @$_ ] };

declare 'MapStringGoSettings',
    as HashRef[GoSettings()];

declare 'RenamedServicesEntry',
    as InstanceOf['Google::Api::Client::GoSettings::RenamedServicesEntry'];

coerce 'RenamedServicesEntry',
    from HashRef, via { 'Google::Api::Client::GoSettings::RenamedServicesEntry'->new($_) };

declare 'RepeatedRenamedServicesEntry',
    as ArrayRef[RenamedServicesEntry()];

coerce 'RepeatedRenamedServicesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::GoSettings::RenamedServicesEntry'->new($_) } @$_ ] };

declare 'MapStringRenamedServicesEntry',
    as HashRef[RenamedServicesEntry()];

declare 'MethodSettings',
    as InstanceOf['Google::Api::Client::MethodSettings'];

coerce 'MethodSettings',
    from HashRef, via { 'Google::Api::Client::MethodSettings'->new($_) };

declare 'RepeatedMethodSettings',
    as ArrayRef[MethodSettings()];

coerce 'RepeatedMethodSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::MethodSettings'->new($_) } @$_ ] };

declare 'MapStringMethodSettings',
    as HashRef[MethodSettings()];

declare 'LongRunning',
    as InstanceOf['Google::Api::Client::MethodSettings::LongRunning'];

coerce 'LongRunning',
    from HashRef, via { 'Google::Api::Client::MethodSettings::LongRunning'->new($_) };

declare 'RepeatedLongRunning',
    as ArrayRef[LongRunning()];

coerce 'RepeatedLongRunning',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::MethodSettings::LongRunning'->new($_) } @$_ ] };

declare 'MapStringLongRunning',
    as HashRef[LongRunning()];

declare 'SelectiveGapicGeneration',
    as InstanceOf['Google::Api::Client::SelectiveGapicGeneration'];

coerce 'SelectiveGapicGeneration',
    from HashRef, via { 'Google::Api::Client::SelectiveGapicGeneration'->new($_) };

declare 'RepeatedSelectiveGapicGeneration',
    as ArrayRef[SelectiveGapicGeneration()];

coerce 'RepeatedSelectiveGapicGeneration',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::SelectiveGapicGeneration'->new($_) } @$_ ] };

declare 'MapStringSelectiveGapicGeneration',
    as HashRef[SelectiveGapicGeneration()];

declare 'BatchingConfigProto',
    as InstanceOf['Google::Api::Client::BatchingConfigProto'];

coerce 'BatchingConfigProto',
    from HashRef, via { 'Google::Api::Client::BatchingConfigProto'->new($_) };

declare 'RepeatedBatchingConfigProto',
    as ArrayRef[BatchingConfigProto()];

coerce 'RepeatedBatchingConfigProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::BatchingConfigProto'->new($_) } @$_ ] };

declare 'MapStringBatchingConfigProto',
    as HashRef[BatchingConfigProto()];

declare 'BatchingSettingsProto',
    as InstanceOf['Google::Api::Client::BatchingSettingsProto'];

coerce 'BatchingSettingsProto',
    from HashRef, via { 'Google::Api::Client::BatchingSettingsProto'->new($_) };

declare 'RepeatedBatchingSettingsProto',
    as ArrayRef[BatchingSettingsProto()];

coerce 'RepeatedBatchingSettingsProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::BatchingSettingsProto'->new($_) } @$_ ] };

declare 'MapStringBatchingSettingsProto',
    as HashRef[BatchingSettingsProto()];

declare 'BatchingDescriptorProto',
    as InstanceOf['Google::Api::Client::BatchingDescriptorProto'];

coerce 'BatchingDescriptorProto',
    from HashRef, via { 'Google::Api::Client::BatchingDescriptorProto'->new($_) };

declare 'RepeatedBatchingDescriptorProto',
    as ArrayRef[BatchingDescriptorProto()];

coerce 'RepeatedBatchingDescriptorProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Client::BatchingDescriptorProto'->new($_) } @$_ ] };

declare 'MapStringBatchingDescriptorProto',
    as HashRef[BatchingDescriptorProto()];

1;
