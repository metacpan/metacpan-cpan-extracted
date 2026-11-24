package Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CheckGroundingSpec',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingSpec'];

coerce 'CheckGroundingSpec',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingSpec'->new($_) };

declare 'RepeatedCheckGroundingSpec',
    as ArrayRef[CheckGroundingSpec()];

coerce 'RepeatedCheckGroundingSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingSpec'->new($_) } @$_ ] };

declare 'MapStringCheckGroundingSpec',
    as HashRef[CheckGroundingSpec()];

declare 'CheckGroundingRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingRequest'];

coerce 'CheckGroundingRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingRequest'->new($_) };

declare 'RepeatedCheckGroundingRequest',
    as ArrayRef[CheckGroundingRequest()];

coerce 'RepeatedCheckGroundingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingRequest'->new($_) } @$_ ] };

declare 'MapStringCheckGroundingRequest',
    as HashRef[CheckGroundingRequest()];

declare 'UserLabelsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingRequest::UserLabelsEntry'];

coerce 'UserLabelsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingRequest::UserLabelsEntry'->new($_) };

declare 'RepeatedUserLabelsEntry',
    as ArrayRef[UserLabelsEntry()];

coerce 'RepeatedUserLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingRequest::UserLabelsEntry'->new($_) } @$_ ] };

declare 'MapStringUserLabelsEntry',
    as HashRef[UserLabelsEntry()];

declare 'CheckGroundingResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse'];

coerce 'CheckGroundingResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse'->new($_) };

declare 'RepeatedCheckGroundingResponse',
    as ArrayRef[CheckGroundingResponse()];

coerce 'RepeatedCheckGroundingResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse'->new($_) } @$_ ] };

declare 'MapStringCheckGroundingResponse',
    as HashRef[CheckGroundingResponse()];

declare 'Claim',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse::Claim'];

coerce 'Claim',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse::Claim'->new($_) };

declare 'RepeatedClaim',
    as ArrayRef[Claim()];

coerce 'RepeatedClaim',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::CheckGroundingResponse::Claim'->new($_) } @$_ ] };

declare 'MapStringClaim',
    as HashRef[Claim()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::GroundedGenerationService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
