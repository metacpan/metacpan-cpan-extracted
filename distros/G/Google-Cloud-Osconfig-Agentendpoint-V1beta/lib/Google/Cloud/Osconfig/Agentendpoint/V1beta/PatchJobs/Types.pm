package Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PatchConfig',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::PatchConfig'];

coerce 'PatchConfig',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::PatchConfig'->new($_) };

declare 'RepeatedPatchConfig',
    as ArrayRef[PatchConfig()];

coerce 'RepeatedPatchConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::PatchConfig'->new($_) } @$_ ] };

declare 'MapStringPatchConfig',
    as HashRef[PatchConfig()];

declare 'RebootConfig',
    as (Int | Str);

declare 'AptSettings',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::AptSettings'];

coerce 'AptSettings',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::AptSettings'->new($_) };

declare 'RepeatedAptSettings',
    as ArrayRef[AptSettings()];

coerce 'RepeatedAptSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::AptSettings'->new($_) } @$_ ] };

declare 'MapStringAptSettings',
    as HashRef[AptSettings()];

declare 'Type',
    as (Int | Str);

declare 'YumSettings',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::YumSettings'];

coerce 'YumSettings',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::YumSettings'->new($_) };

declare 'RepeatedYumSettings',
    as ArrayRef[YumSettings()];

coerce 'RepeatedYumSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::YumSettings'->new($_) } @$_ ] };

declare 'MapStringYumSettings',
    as HashRef[YumSettings()];

declare 'GooSettings',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::GooSettings'];

coerce 'GooSettings',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::GooSettings'->new($_) };

declare 'RepeatedGooSettings',
    as ArrayRef[GooSettings()];

coerce 'RepeatedGooSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::GooSettings'->new($_) } @$_ ] };

declare 'MapStringGooSettings',
    as HashRef[GooSettings()];

declare 'ZypperSettings',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ZypperSettings'];

coerce 'ZypperSettings',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ZypperSettings'->new($_) };

declare 'RepeatedZypperSettings',
    as ArrayRef[ZypperSettings()];

coerce 'RepeatedZypperSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ZypperSettings'->new($_) } @$_ ] };

declare 'MapStringZypperSettings',
    as HashRef[ZypperSettings()];

declare 'WindowsUpdateSettings',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::WindowsUpdateSettings'];

coerce 'WindowsUpdateSettings',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::WindowsUpdateSettings'->new($_) };

declare 'RepeatedWindowsUpdateSettings',
    as ArrayRef[WindowsUpdateSettings()];

coerce 'RepeatedWindowsUpdateSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::WindowsUpdateSettings'->new($_) } @$_ ] };

declare 'MapStringWindowsUpdateSettings',
    as HashRef[WindowsUpdateSettings()];

declare 'Classification',
    as (Int | Str);

declare 'RetryStrategy',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::RetryStrategy'];

coerce 'RetryStrategy',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::RetryStrategy'->new($_) };

declare 'RepeatedRetryStrategy',
    as ArrayRef[RetryStrategy()];

coerce 'RepeatedRetryStrategy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::RetryStrategy'->new($_) } @$_ ] };

declare 'MapStringRetryStrategy',
    as HashRef[RetryStrategy()];

declare 'ExecStep',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStep'];

coerce 'ExecStep',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStep'->new($_) };

declare 'RepeatedExecStep',
    as ArrayRef[ExecStep()];

coerce 'RepeatedExecStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStep'->new($_) } @$_ ] };

declare 'MapStringExecStep',
    as HashRef[ExecStep()];

declare 'ExecStepConfig',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStepConfig'];

coerce 'ExecStepConfig',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStepConfig'->new($_) };

declare 'RepeatedExecStepConfig',
    as ArrayRef[ExecStepConfig()];

coerce 'RepeatedExecStepConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::ExecStepConfig'->new($_) } @$_ ] };

declare 'MapStringExecStepConfig',
    as HashRef[ExecStepConfig()];

declare 'Interpreter',
    as (Int | Str);

declare 'GcsObject',
    as InstanceOf['Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::GcsObject'];

coerce 'GcsObject',
    from HashRef, via { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::GcsObject'->new($_) };

declare 'RepeatedGcsObject',
    as ArrayRef[GcsObject()];

coerce 'RepeatedGcsObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::GcsObject'->new($_) } @$_ ] };

declare 'MapStringGcsObject',
    as HashRef[GcsObject()];

1;

__END__

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
