package Google::Cloud::Securitycenter::V2::VertexAi::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VertexAi',
    as InstanceOf['Google::Cloud::Securitycenter::V2::VertexAi::VertexAi'];

coerce 'VertexAi',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::VertexAi::VertexAi'->new($_) };

declare 'RepeatedVertexAi',
    as ArrayRef[VertexAi()];

coerce 'RepeatedVertexAi',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::VertexAi::VertexAi'->new($_) } @$_ ] };

declare 'MapStringVertexAi',
    as HashRef[VertexAi()];

declare 'Dataset',
    as InstanceOf['Google::Cloud::Securitycenter::V2::VertexAi::VertexAi::Dataset'];

coerce 'Dataset',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::VertexAi::VertexAi::Dataset'->new($_) };

declare 'RepeatedDataset',
    as ArrayRef[Dataset()];

coerce 'RepeatedDataset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::VertexAi::VertexAi::Dataset'->new($_) } @$_ ] };

declare 'MapStringDataset',
    as HashRef[Dataset()];

declare 'Pipeline',
    as InstanceOf['Google::Cloud::Securitycenter::V2::VertexAi::VertexAi::Pipeline'];

coerce 'Pipeline',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::VertexAi::VertexAi::Pipeline'->new($_) };

declare 'RepeatedPipeline',
    as ArrayRef[Pipeline()];

coerce 'RepeatedPipeline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::VertexAi::VertexAi::Pipeline'->new($_) } @$_ ] };

declare 'MapStringPipeline',
    as HashRef[Pipeline()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::VertexAi::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
