package Google::Cloud::Apptopology::V1::Schema::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Domain',
    as InstanceOf['Google::Cloud::Apptopology::V1::Schema::Domain'];

coerce 'Domain',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Schema::Domain'->new($_) };

declare 'RepeatedDomain',
    as ArrayRef[Domain()];

coerce 'RepeatedDomain',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Schema::Domain'->new($_) } @$_ ] };

declare 'MapStringDomain',
    as HashRef[Domain()];

declare 'Schema',
    as InstanceOf['Google::Cloud::Apptopology::V1::Schema::Schema'];

coerce 'Schema',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Schema::Schema'->new($_) };

declare 'RepeatedSchema',
    as ArrayRef[Schema()];

coerce 'RepeatedSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Schema::Schema'->new($_) } @$_ ] };

declare 'MapStringSchema',
    as HashRef[Schema()];

declare 'NodeType',
    as InstanceOf['Google::Cloud::Apptopology::V1::Schema::NodeType'];

coerce 'NodeType',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Schema::NodeType'->new($_) };

declare 'RepeatedNodeType',
    as ArrayRef[NodeType()];

coerce 'RepeatedNodeType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Schema::NodeType'->new($_) } @$_ ] };

declare 'MapStringNodeType',
    as HashRef[NodeType()];

declare 'EdgeType',
    as InstanceOf['Google::Cloud::Apptopology::V1::Schema::EdgeType'];

coerce 'EdgeType',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Schema::EdgeType'->new($_) };

declare 'RepeatedEdgeType',
    as ArrayRef[EdgeType()];

coerce 'RepeatedEdgeType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Schema::EdgeType'->new($_) } @$_ ] };

declare 'MapStringEdgeType',
    as HashRef[EdgeType()];

declare 'NodeGroup',
    as InstanceOf['Google::Cloud::Apptopology::V1::Schema::NodeGroup'];

coerce 'NodeGroup',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Schema::NodeGroup'->new($_) };

declare 'RepeatedNodeGroup',
    as ArrayRef[NodeGroup()];

coerce 'RepeatedNodeGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Schema::NodeGroup'->new($_) } @$_ ] };

declare 'MapStringNodeGroup',
    as HashRef[NodeGroup()];

declare 'EdgeRule',
    as InstanceOf['Google::Cloud::Apptopology::V1::Schema::EdgeRule'];

coerce 'EdgeRule',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Schema::EdgeRule'->new($_) };

declare 'RepeatedEdgeRule',
    as ArrayRef[EdgeRule()];

coerce 'RepeatedEdgeRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Schema::EdgeRule'->new($_) } @$_ ] };

declare 'MapStringEdgeRule',
    as HashRef[EdgeRule()];

declare 'LabelProperties',
    as InstanceOf['Google::Cloud::Apptopology::V1::Schema::LabelProperties'];

coerce 'LabelProperties',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Schema::LabelProperties'->new($_) };

declare 'RepeatedLabelProperties',
    as ArrayRef[LabelProperties()];

coerce 'RepeatedLabelProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Schema::LabelProperties'->new($_) } @$_ ] };

declare 'MapStringLabelProperties',
    as HashRef[LabelProperties()];

declare 'Property',
    as InstanceOf['Google::Cloud::Apptopology::V1::Schema::Property'];

coerce 'Property',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Schema::Property'->new($_) };

declare 'RepeatedProperty',
    as ArrayRef[Property()];

coerce 'RepeatedProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Schema::Property'->new($_) } @$_ ] };

declare 'MapStringProperty',
    as HashRef[Property()];

declare 'StringValue',
    as InstanceOf['Google::Cloud::Apptopology::V1::Schema::StringValue'];

coerce 'StringValue',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Schema::StringValue'->new($_) };

declare 'RepeatedStringValue',
    as ArrayRef[StringValue()];

coerce 'RepeatedStringValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Schema::StringValue'->new($_) } @$_ ] };

declare 'MapStringStringValue',
    as HashRef[StringValue()];

declare 'IntValue',
    as InstanceOf['Google::Cloud::Apptopology::V1::Schema::IntValue'];

coerce 'IntValue',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Schema::IntValue'->new($_) };

declare 'RepeatedIntValue',
    as ArrayRef[IntValue()];

coerce 'RepeatedIntValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Schema::IntValue'->new($_) } @$_ ] };

declare 'MapStringIntValue',
    as HashRef[IntValue()];

declare 'BoolValue',
    as InstanceOf['Google::Cloud::Apptopology::V1::Schema::BoolValue'];

coerce 'BoolValue',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Schema::BoolValue'->new($_) };

declare 'RepeatedBoolValue',
    as ArrayRef[BoolValue()];

coerce 'RepeatedBoolValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Schema::BoolValue'->new($_) } @$_ ] };

declare 'MapStringBoolValue',
    as HashRef[BoolValue()];

declare 'DoubleValue',
    as InstanceOf['Google::Cloud::Apptopology::V1::Schema::DoubleValue'];

coerce 'DoubleValue',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Schema::DoubleValue'->new($_) };

declare 'RepeatedDoubleValue',
    as ArrayRef[DoubleValue()];

coerce 'RepeatedDoubleValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Schema::DoubleValue'->new($_) } @$_ ] };

declare 'MapStringDoubleValue',
    as HashRef[DoubleValue()];

1;

__END__

=head1 NAME

Google::Cloud::Apptopology::V1::Schema::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
