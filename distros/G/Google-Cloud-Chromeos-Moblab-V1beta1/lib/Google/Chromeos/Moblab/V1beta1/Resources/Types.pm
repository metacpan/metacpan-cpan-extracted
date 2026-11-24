package Google::Chromeos::Moblab::V1beta1::Resources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BuildTarget',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::BuildTarget'];

coerce 'BuildTarget',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::BuildTarget'->new($_) };

declare 'RepeatedBuildTarget',
    as ArrayRef[BuildTarget()];

coerce 'RepeatedBuildTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::BuildTarget'->new($_) } @$_ ] };

declare 'MapStringBuildTarget',
    as HashRef[BuildTarget()];

declare 'Model',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::Model'];

coerce 'Model',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::Model'->new($_) };

declare 'RepeatedModel',
    as ArrayRef[Model()];

coerce 'RepeatedModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::Model'->new($_) } @$_ ] };

declare 'MapStringModel',
    as HashRef[Model()];

declare 'Milestone',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::Milestone'];

coerce 'Milestone',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::Milestone'->new($_) };

declare 'RepeatedMilestone',
    as ArrayRef[Milestone()];

coerce 'RepeatedMilestone',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::Milestone'->new($_) } @$_ ] };

declare 'MapStringMilestone',
    as HashRef[Milestone()];

declare 'Build',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::Build'];

coerce 'Build',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::Build'->new($_) };

declare 'RepeatedBuild',
    as ArrayRef[Build()];

coerce 'RepeatedBuild',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::Build'->new($_) } @$_ ] };

declare 'MapStringBuild',
    as HashRef[Build()];

declare 'BuildStatus',
    as (Int | Str);

declare 'BuildType',
    as (Int | Str);

declare 'BuildArtifact',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::BuildArtifact'];

coerce 'BuildArtifact',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::BuildArtifact'->new($_) };

declare 'RepeatedBuildArtifact',
    as ArrayRef[BuildArtifact()];

coerce 'RepeatedBuildArtifact',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::BuildArtifact'->new($_) } @$_ ] };

declare 'MapStringBuildArtifact',
    as HashRef[BuildArtifact()];

declare 'CloudBuild',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::CloudBuild'];

coerce 'CloudBuild',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::CloudBuild'->new($_) };

declare 'RepeatedCloudBuild',
    as ArrayRef[CloudBuild()];

coerce 'RepeatedCloudBuild',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::CloudBuild'->new($_) } @$_ ] };

declare 'MapStringCloudBuild',
    as HashRef[CloudBuild()];

declare 'State',
    as (Int | Str);

declare 'Session',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::Session'];

coerce 'Session',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::Session'->new($_) };

declare 'RepeatedSession',
    as ArrayRef[Session()];

coerce 'RepeatedSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::Session'->new($_) } @$_ ] };

declare 'MapStringSession',
    as HashRef[Session()];

declare 'State',
    as (Int | Str);

declare 'Result',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

declare 'DimensionsEntry',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::Session::DimensionsEntry'];

coerce 'DimensionsEntry',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::Session::DimensionsEntry'->new($_) };

declare 'RepeatedDimensionsEntry',
    as ArrayRef[DimensionsEntry()];

coerce 'RepeatedDimensionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::Session::DimensionsEntry'->new($_) } @$_ ] };

declare 'MapStringDimensionsEntry',
    as HashRef[DimensionsEntry()];

declare 'Timeout',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::Timeout'];

coerce 'Timeout',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::Timeout'->new($_) };

declare 'RepeatedTimeout',
    as ArrayRef[Timeout()];

coerce 'RepeatedTimeout',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::Timeout'->new($_) } @$_ ] };

declare 'MapStringTimeout',
    as HashRef[Timeout()];

declare 'TradefedTest',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::TradefedTest'];

coerce 'TradefedTest',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::TradefedTest'->new($_) };

declare 'RepeatedTradefedTest',
    as ArrayRef[TradefedTest()];

coerce 'RepeatedTradefedTest',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::TradefedTest'->new($_) } @$_ ] };

declare 'MapStringTradefedTest',
    as HashRef[TradefedTest()];

declare 'ShardArgsEntry',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::TradefedTest::ShardArgsEntry'];

coerce 'ShardArgsEntry',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::TradefedTest::ShardArgsEntry'->new($_) };

declare 'RepeatedShardArgsEntry',
    as ArrayRef[ShardArgsEntry()];

coerce 'RepeatedShardArgsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::TradefedTest::ShardArgsEntry'->new($_) } @$_ ] };

declare 'MapStringShardArgsEntry',
    as HashRef[ShardArgsEntry()];

declare 'TestEffort',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::TestEffort'];

coerce 'TestEffort',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort'->new($_) };

declare 'RepeatedTestEffort',
    as ArrayRef[TestEffort()];

coerce 'RepeatedTestEffort',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort'->new($_) } @$_ ] };

declare 'MapStringTestEffort',
    as HashRef[TestEffort()];

declare 'State',
    as (Int | Str);

declare 'FirmwareType',
    as (Int | Str);

declare 'BoardModel',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::BoardModel'];

coerce 'BoardModel',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::BoardModel'->new($_) };

declare 'RepeatedBoardModel',
    as ArrayRef[BoardModel()];

coerce 'RepeatedBoardModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::BoardModel'->new($_) } @$_ ] };

declare 'MapStringBoardModel',
    as HashRef[BoardModel()];

declare 'Pool',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::Pool'];

coerce 'Pool',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::Pool'->new($_) };

declare 'RepeatedPool',
    as ArrayRef[Pool()];

coerce 'RepeatedPool',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::Pool'->new($_) } @$_ ] };

declare 'MapStringPool',
    as HashRef[Pool()];

declare 'PoolType',
    as (Int | Str);

declare 'AndroidBuildTarget',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::AndroidBuildTarget'];

coerce 'AndroidBuildTarget',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::AndroidBuildTarget'->new($_) };

declare 'RepeatedAndroidBuildTarget',
    as ArrayRef[AndroidBuildTarget()];

coerce 'RepeatedAndroidBuildTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::AndroidBuildTarget'->new($_) } @$_ ] };

declare 'MapStringAndroidBuildTarget',
    as HashRef[AndroidBuildTarget()];

declare 'FirmwareTestEffortVersion',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::FirmwareTestEffortVersion'];

coerce 'FirmwareTestEffortVersion',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::FirmwareTestEffortVersion'->new($_) };

declare 'RepeatedFirmwareTestEffortVersion',
    as ArrayRef[FirmwareTestEffortVersion()];

coerce 'RepeatedFirmwareTestEffortVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::FirmwareTestEffortVersion'->new($_) } @$_ ] };

declare 'MapStringFirmwareTestEffortVersion',
    as HashRef[FirmwareTestEffortVersion()];

declare 'GscTestEffortVersion',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::GscTestEffortVersion'];

coerce 'GscTestEffortVersion',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::GscTestEffortVersion'->new($_) };

declare 'RepeatedGscTestEffortVersion',
    as ArrayRef[GscTestEffortVersion()];

coerce 'RepeatedGscTestEffortVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::GscTestEffortVersion'->new($_) } @$_ ] };

declare 'MapStringGscTestEffortVersion',
    as HashRef[GscTestEffortVersion()];

declare 'FirmwareTarget',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::FirmwareTarget'];

coerce 'FirmwareTarget',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::FirmwareTarget'->new($_) };

declare 'RepeatedFirmwareTarget',
    as ArrayRef[FirmwareTarget()];

coerce 'RepeatedFirmwareTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::FirmwareTarget'->new($_) } @$_ ] };

declare 'MapStringFirmwareTarget',
    as HashRef[FirmwareTarget()];

declare 'FirmwareConfig',
    as InstanceOf['Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::FirmwareConfig'];

coerce 'FirmwareConfig',
    from HashRef, via { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::FirmwareConfig'->new($_) };

declare 'RepeatedFirmwareConfig',
    as ArrayRef[FirmwareConfig()];

coerce 'RepeatedFirmwareConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort::FirmwareConfig'->new($_) } @$_ ] };

declare 'MapStringFirmwareConfig',
    as HashRef[FirmwareConfig()];

1;

__END__

=head1 NAME

Google::Chromeos::Moblab::V1beta1::Resources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
