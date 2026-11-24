package Google::Cloud::Securitycenter::V1::AttackPath::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AttackPath',
    as InstanceOf['Google::Cloud::Securitycenter::V1::AttackPath::AttackPath'];

coerce 'AttackPath',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::AttackPath::AttackPath'->new($_) };

declare 'RepeatedAttackPath',
    as ArrayRef[AttackPath()];

coerce 'RepeatedAttackPath',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::AttackPath::AttackPath'->new($_) } @$_ ] };

declare 'MapStringAttackPath',
    as HashRef[AttackPath()];

declare 'AttackPathNode',
    as InstanceOf['Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathNode'];

coerce 'AttackPathNode',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathNode'->new($_) };

declare 'RepeatedAttackPathNode',
    as ArrayRef[AttackPathNode()];

coerce 'RepeatedAttackPathNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathNode'->new($_) } @$_ ] };

declare 'MapStringAttackPathNode',
    as HashRef[AttackPathNode()];

declare 'NodeType',
    as (Int | Str);

declare 'PathNodeAssociatedFinding',
    as InstanceOf['Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathNode::PathNodeAssociatedFinding'];

coerce 'PathNodeAssociatedFinding',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathNode::PathNodeAssociatedFinding'->new($_) };

declare 'RepeatedPathNodeAssociatedFinding',
    as ArrayRef[PathNodeAssociatedFinding()];

coerce 'RepeatedPathNodeAssociatedFinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathNode::PathNodeAssociatedFinding'->new($_) } @$_ ] };

declare 'MapStringPathNodeAssociatedFinding',
    as HashRef[PathNodeAssociatedFinding()];

declare 'AttackStepNode',
    as InstanceOf['Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathNode::AttackStepNode'];

coerce 'AttackStepNode',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathNode::AttackStepNode'->new($_) };

declare 'RepeatedAttackStepNode',
    as ArrayRef[AttackStepNode()];

coerce 'RepeatedAttackStepNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathNode::AttackStepNode'->new($_) } @$_ ] };

declare 'MapStringAttackStepNode',
    as HashRef[AttackStepNode()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathNode::AttackStepNode::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathNode::AttackStepNode::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathNode::AttackStepNode::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AttackPathEdge',
    as InstanceOf['Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathEdge'];

coerce 'AttackPathEdge',
    from HashRef, via { 'Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathEdge'->new($_) };

declare 'RepeatedAttackPathEdge',
    as ArrayRef[AttackPathEdge()];

coerce 'RepeatedAttackPathEdge',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V1::AttackPath::AttackPath::AttackPathEdge'->new($_) } @$_ ] };

declare 'MapStringAttackPathEdge',
    as HashRef[AttackPathEdge()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1::AttackPath::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
