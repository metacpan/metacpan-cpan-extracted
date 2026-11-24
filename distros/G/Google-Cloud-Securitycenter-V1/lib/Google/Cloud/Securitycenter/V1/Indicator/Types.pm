package Google::Cloud::Securitycenter::V1::Indicator::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Indicator',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Indicator::Indicator'];

coerce 'Indicator',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Indicator::Indicator'->new($_) };

declare 'RepeatedIndicator',
    as ArrayRef[Indicator()];

coerce 'RepeatedIndicator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Indicator::Indicator'->new($_) } @$_ ] };

declare 'MapStringIndicator',
    as HashRef[Indicator()];

declare 'ProcessSignature',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Indicator::Indicator::ProcessSignature'];

coerce 'ProcessSignature',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Indicator::Indicator::ProcessSignature'->new($_) };

declare 'RepeatedProcessSignature',
    as ArrayRef[ProcessSignature()];

coerce 'RepeatedProcessSignature',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Indicator::Indicator::ProcessSignature'->new($_) } @$_ ] };

declare 'MapStringProcessSignature',
    as HashRef[ProcessSignature()];

declare 'SignatureType',
    as (Int | Str);

declare 'MemoryHashSignature',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Indicator::Indicator::ProcessSignature::MemoryHashSignature'];

coerce 'MemoryHashSignature',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Indicator::Indicator::ProcessSignature::MemoryHashSignature'->new($_) };

declare 'RepeatedMemoryHashSignature',
    as ArrayRef[MemoryHashSignature()];

coerce 'RepeatedMemoryHashSignature',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Indicator::Indicator::ProcessSignature::MemoryHashSignature'->new($_) } @$_ ] };

declare 'MapStringMemoryHashSignature',
    as HashRef[MemoryHashSignature()];

declare 'Detection',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Indicator::Indicator::ProcessSignature::MemoryHashSignature::Detection'];

coerce 'Detection',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Indicator::Indicator::ProcessSignature::MemoryHashSignature::Detection'->new($_) };

declare 'RepeatedDetection',
    as ArrayRef[Detection()];

coerce 'RepeatedDetection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Indicator::Indicator::ProcessSignature::MemoryHashSignature::Detection'->new($_) } @$_ ] };

declare 'MapStringDetection',
    as HashRef[Detection()];

declare 'YaraRuleSignature',
    as InstanceOf['Google::Cloud::Securitycenter::V1::Indicator::Indicator::ProcessSignature::YaraRuleSignature'];

coerce 'YaraRuleSignature',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::Indicator::Indicator::ProcessSignature::YaraRuleSignature'->new($_) };

declare 'RepeatedYaraRuleSignature',
    as ArrayRef[YaraRuleSignature()];

coerce 'RepeatedYaraRuleSignature',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::Indicator::Indicator::ProcessSignature::YaraRuleSignature'->new($_) } @$_ ] };

declare 'MapStringYaraRuleSignature',
    as HashRef[YaraRuleSignature()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::Indicator::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
