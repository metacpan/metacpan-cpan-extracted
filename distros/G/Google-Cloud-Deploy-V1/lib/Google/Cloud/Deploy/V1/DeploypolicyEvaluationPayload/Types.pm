package Google::Cloud::Deploy::V1::DeploypolicyEvaluationPayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeployPolicyEvaluationEvent',
    as InstanceOf['Google::Cloud::Deploy::V1::DeploypolicyEvaluationPayload::DeployPolicyEvaluationEvent'];

coerce 'DeployPolicyEvaluationEvent',
    from HashRef, via { 'Google::Cloud::Deploy::V1::DeploypolicyEvaluationPayload::DeployPolicyEvaluationEvent'->new($_) };

declare 'RepeatedDeployPolicyEvaluationEvent',
    as ArrayRef[DeployPolicyEvaluationEvent()];

coerce 'RepeatedDeployPolicyEvaluationEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Deploy::V1::DeploypolicyEvaluationPayload::DeployPolicyEvaluationEvent'->new($_) } @$_ ] };

declare 'MapStringDeployPolicyEvaluationEvent',
    as HashRef[DeployPolicyEvaluationEvent()];

declare 'PolicyVerdict',
    as (Int | Str);

declare 'PolicyVerdictOverride',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Deploy::V1::DeploypolicyEvaluationPayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
