package Google::Cloud::Apptopology::V1::Query::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GraphPattern',
    as InstanceOf['Google::Cloud::Apptopology::V1::Query::GraphPattern'];

coerce 'GraphPattern',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Query::GraphPattern'->new($_) };

declare 'RepeatedGraphPattern',
    as ArrayRef[GraphPattern()];

coerce 'RepeatedGraphPattern',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Query::GraphPattern'->new($_) } @$_ ] };

declare 'MapStringGraphPattern',
    as HashRef[GraphPattern()];

declare 'NodePattern',
    as InstanceOf['Google::Cloud::Apptopology::V1::Query::NodePattern'];

coerce 'NodePattern',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Query::NodePattern'->new($_) };

declare 'RepeatedNodePattern',
    as ArrayRef[NodePattern()];

coerce 'RepeatedNodePattern',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Query::NodePattern'->new($_) } @$_ ] };

declare 'MapStringNodePattern',
    as HashRef[NodePattern()];

declare 'EdgePattern',
    as InstanceOf['Google::Cloud::Apptopology::V1::Query::EdgePattern'];

coerce 'EdgePattern',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Query::EdgePattern'->new($_) };

declare 'RepeatedEdgePattern',
    as ArrayRef[EdgePattern()];

coerce 'RepeatedEdgePattern',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Query::EdgePattern'->new($_) } @$_ ] };

declare 'MapStringEdgePattern',
    as HashRef[EdgePattern()];

declare 'Direction',
    as (Int | Str);

declare 'ConnectedNodePattern',
    as InstanceOf['Google::Cloud::Apptopology::V1::Query::ConnectedNodePattern'];

coerce 'ConnectedNodePattern',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Query::ConnectedNodePattern'->new($_) };

declare 'RepeatedConnectedNodePattern',
    as ArrayRef[ConnectedNodePattern()];

coerce 'RepeatedConnectedNodePattern',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Query::ConnectedNodePattern'->new($_) } @$_ ] };

declare 'MapStringConnectedNodePattern',
    as HashRef[ConnectedNodePattern()];

declare 'LabelPropertiesPattern',
    as InstanceOf['Google::Cloud::Apptopology::V1::Query::LabelPropertiesPattern'];

coerce 'LabelPropertiesPattern',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Query::LabelPropertiesPattern'->new($_) };

declare 'RepeatedLabelPropertiesPattern',
    as ArrayRef[LabelPropertiesPattern()];

coerce 'RepeatedLabelPropertiesPattern',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Query::LabelPropertiesPattern'->new($_) } @$_ ] };

declare 'MapStringLabelPropertiesPattern',
    as HashRef[LabelPropertiesPattern()];

1;

__END__

=head1 NAME

Google::Cloud::Apptopology::V1::Query::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
