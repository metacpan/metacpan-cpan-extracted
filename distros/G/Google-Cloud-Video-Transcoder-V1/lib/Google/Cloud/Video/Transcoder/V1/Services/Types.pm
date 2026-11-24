package Google::Cloud::Video::Transcoder::V1::Services::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateJobRequest',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Services::CreateJobRequest'];

coerce 'CreateJobRequest',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Services::CreateJobRequest'->new($_) };

declare 'RepeatedCreateJobRequest',
    as ArrayRef[CreateJobRequest()];

coerce 'RepeatedCreateJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Services::CreateJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateJobRequest',
    as HashRef[CreateJobRequest()];

declare 'ListJobsRequest',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Services::ListJobsRequest'];

coerce 'ListJobsRequest',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Services::ListJobsRequest'->new($_) };

declare 'RepeatedListJobsRequest',
    as ArrayRef[ListJobsRequest()];

coerce 'RepeatedListJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Services::ListJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListJobsRequest',
    as HashRef[ListJobsRequest()];

declare 'GetJobRequest',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Services::GetJobRequest'];

coerce 'GetJobRequest',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Services::GetJobRequest'->new($_) };

declare 'RepeatedGetJobRequest',
    as ArrayRef[GetJobRequest()];

coerce 'RepeatedGetJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Services::GetJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobRequest',
    as HashRef[GetJobRequest()];

declare 'DeleteJobRequest',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Services::DeleteJobRequest'];

coerce 'DeleteJobRequest',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Services::DeleteJobRequest'->new($_) };

declare 'RepeatedDeleteJobRequest',
    as ArrayRef[DeleteJobRequest()];

coerce 'RepeatedDeleteJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Services::DeleteJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteJobRequest',
    as HashRef[DeleteJobRequest()];

declare 'ListJobsResponse',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Services::ListJobsResponse'];

coerce 'ListJobsResponse',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Services::ListJobsResponse'->new($_) };

declare 'RepeatedListJobsResponse',
    as ArrayRef[ListJobsResponse()];

coerce 'RepeatedListJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Services::ListJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListJobsResponse',
    as HashRef[ListJobsResponse()];

declare 'CreateJobTemplateRequest',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Services::CreateJobTemplateRequest'];

coerce 'CreateJobTemplateRequest',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Services::CreateJobTemplateRequest'->new($_) };

declare 'RepeatedCreateJobTemplateRequest',
    as ArrayRef[CreateJobTemplateRequest()];

coerce 'RepeatedCreateJobTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Services::CreateJobTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringCreateJobTemplateRequest',
    as HashRef[CreateJobTemplateRequest()];

declare 'ListJobTemplatesRequest',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Services::ListJobTemplatesRequest'];

coerce 'ListJobTemplatesRequest',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Services::ListJobTemplatesRequest'->new($_) };

declare 'RepeatedListJobTemplatesRequest',
    as ArrayRef[ListJobTemplatesRequest()];

coerce 'RepeatedListJobTemplatesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Services::ListJobTemplatesRequest'->new($_) } @$_ ] };

declare 'MapStringListJobTemplatesRequest',
    as HashRef[ListJobTemplatesRequest()];

declare 'GetJobTemplateRequest',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Services::GetJobTemplateRequest'];

coerce 'GetJobTemplateRequest',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Services::GetJobTemplateRequest'->new($_) };

declare 'RepeatedGetJobTemplateRequest',
    as ArrayRef[GetJobTemplateRequest()];

coerce 'RepeatedGetJobTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Services::GetJobTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringGetJobTemplateRequest',
    as HashRef[GetJobTemplateRequest()];

declare 'DeleteJobTemplateRequest',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Services::DeleteJobTemplateRequest'];

coerce 'DeleteJobTemplateRequest',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Services::DeleteJobTemplateRequest'->new($_) };

declare 'RepeatedDeleteJobTemplateRequest',
    as ArrayRef[DeleteJobTemplateRequest()];

coerce 'RepeatedDeleteJobTemplateRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Services::DeleteJobTemplateRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteJobTemplateRequest',
    as HashRef[DeleteJobTemplateRequest()];

declare 'ListJobTemplatesResponse',
    as InstanceOf['Google::Cloud::Video::Transcoder::V1::Services::ListJobTemplatesResponse'];

coerce 'ListJobTemplatesResponse',
    from HashRef, via { 'Google::Cloud::Video::Transcoder::V1::Services::ListJobTemplatesResponse'->new($_) };

declare 'RepeatedListJobTemplatesResponse',
    as ArrayRef[ListJobTemplatesResponse()];

coerce 'RepeatedListJobTemplatesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Video::Transcoder::V1::Services::ListJobTemplatesResponse'->new($_) } @$_ ] };

declare 'MapStringListJobTemplatesResponse',
    as HashRef[ListJobTemplatesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Video::Transcoder::V1::Services::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
