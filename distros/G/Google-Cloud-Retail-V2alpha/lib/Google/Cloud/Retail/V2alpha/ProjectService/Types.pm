package Google::Cloud::Retail::V2alpha::ProjectService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetProjectRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProjectService::GetProjectRequest'];

coerce 'GetProjectRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProjectService::GetProjectRequest'->new($_) };

declare 'RepeatedGetProjectRequest',
    as ArrayRef[GetProjectRequest()];

coerce 'RepeatedGetProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProjectService::GetProjectRequest'->new($_) } @$_ ] };

declare 'MapStringGetProjectRequest',
    as HashRef[GetProjectRequest()];

declare 'AcceptTermsRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProjectService::AcceptTermsRequest'];

coerce 'AcceptTermsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProjectService::AcceptTermsRequest'->new($_) };

declare 'RepeatedAcceptTermsRequest',
    as ArrayRef[AcceptTermsRequest()];

coerce 'RepeatedAcceptTermsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProjectService::AcceptTermsRequest'->new($_) } @$_ ] };

declare 'MapStringAcceptTermsRequest',
    as HashRef[AcceptTermsRequest()];

declare 'EnrollSolutionRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionRequest'];

coerce 'EnrollSolutionRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionRequest'->new($_) };

declare 'RepeatedEnrollSolutionRequest',
    as ArrayRef[EnrollSolutionRequest()];

coerce 'RepeatedEnrollSolutionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionRequest'->new($_) } @$_ ] };

declare 'MapStringEnrollSolutionRequest',
    as HashRef[EnrollSolutionRequest()];

declare 'EnrollSolutionResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionResponse'];

coerce 'EnrollSolutionResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionResponse'->new($_) };

declare 'RepeatedEnrollSolutionResponse',
    as ArrayRef[EnrollSolutionResponse()];

coerce 'RepeatedEnrollSolutionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionResponse'->new($_) } @$_ ] };

declare 'MapStringEnrollSolutionResponse',
    as HashRef[EnrollSolutionResponse()];

declare 'EnrollSolutionMetadata',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionMetadata'];

coerce 'EnrollSolutionMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionMetadata'->new($_) };

declare 'RepeatedEnrollSolutionMetadata',
    as ArrayRef[EnrollSolutionMetadata()];

coerce 'RepeatedEnrollSolutionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProjectService::EnrollSolutionMetadata'->new($_) } @$_ ] };

declare 'MapStringEnrollSolutionMetadata',
    as HashRef[EnrollSolutionMetadata()];

declare 'ListEnrolledSolutionsRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProjectService::ListEnrolledSolutionsRequest'];

coerce 'ListEnrolledSolutionsRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProjectService::ListEnrolledSolutionsRequest'->new($_) };

declare 'RepeatedListEnrolledSolutionsRequest',
    as ArrayRef[ListEnrolledSolutionsRequest()];

coerce 'RepeatedListEnrolledSolutionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProjectService::ListEnrolledSolutionsRequest'->new($_) } @$_ ] };

declare 'MapStringListEnrolledSolutionsRequest',
    as HashRef[ListEnrolledSolutionsRequest()];

declare 'ListEnrolledSolutionsResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProjectService::ListEnrolledSolutionsResponse'];

coerce 'ListEnrolledSolutionsResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProjectService::ListEnrolledSolutionsResponse'->new($_) };

declare 'RepeatedListEnrolledSolutionsResponse',
    as ArrayRef[ListEnrolledSolutionsResponse()];

coerce 'RepeatedListEnrolledSolutionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProjectService::ListEnrolledSolutionsResponse'->new($_) } @$_ ] };

declare 'MapStringListEnrolledSolutionsResponse',
    as HashRef[ListEnrolledSolutionsResponse()];

declare 'GetLoggingConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProjectService::GetLoggingConfigRequest'];

coerce 'GetLoggingConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProjectService::GetLoggingConfigRequest'->new($_) };

declare 'RepeatedGetLoggingConfigRequest',
    as ArrayRef[GetLoggingConfigRequest()];

coerce 'RepeatedGetLoggingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProjectService::GetLoggingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetLoggingConfigRequest',
    as HashRef[GetLoggingConfigRequest()];

declare 'UpdateLoggingConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProjectService::UpdateLoggingConfigRequest'];

coerce 'UpdateLoggingConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProjectService::UpdateLoggingConfigRequest'->new($_) };

declare 'RepeatedUpdateLoggingConfigRequest',
    as ArrayRef[UpdateLoggingConfigRequest()];

coerce 'RepeatedUpdateLoggingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProjectService::UpdateLoggingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateLoggingConfigRequest',
    as HashRef[UpdateLoggingConfigRequest()];

declare 'GetAlertConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProjectService::GetAlertConfigRequest'];

coerce 'GetAlertConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProjectService::GetAlertConfigRequest'->new($_) };

declare 'RepeatedGetAlertConfigRequest',
    as ArrayRef[GetAlertConfigRequest()];

coerce 'RepeatedGetAlertConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProjectService::GetAlertConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetAlertConfigRequest',
    as HashRef[GetAlertConfigRequest()];

declare 'UpdateAlertConfigRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::ProjectService::UpdateAlertConfigRequest'];

coerce 'UpdateAlertConfigRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::ProjectService::UpdateAlertConfigRequest'->new($_) };

declare 'RepeatedUpdateAlertConfigRequest',
    as ArrayRef[UpdateAlertConfigRequest()];

coerce 'RepeatedUpdateAlertConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::ProjectService::UpdateAlertConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAlertConfigRequest',
    as HashRef[UpdateAlertConfigRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::ProjectService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
