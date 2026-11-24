package Google::Cloud::Discoveryengine::V1alpha::ProjectService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetProjectRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ProjectService::GetProjectRequest'];

coerce 'GetProjectRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::GetProjectRequest'->new($_) };

declare 'RepeatedGetProjectRequest',
    as ArrayRef[GetProjectRequest()];

coerce 'RepeatedGetProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::GetProjectRequest'->new($_) } @$_ ] };

declare 'MapStringGetProjectRequest',
    as HashRef[GetProjectRequest()];

declare 'ProvisionProjectRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectRequest'];

coerce 'ProvisionProjectRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectRequest'->new($_) };

declare 'RepeatedProvisionProjectRequest',
    as ArrayRef[ProvisionProjectRequest()];

coerce 'RepeatedProvisionProjectRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectRequest'->new($_) } @$_ ] };

declare 'MapStringProvisionProjectRequest',
    as HashRef[ProvisionProjectRequest()];

declare 'ProvisionProjectMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectMetadata'];

coerce 'ProvisionProjectMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectMetadata'->new($_) };

declare 'RepeatedProvisionProjectMetadata',
    as ArrayRef[ProvisionProjectMetadata()];

coerce 'RepeatedProvisionProjectMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::ProvisionProjectMetadata'->new($_) } @$_ ] };

declare 'MapStringProvisionProjectMetadata',
    as HashRef[ProvisionProjectMetadata()];

declare 'ReportConsentChangeRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ProjectService::ReportConsentChangeRequest'];

coerce 'ReportConsentChangeRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::ReportConsentChangeRequest'->new($_) };

declare 'RepeatedReportConsentChangeRequest',
    as ArrayRef[ReportConsentChangeRequest()];

coerce 'RepeatedReportConsentChangeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ProjectService::ReportConsentChangeRequest'->new($_) } @$_ ] };

declare 'MapStringReportConsentChangeRequest',
    as HashRef[ReportConsentChangeRequest()];

declare 'ConsentChangeAction',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::ProjectService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
