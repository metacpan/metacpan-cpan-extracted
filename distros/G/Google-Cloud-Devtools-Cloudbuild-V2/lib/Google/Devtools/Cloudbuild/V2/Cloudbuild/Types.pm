package Google::Devtools::Cloudbuild::V2::Cloudbuild::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadata',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Cloudbuild::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Cloudbuild::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Cloudbuild::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'RunWorkflowCustomOperationMetadata',
    as InstanceOf['Google::Devtools::Cloudbuild::V2::Cloudbuild::RunWorkflowCustomOperationMetadata'];

coerce 'RunWorkflowCustomOperationMetadata',
    from HashRef, via { 'Google::Devtools::Cloudbuild::V2::Cloudbuild::RunWorkflowCustomOperationMetadata'->new($_) };

declare 'RepeatedRunWorkflowCustomOperationMetadata',
    as ArrayRef[RunWorkflowCustomOperationMetadata()];

coerce 'RepeatedRunWorkflowCustomOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Cloudbuild::V2::Cloudbuild::RunWorkflowCustomOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringRunWorkflowCustomOperationMetadata',
    as HashRef[RunWorkflowCustomOperationMetadata()];

1;

__END__

=head1 NAME

Google::Devtools::Cloudbuild::V2::Cloudbuild::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
