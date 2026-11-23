package Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BlueGreenDeployment',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment'];

coerce 'BlueGreenDeployment',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment'->new($_) };

declare 'RepeatedBlueGreenDeployment',
    as ArrayRef[BlueGreenDeployment()];

coerce 'RepeatedBlueGreenDeployment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment'->new($_) } @$_ ] };

declare 'MapStringBlueGreenDeployment',
    as HashRef[BlueGreenDeployment()];

declare 'State',
    as (Int | Str);

declare 'RequestedConfig',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::RequestedConfig'];

coerce 'RequestedConfig',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::RequestedConfig'->new($_) };

declare 'RepeatedRequestedConfig',
    as ArrayRef[RequestedConfig()];

coerce 'RepeatedRequestedConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::RequestedConfig'->new($_) } @$_ ] };

declare 'MapStringRequestedConfig',
    as HashRef[RequestedConfig()];

declare 'DeploymentTasks',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::DeploymentTasks'];

coerce 'DeploymentTasks',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::DeploymentTasks'->new($_) };

declare 'RepeatedDeploymentTasks',
    as ArrayRef[DeploymentTasks()];

coerce 'RepeatedDeploymentTasks',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::DeploymentTasks'->new($_) } @$_ ] };

declare 'MapStringDeploymentTasks',
    as HashRef[DeploymentTasks()];

declare 'SourceTargetPairedNode',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::SourceTargetPairedNode'];

coerce 'SourceTargetPairedNode',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::SourceTargetPairedNode'->new($_) };

declare 'RepeatedSourceTargetPairedNode',
    as ArrayRef[SourceTargetPairedNode()];

coerce 'RepeatedSourceTargetPairedNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::SourceTargetPairedNode'->new($_) } @$_ ] };

declare 'MapStringSourceTargetPairedNode',
    as HashRef[SourceTargetPairedNode()];

declare 'State',
    as (Int | Str);

declare 'ConfigDiff',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::SourceTargetPairedNode::ConfigDiff'];

coerce 'ConfigDiff',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::SourceTargetPairedNode::ConfigDiff'->new($_) };

declare 'RepeatedConfigDiff',
    as ArrayRef[ConfigDiff()];

coerce 'RepeatedConfigDiff',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::SourceTargetPairedNode::ConfigDiff'->new($_) } @$_ ] };

declare 'MapStringConfigDiff',
    as HashRef[ConfigDiff()];

declare 'NodeInfo',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::SourceTargetPairedNode::NodeInfo'];

coerce 'NodeInfo',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::SourceTargetPairedNode::NodeInfo'->new($_) };

declare 'RepeatedNodeInfo',
    as ArrayRef[NodeInfo()];

coerce 'RepeatedNodeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::SourceTargetPairedNode::NodeInfo'->new($_) } @$_ ] };

declare 'MapStringNodeInfo',
    as HashRef[NodeInfo()];

declare 'DeploymentTask',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::SourceTargetPairedNode::DeploymentTask'];

coerce 'DeploymentTask',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::SourceTargetPairedNode::DeploymentTask'->new($_) };

declare 'RepeatedDeploymentTask',
    as ArrayRef[DeploymentTask()];

coerce 'RepeatedDeploymentTask',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::BlueGreenDeployment::SourceTargetPairedNode::DeploymentTask'->new($_) } @$_ ] };

declare 'MapStringDeploymentTask',
    as HashRef[DeploymentTask()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'CreateBlueGreenDeploymentRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::CreateBlueGreenDeploymentRequest'];

coerce 'CreateBlueGreenDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::CreateBlueGreenDeploymentRequest'->new($_) };

declare 'RepeatedCreateBlueGreenDeploymentRequest',
    as ArrayRef[CreateBlueGreenDeploymentRequest()];

coerce 'RepeatedCreateBlueGreenDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::CreateBlueGreenDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateBlueGreenDeploymentRequest',
    as HashRef[CreateBlueGreenDeploymentRequest()];

declare 'GetBlueGreenDeploymentRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::GetBlueGreenDeploymentRequest'];

coerce 'GetBlueGreenDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::GetBlueGreenDeploymentRequest'->new($_) };

declare 'RepeatedGetBlueGreenDeploymentRequest',
    as ArrayRef[GetBlueGreenDeploymentRequest()];

coerce 'RepeatedGetBlueGreenDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::GetBlueGreenDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringGetBlueGreenDeploymentRequest',
    as HashRef[GetBlueGreenDeploymentRequest()];

declare 'BlueGreenDeploymentView',
    as (Int | Str);

declare 'SwitchoverBlueGreenDeploymentRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::SwitchoverBlueGreenDeploymentRequest'];

coerce 'SwitchoverBlueGreenDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::SwitchoverBlueGreenDeploymentRequest'->new($_) };

declare 'RepeatedSwitchoverBlueGreenDeploymentRequest',
    as ArrayRef[SwitchoverBlueGreenDeploymentRequest()];

coerce 'RepeatedSwitchoverBlueGreenDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::SwitchoverBlueGreenDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringSwitchoverBlueGreenDeploymentRequest',
    as HashRef[SwitchoverBlueGreenDeploymentRequest()];

declare 'ListBlueGreenDeploymentsRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::ListBlueGreenDeploymentsRequest'];

coerce 'ListBlueGreenDeploymentsRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::ListBlueGreenDeploymentsRequest'->new($_) };

declare 'RepeatedListBlueGreenDeploymentsRequest',
    as ArrayRef[ListBlueGreenDeploymentsRequest()];

coerce 'RepeatedListBlueGreenDeploymentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::ListBlueGreenDeploymentsRequest'->new($_) } @$_ ] };

declare 'MapStringListBlueGreenDeploymentsRequest',
    as HashRef[ListBlueGreenDeploymentsRequest()];

declare 'ListBlueGreenDeploymentsResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::ListBlueGreenDeploymentsResponse'];

coerce 'ListBlueGreenDeploymentsResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::ListBlueGreenDeploymentsResponse'->new($_) };

declare 'RepeatedListBlueGreenDeploymentsResponse',
    as ArrayRef[ListBlueGreenDeploymentsResponse()];

coerce 'RepeatedListBlueGreenDeploymentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::ListBlueGreenDeploymentsResponse'->new($_) } @$_ ] };

declare 'MapStringListBlueGreenDeploymentsResponse',
    as HashRef[ListBlueGreenDeploymentsResponse()];

declare 'DeleteBlueGreenDeploymentRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::DeleteBlueGreenDeploymentRequest'];

coerce 'DeleteBlueGreenDeploymentRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::DeleteBlueGreenDeploymentRequest'->new($_) };

declare 'RepeatedDeleteBlueGreenDeploymentRequest',
    as ArrayRef[DeleteBlueGreenDeploymentRequest()];

coerce 'RepeatedDeleteBlueGreenDeploymentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::DeleteBlueGreenDeploymentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteBlueGreenDeploymentRequest',
    as HashRef[DeleteBlueGreenDeploymentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlBlueGreenDeployments::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
