package Google::Cloud::Apptopology::V1::Graph::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Graph',
    as InstanceOf['Google::Cloud::Apptopology::V1::Graph::Graph'];

coerce 'Graph',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Graph::Graph'->new($_) };

declare 'RepeatedGraph',
    as ArrayRef[Graph()];

coerce 'RepeatedGraph',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Graph::Graph'->new($_) } @$_ ] };

declare 'MapStringGraph',
    as HashRef[Graph()];

declare 'EntityContext',
    as InstanceOf['Google::Cloud::Apptopology::V1::Graph::EntityContext'];

coerce 'EntityContext',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Graph::EntityContext'->new($_) };

declare 'RepeatedEntityContext',
    as ArrayRef[EntityContext()];

coerce 'RepeatedEntityContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Graph::EntityContext'->new($_) } @$_ ] };

declare 'MapStringEntityContext',
    as HashRef[EntityContext()];

declare 'Node',
    as InstanceOf['Google::Cloud::Apptopology::V1::Graph::Node'];

coerce 'Node',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Graph::Node'->new($_) };

declare 'RepeatedNode',
    as ArrayRef[Node()];

coerce 'RepeatedNode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Graph::Node'->new($_) } @$_ ] };

declare 'MapStringNode',
    as HashRef[Node()];

declare 'Edge',
    as InstanceOf['Google::Cloud::Apptopology::V1::Graph::Edge'];

coerce 'Edge',
    from HashRef, via { 'Google::Cloud::Apptopology::V1::Graph::Edge'->new($_) };

declare 'RepeatedEdge',
    as ArrayRef[Edge()];

coerce 'RepeatedEdge',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apptopology::V1::Graph::Edge'->new($_) } @$_ ] };

declare 'MapStringEdge',
    as HashRef[Edge()];

1;

__END__

=head1 NAME

Google::Cloud::Apptopology::V1::Graph::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
