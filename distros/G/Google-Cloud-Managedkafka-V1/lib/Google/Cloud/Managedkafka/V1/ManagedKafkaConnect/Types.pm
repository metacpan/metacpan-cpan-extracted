package Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetConnectClusterRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectClusterRequest'];

coerce 'GetConnectClusterRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectClusterRequest'->new($_) };

declare 'RepeatedGetConnectClusterRequest',
    as ArrayRef[GetConnectClusterRequest()];

coerce 'RepeatedGetConnectClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectClusterRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectClusterRequest',
    as HashRef[GetConnectClusterRequest()];

declare 'CreateConnectClusterRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::CreateConnectClusterRequest'];

coerce 'CreateConnectClusterRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::CreateConnectClusterRequest'->new($_) };

declare 'RepeatedCreateConnectClusterRequest',
    as ArrayRef[CreateConnectClusterRequest()];

coerce 'RepeatedCreateConnectClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::CreateConnectClusterRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConnectClusterRequest',
    as HashRef[CreateConnectClusterRequest()];

declare 'UpdateConnectClusterRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::UpdateConnectClusterRequest'];

coerce 'UpdateConnectClusterRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::UpdateConnectClusterRequest'->new($_) };

declare 'RepeatedUpdateConnectClusterRequest',
    as ArrayRef[UpdateConnectClusterRequest()];

coerce 'RepeatedUpdateConnectClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::UpdateConnectClusterRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConnectClusterRequest',
    as HashRef[UpdateConnectClusterRequest()];

declare 'DeleteConnectClusterRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::DeleteConnectClusterRequest'];

coerce 'DeleteConnectClusterRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::DeleteConnectClusterRequest'->new($_) };

declare 'RepeatedDeleteConnectClusterRequest',
    as ArrayRef[DeleteConnectClusterRequest()];

coerce 'RepeatedDeleteConnectClusterRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::DeleteConnectClusterRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConnectClusterRequest',
    as HashRef[DeleteConnectClusterRequest()];

declare 'ListConnectClustersRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectClustersRequest'];

coerce 'ListConnectClustersRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectClustersRequest'->new($_) };

declare 'RepeatedListConnectClustersRequest',
    as ArrayRef[ListConnectClustersRequest()];

coerce 'RepeatedListConnectClustersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectClustersRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectClustersRequest',
    as HashRef[ListConnectClustersRequest()];

declare 'ListConnectClustersResponse',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectClustersResponse'];

coerce 'ListConnectClustersResponse',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectClustersResponse'->new($_) };

declare 'RepeatedListConnectClustersResponse',
    as ArrayRef[ListConnectClustersResponse()];

coerce 'RepeatedListConnectClustersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectClustersResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectClustersResponse',
    as HashRef[ListConnectClustersResponse()];

declare 'GetConnectorRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectorRequest'];

coerce 'GetConnectorRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectorRequest'->new($_) };

declare 'RepeatedGetConnectorRequest',
    as ArrayRef[GetConnectorRequest()];

coerce 'RepeatedGetConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::GetConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectorRequest',
    as HashRef[GetConnectorRequest()];

declare 'CreateConnectorRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::CreateConnectorRequest'];

coerce 'CreateConnectorRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::CreateConnectorRequest'->new($_) };

declare 'RepeatedCreateConnectorRequest',
    as ArrayRef[CreateConnectorRequest()];

coerce 'RepeatedCreateConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::CreateConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConnectorRequest',
    as HashRef[CreateConnectorRequest()];

declare 'UpdateConnectorRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::UpdateConnectorRequest'];

coerce 'UpdateConnectorRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::UpdateConnectorRequest'->new($_) };

declare 'RepeatedUpdateConnectorRequest',
    as ArrayRef[UpdateConnectorRequest()];

coerce 'RepeatedUpdateConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::UpdateConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConnectorRequest',
    as HashRef[UpdateConnectorRequest()];

declare 'DeleteConnectorRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::DeleteConnectorRequest'];

coerce 'DeleteConnectorRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::DeleteConnectorRequest'->new($_) };

declare 'RepeatedDeleteConnectorRequest',
    as ArrayRef[DeleteConnectorRequest()];

coerce 'RepeatedDeleteConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::DeleteConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConnectorRequest',
    as HashRef[DeleteConnectorRequest()];

declare 'ListConnectorsRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectorsRequest'];

coerce 'ListConnectorsRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectorsRequest'->new($_) };

declare 'RepeatedListConnectorsRequest',
    as ArrayRef[ListConnectorsRequest()];

coerce 'RepeatedListConnectorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectorsRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectorsRequest',
    as HashRef[ListConnectorsRequest()];

declare 'ListConnectorsResponse',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectorsResponse'];

coerce 'ListConnectorsResponse',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectorsResponse'->new($_) };

declare 'RepeatedListConnectorsResponse',
    as ArrayRef[ListConnectorsResponse()];

coerce 'RepeatedListConnectorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ListConnectorsResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectorsResponse',
    as HashRef[ListConnectorsResponse()];

declare 'PauseConnectorRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::PauseConnectorRequest'];

coerce 'PauseConnectorRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::PauseConnectorRequest'->new($_) };

declare 'RepeatedPauseConnectorRequest',
    as ArrayRef[PauseConnectorRequest()];

coerce 'RepeatedPauseConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::PauseConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringPauseConnectorRequest',
    as HashRef[PauseConnectorRequest()];

declare 'PauseConnectorResponse',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::PauseConnectorResponse'];

coerce 'PauseConnectorResponse',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::PauseConnectorResponse'->new($_) };

declare 'RepeatedPauseConnectorResponse',
    as ArrayRef[PauseConnectorResponse()];

coerce 'RepeatedPauseConnectorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::PauseConnectorResponse'->new($_) } @$_ ] };

declare 'MapStringPauseConnectorResponse',
    as HashRef[PauseConnectorResponse()];

declare 'ResumeConnectorRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ResumeConnectorRequest'];

coerce 'ResumeConnectorRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ResumeConnectorRequest'->new($_) };

declare 'RepeatedResumeConnectorRequest',
    as ArrayRef[ResumeConnectorRequest()];

coerce 'RepeatedResumeConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ResumeConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringResumeConnectorRequest',
    as HashRef[ResumeConnectorRequest()];

declare 'ResumeConnectorResponse',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ResumeConnectorResponse'];

coerce 'ResumeConnectorResponse',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ResumeConnectorResponse'->new($_) };

declare 'RepeatedResumeConnectorResponse',
    as ArrayRef[ResumeConnectorResponse()];

coerce 'RepeatedResumeConnectorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::ResumeConnectorResponse'->new($_) } @$_ ] };

declare 'MapStringResumeConnectorResponse',
    as HashRef[ResumeConnectorResponse()];

declare 'RestartConnectorRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::RestartConnectorRequest'];

coerce 'RestartConnectorRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::RestartConnectorRequest'->new($_) };

declare 'RepeatedRestartConnectorRequest',
    as ArrayRef[RestartConnectorRequest()];

coerce 'RepeatedRestartConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::RestartConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringRestartConnectorRequest',
    as HashRef[RestartConnectorRequest()];

declare 'RestartConnectorResponse',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::RestartConnectorResponse'];

coerce 'RestartConnectorResponse',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::RestartConnectorResponse'->new($_) };

declare 'RepeatedRestartConnectorResponse',
    as ArrayRef[RestartConnectorResponse()];

coerce 'RepeatedRestartConnectorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::RestartConnectorResponse'->new($_) } @$_ ] };

declare 'MapStringRestartConnectorResponse',
    as HashRef[RestartConnectorResponse()];

declare 'StopConnectorRequest',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::StopConnectorRequest'];

coerce 'StopConnectorRequest',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::StopConnectorRequest'->new($_) };

declare 'RepeatedStopConnectorRequest',
    as ArrayRef[StopConnectorRequest()];

coerce 'RepeatedStopConnectorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::StopConnectorRequest'->new($_) } @$_ ] };

declare 'MapStringStopConnectorRequest',
    as HashRef[StopConnectorRequest()];

declare 'StopConnectorResponse',
    as InstanceOf['Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::StopConnectorResponse'];

coerce 'StopConnectorResponse',
    from HashRef, via { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::StopConnectorResponse'->new($_) };

declare 'RepeatedStopConnectorResponse',
    as ArrayRef[StopConnectorResponse()];

coerce 'RepeatedStopConnectorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::StopConnectorResponse'->new($_) } @$_ ] };

declare 'MapStringStopConnectorResponse',
    as HashRef[StopConnectorResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Managedkafka::V1::ManagedKafkaConnect::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
