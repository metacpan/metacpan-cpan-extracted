package Google::Cloud::Datalabeling::V1beta1::EvaluationJob::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EvaluationJob',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJob'];

coerce 'EvaluationJob',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJob'->new($_) };

declare 'RepeatedEvaluationJob',
    as ArrayRef[EvaluationJob()];

coerce 'RepeatedEvaluationJob',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJob'->new($_) } @$_ ] };

declare 'MapStringEvaluationJob',
    as HashRef[EvaluationJob()];

declare 'State',
    as (Int | Str);

declare 'EvaluationJobConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobConfig'];

coerce 'EvaluationJobConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobConfig'->new($_) };

declare 'RepeatedEvaluationJobConfig',
    as ArrayRef[EvaluationJobConfig()];

coerce 'RepeatedEvaluationJobConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobConfig'->new($_) } @$_ ] };

declare 'MapStringEvaluationJobConfig',
    as HashRef[EvaluationJobConfig()];

declare 'BigqueryImportKeysEntry',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobConfig::BigqueryImportKeysEntry'];

coerce 'BigqueryImportKeysEntry',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobConfig::BigqueryImportKeysEntry'->new($_) };

declare 'RepeatedBigqueryImportKeysEntry',
    as ArrayRef[BigqueryImportKeysEntry()];

coerce 'RepeatedBigqueryImportKeysEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobConfig::BigqueryImportKeysEntry'->new($_) } @$_ ] };

declare 'MapStringBigqueryImportKeysEntry',
    as HashRef[BigqueryImportKeysEntry()];

declare 'EvaluationJobAlertConfig',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobAlertConfig'];

coerce 'EvaluationJobAlertConfig',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobAlertConfig'->new($_) };

declare 'RepeatedEvaluationJobAlertConfig',
    as ArrayRef[EvaluationJobAlertConfig()];

coerce 'RepeatedEvaluationJobAlertConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::EvaluationJob::EvaluationJobAlertConfig'->new($_) } @$_ ] };

declare 'MapStringEvaluationJobAlertConfig',
    as HashRef[EvaluationJobAlertConfig()];

declare 'Attempt',
    as InstanceOf['Google::Cloud::Datalabeling::V1beta1::EvaluationJob::Attempt'];

coerce 'Attempt',
    from HashRef, via { 'Google::Cloud::Datalabeling::V1beta1::EvaluationJob::Attempt'->new($_) };

declare 'RepeatedAttempt',
    as ArrayRef[Attempt()];

coerce 'RepeatedAttempt',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datalabeling::V1beta1::EvaluationJob::Attempt'->new($_) } @$_ ] };

declare 'MapStringAttempt',
    as HashRef[Attempt()];

1;

__END__

=head1 NAME

Google::Cloud::Datalabeling::V1beta1::EvaluationJob::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
