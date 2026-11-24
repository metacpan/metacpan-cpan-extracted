package Google::Cloud::Apihub::V1::LintingService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetStyleGuideRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::LintingService::GetStyleGuideRequest'];

coerce 'GetStyleGuideRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::LintingService::GetStyleGuideRequest'->new($_) };

declare 'RepeatedGetStyleGuideRequest',
    as ArrayRef[GetStyleGuideRequest()];

coerce 'RepeatedGetStyleGuideRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::LintingService::GetStyleGuideRequest'->new($_) } @$_ ] };

declare 'MapStringGetStyleGuideRequest',
    as HashRef[GetStyleGuideRequest()];

declare 'UpdateStyleGuideRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::LintingService::UpdateStyleGuideRequest'];

coerce 'UpdateStyleGuideRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::LintingService::UpdateStyleGuideRequest'->new($_) };

declare 'RepeatedUpdateStyleGuideRequest',
    as ArrayRef[UpdateStyleGuideRequest()];

coerce 'RepeatedUpdateStyleGuideRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::LintingService::UpdateStyleGuideRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateStyleGuideRequest',
    as HashRef[UpdateStyleGuideRequest()];

declare 'GetStyleGuideContentsRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::LintingService::GetStyleGuideContentsRequest'];

coerce 'GetStyleGuideContentsRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::LintingService::GetStyleGuideContentsRequest'->new($_) };

declare 'RepeatedGetStyleGuideContentsRequest',
    as ArrayRef[GetStyleGuideContentsRequest()];

coerce 'RepeatedGetStyleGuideContentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::LintingService::GetStyleGuideContentsRequest'->new($_) } @$_ ] };

declare 'MapStringGetStyleGuideContentsRequest',
    as HashRef[GetStyleGuideContentsRequest()];

declare 'LintSpecRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::LintingService::LintSpecRequest'];

coerce 'LintSpecRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::LintingService::LintSpecRequest'->new($_) };

declare 'RepeatedLintSpecRequest',
    as ArrayRef[LintSpecRequest()];

coerce 'RepeatedLintSpecRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::LintingService::LintSpecRequest'->new($_) } @$_ ] };

declare 'MapStringLintSpecRequest',
    as HashRef[LintSpecRequest()];

declare 'StyleGuideContents',
    as InstanceOf['Google::Cloud::Apihub::V1::LintingService::StyleGuideContents'];

coerce 'StyleGuideContents',
    from HashRef, via { 'Google::Cloud::Apihub::V1::LintingService::StyleGuideContents'->new($_) };

declare 'RepeatedStyleGuideContents',
    as ArrayRef[StyleGuideContents()];

coerce 'RepeatedStyleGuideContents',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::LintingService::StyleGuideContents'->new($_) } @$_ ] };

declare 'MapStringStyleGuideContents',
    as HashRef[StyleGuideContents()];

declare 'StyleGuide',
    as InstanceOf['Google::Cloud::Apihub::V1::LintingService::StyleGuide'];

coerce 'StyleGuide',
    from HashRef, via { 'Google::Cloud::Apihub::V1::LintingService::StyleGuide'->new($_) };

declare 'RepeatedStyleGuide',
    as ArrayRef[StyleGuide()];

coerce 'RepeatedStyleGuide',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::LintingService::StyleGuide'->new($_) } @$_ ] };

declare 'MapStringStyleGuide',
    as HashRef[StyleGuide()];

1;

__END__

=head1 NAME

Google::Cloud::Apihub::V1::LintingService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
