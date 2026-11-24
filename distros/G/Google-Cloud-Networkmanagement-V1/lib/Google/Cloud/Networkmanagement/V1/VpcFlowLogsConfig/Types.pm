package Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VpcFlowLogsConfig',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig'];

coerce 'VpcFlowLogsConfig',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig'->new($_) };

declare 'RepeatedVpcFlowLogsConfig',
    as ArrayRef[VpcFlowLogsConfig()];

coerce 'RepeatedVpcFlowLogsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig'->new($_) } @$_ ] };

declare 'MapStringVpcFlowLogsConfig',
    as HashRef[VpcFlowLogsConfig()];

declare 'State',
    as (Int | Str);

declare 'AggregationInterval',
    as (Int | Str);

declare 'Metadata',
    as (Int | Str);

declare 'CrossProjectMetadata',
    as (Int | Str);

declare 'TargetResourceState',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::VpcFlowLogsConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'EffectiveVpcFlowLogsConfig',
    as InstanceOf['Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::EffectiveVpcFlowLogsConfig'];

coerce 'EffectiveVpcFlowLogsConfig',
    from HashRef, via { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::EffectiveVpcFlowLogsConfig'->new($_) };

declare 'RepeatedEffectiveVpcFlowLogsConfig',
    as ArrayRef[EffectiveVpcFlowLogsConfig()];

coerce 'RepeatedEffectiveVpcFlowLogsConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::EffectiveVpcFlowLogsConfig'->new($_) } @$_ ] };

declare 'MapStringEffectiveVpcFlowLogsConfig',
    as HashRef[EffectiveVpcFlowLogsConfig()];

declare 'Scope',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
