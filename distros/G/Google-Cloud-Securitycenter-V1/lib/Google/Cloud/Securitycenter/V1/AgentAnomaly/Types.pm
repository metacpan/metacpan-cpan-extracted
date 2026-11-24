package Google::Cloud::Securitycenter::V1::AgentAnomaly::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AgentAnomaly',
    as InstanceOf['Google::Cloud::Securitycenter::V1::AgentAnomaly::AgentAnomaly'];

coerce 'AgentAnomaly',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::AgentAnomaly::AgentAnomaly'->new($_) };

declare 'RepeatedAgentAnomaly',
    as ArrayRef[AgentAnomaly()];

coerce 'RepeatedAgentAnomaly',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::AgentAnomaly::AgentAnomaly'->new($_) } @$_ ] };

declare 'MapStringAgentAnomaly',
    as HashRef[AgentAnomaly()];

declare 'DetectorReference',
    as InstanceOf['Google::Cloud::Securitycenter::V1::AgentAnomaly::DetectorReference'];

coerce 'DetectorReference',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::AgentAnomaly::DetectorReference'->new($_) };

declare 'RepeatedDetectorReference',
    as ArrayRef[DetectorReference()];

coerce 'RepeatedDetectorReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::AgentAnomaly::DetectorReference'->new($_) } @$_ ] };

declare 'MapStringDetectorReference',
    as HashRef[DetectorReference()];

declare 'Severity',
    as (Int | Str);

declare 'InvocationReference',
    as InstanceOf['Google::Cloud::Securitycenter::V1::AgentAnomaly::InvocationReference'];

coerce 'InvocationReference',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::AgentAnomaly::InvocationReference'->new($_) };

declare 'RepeatedInvocationReference',
    as ArrayRef[InvocationReference()];

coerce 'RepeatedInvocationReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::AgentAnomaly::InvocationReference'->new($_) } @$_ ] };

declare 'MapStringInvocationReference',
    as HashRef[InvocationReference()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::AgentAnomaly::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
