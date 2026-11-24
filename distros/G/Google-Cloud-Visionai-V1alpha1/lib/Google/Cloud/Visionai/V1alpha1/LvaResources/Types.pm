package Google::Cloud::Visionai::V1alpha1::LvaResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Analysis',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis'];

coerce 'Analysis',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis'->new($_) };

declare 'RepeatedAnalysis',
    as ArrayRef[Analysis()];

coerce 'RepeatedAnalysis',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis'->new($_) } @$_ ] };

declare 'MapStringAnalysis',
    as HashRef[Analysis()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'InputStreamsMappingEntry',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis::InputStreamsMappingEntry'];

coerce 'InputStreamsMappingEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis::InputStreamsMappingEntry'->new($_) };

declare 'RepeatedInputStreamsMappingEntry',
    as ArrayRef[InputStreamsMappingEntry()];

coerce 'RepeatedInputStreamsMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis::InputStreamsMappingEntry'->new($_) } @$_ ] };

declare 'MapStringInputStreamsMappingEntry',
    as HashRef[InputStreamsMappingEntry()];

declare 'OutputStreamsMappingEntry',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis::OutputStreamsMappingEntry'];

coerce 'OutputStreamsMappingEntry',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis::OutputStreamsMappingEntry'->new($_) };

declare 'RepeatedOutputStreamsMappingEntry',
    as ArrayRef[OutputStreamsMappingEntry()];

coerce 'RepeatedOutputStreamsMappingEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::LvaResources::Analysis::OutputStreamsMappingEntry'->new($_) } @$_ ] };

declare 'MapStringOutputStreamsMappingEntry',
    as HashRef[OutputStreamsMappingEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1alpha1::LvaResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
