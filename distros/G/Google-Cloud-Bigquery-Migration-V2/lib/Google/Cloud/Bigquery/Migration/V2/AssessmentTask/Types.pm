package Google::Cloud::Bigquery::Migration::V2::AssessmentTask::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AssessmentTaskDetails',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::AssessmentTask::AssessmentTaskDetails'];

coerce 'AssessmentTaskDetails',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::AssessmentTask::AssessmentTaskDetails'->new($_) };

declare 'RepeatedAssessmentTaskDetails',
    as ArrayRef[AssessmentTaskDetails()];

coerce 'RepeatedAssessmentTaskDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::AssessmentTask::AssessmentTaskDetails'->new($_) } @$_ ] };

declare 'MapStringAssessmentTaskDetails',
    as HashRef[AssessmentTaskDetails()];

declare 'AssessmentFeatureHandle',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::AssessmentTask::AssessmentFeatureHandle'];

coerce 'AssessmentFeatureHandle',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::AssessmentTask::AssessmentFeatureHandle'->new($_) };

declare 'RepeatedAssessmentFeatureHandle',
    as ArrayRef[AssessmentFeatureHandle()];

coerce 'RepeatedAssessmentFeatureHandle',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::AssessmentTask::AssessmentFeatureHandle'->new($_) } @$_ ] };

declare 'MapStringAssessmentFeatureHandle',
    as HashRef[AssessmentFeatureHandle()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::AssessmentTask::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
