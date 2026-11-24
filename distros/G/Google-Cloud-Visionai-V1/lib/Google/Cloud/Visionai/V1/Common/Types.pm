package Google::Cloud::Visionai::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Cluster',
    as InstanceOf['Google::Cloud::Visionai::V1::Common::Cluster'];

coerce 'Cluster',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Common::Cluster'->new($_) };

declare 'RepeatedCluster',
    as ArrayRef[Cluster()];

coerce 'RepeatedCluster',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Common::Cluster'->new($_) } @$_ ] };

declare 'MapStringCluster',
    as HashRef[Cluster()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1::Common::Cluster::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Common::Cluster::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Common::Cluster::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AnnotationsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1::Common::Cluster::AnnotationsEntry'];

coerce 'AnnotationsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Common::Cluster::AnnotationsEntry'->new($_) };

declare 'RepeatedAnnotationsEntry',
    as ArrayRef[AnnotationsEntry()];

coerce 'RepeatedAnnotationsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Common::Cluster::AnnotationsEntry'->new($_) } @$_ ] };

declare 'MapStringAnnotationsEntry',
    as HashRef[AnnotationsEntry()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::Common::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Common::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Common::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'GcsSource',
    as InstanceOf['Google::Cloud::Visionai::V1::Common::GcsSource'];

coerce 'GcsSource',
    from HashRef, via { 'Google::Cloud::Visionai::V1::Common::GcsSource'->new($_) };

declare 'RepeatedGcsSource',
    as ArrayRef[GcsSource()];

coerce 'RepeatedGcsSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::Common::GcsSource'->new($_) } @$_ ] };

declare 'MapStringGcsSource',
    as HashRef[GcsSource()];

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
