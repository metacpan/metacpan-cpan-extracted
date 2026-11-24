package Google::Cloud::Contentwarehouse::V1::PipelineService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RunPipelineRequest',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::PipelineService::RunPipelineRequest'];

coerce 'RunPipelineRequest',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::PipelineService::RunPipelineRequest'->new($_) };

declare 'RepeatedRunPipelineRequest',
    as ArrayRef[RunPipelineRequest()];

coerce 'RepeatedRunPipelineRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::PipelineService::RunPipelineRequest'->new($_) } @$_ ] };

declare 'MapStringRunPipelineRequest',
    as HashRef[RunPipelineRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::PipelineService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
