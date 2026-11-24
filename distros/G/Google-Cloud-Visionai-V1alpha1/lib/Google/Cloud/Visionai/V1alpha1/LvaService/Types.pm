package Google::Cloud::Visionai::V1alpha1::LvaService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListAnalysesRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesRequest'];

coerce 'ListAnalysesRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesRequest'->new($_) };

declare 'RepeatedListAnalysesRequest',
    as ArrayRef[ListAnalysesRequest()];

coerce 'RepeatedListAnalysesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesRequest'->new($_) } @$_ ] };

declare 'MapStringListAnalysesRequest',
    as HashRef[ListAnalysesRequest()];

declare 'ListAnalysesResponse',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesResponse'];

coerce 'ListAnalysesResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesResponse'->new($_) };

declare 'RepeatedListAnalysesResponse',
    as ArrayRef[ListAnalysesResponse()];

coerce 'RepeatedListAnalysesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::LvaService::ListAnalysesResponse'->new($_) } @$_ ] };

declare 'MapStringListAnalysesResponse',
    as HashRef[ListAnalysesResponse()];

declare 'GetAnalysisRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::LvaService::GetAnalysisRequest'];

coerce 'GetAnalysisRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::LvaService::GetAnalysisRequest'->new($_) };

declare 'RepeatedGetAnalysisRequest',
    as ArrayRef[GetAnalysisRequest()];

coerce 'RepeatedGetAnalysisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::LvaService::GetAnalysisRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnalysisRequest',
    as HashRef[GetAnalysisRequest()];

declare 'CreateAnalysisRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::LvaService::CreateAnalysisRequest'];

coerce 'CreateAnalysisRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::LvaService::CreateAnalysisRequest'->new($_) };

declare 'RepeatedCreateAnalysisRequest',
    as ArrayRef[CreateAnalysisRequest()];

coerce 'RepeatedCreateAnalysisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::LvaService::CreateAnalysisRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAnalysisRequest',
    as HashRef[CreateAnalysisRequest()];

declare 'UpdateAnalysisRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::LvaService::UpdateAnalysisRequest'];

coerce 'UpdateAnalysisRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::LvaService::UpdateAnalysisRequest'->new($_) };

declare 'RepeatedUpdateAnalysisRequest',
    as ArrayRef[UpdateAnalysisRequest()];

coerce 'RepeatedUpdateAnalysisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::LvaService::UpdateAnalysisRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAnalysisRequest',
    as HashRef[UpdateAnalysisRequest()];

declare 'DeleteAnalysisRequest',
    as InstanceOf['Google::Cloud::Visionai::V1alpha1::LvaService::DeleteAnalysisRequest'];

coerce 'DeleteAnalysisRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1alpha1::LvaService::DeleteAnalysisRequest'->new($_) };

declare 'RepeatedDeleteAnalysisRequest',
    as ArrayRef[DeleteAnalysisRequest()];

coerce 'RepeatedDeleteAnalysisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1alpha1::LvaService::DeleteAnalysisRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAnalysisRequest',
    as HashRef[DeleteAnalysisRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1alpha1::LvaService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
