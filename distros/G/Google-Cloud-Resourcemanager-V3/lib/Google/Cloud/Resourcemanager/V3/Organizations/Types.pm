package Google::Cloud::Resourcemanager::V3::Organizations::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Organization',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Organizations::Organization'];

coerce 'Organization',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Organizations::Organization'->new($_) };

declare 'RepeatedOrganization',
    as ArrayRef[Organization()];

coerce 'RepeatedOrganization',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Organizations::Organization'->new($_) } @$_ ] };

declare 'MapStringOrganization',
    as HashRef[Organization()];

declare 'State',
    as (Int | Str);

declare 'GetOrganizationRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Organizations::GetOrganizationRequest'];

coerce 'GetOrganizationRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Organizations::GetOrganizationRequest'->new($_) };

declare 'RepeatedGetOrganizationRequest',
    as ArrayRef[GetOrganizationRequest()];

coerce 'RepeatedGetOrganizationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Organizations::GetOrganizationRequest'->new($_) } @$_ ] };

declare 'MapStringGetOrganizationRequest',
    as HashRef[GetOrganizationRequest()];

declare 'SearchOrganizationsRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsRequest'];

coerce 'SearchOrganizationsRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsRequest'->new($_) };

declare 'RepeatedSearchOrganizationsRequest',
    as ArrayRef[SearchOrganizationsRequest()];

coerce 'RepeatedSearchOrganizationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsRequest'->new($_) } @$_ ] };

declare 'MapStringSearchOrganizationsRequest',
    as HashRef[SearchOrganizationsRequest()];

declare 'SearchOrganizationsResponse',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsResponse'];

coerce 'SearchOrganizationsResponse',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsResponse'->new($_) };

declare 'RepeatedSearchOrganizationsResponse',
    as ArrayRef[SearchOrganizationsResponse()];

coerce 'RepeatedSearchOrganizationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsResponse'->new($_) } @$_ ] };

declare 'MapStringSearchOrganizationsResponse',
    as HashRef[SearchOrganizationsResponse()];

declare 'DeleteOrganizationMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Organizations::DeleteOrganizationMetadata'];

coerce 'DeleteOrganizationMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Organizations::DeleteOrganizationMetadata'->new($_) };

declare 'RepeatedDeleteOrganizationMetadata',
    as ArrayRef[DeleteOrganizationMetadata()];

coerce 'RepeatedDeleteOrganizationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Organizations::DeleteOrganizationMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteOrganizationMetadata',
    as HashRef[DeleteOrganizationMetadata()];

declare 'UndeleteOrganizationMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::Organizations::UndeleteOrganizationMetadata'];

coerce 'UndeleteOrganizationMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::Organizations::UndeleteOrganizationMetadata'->new($_) };

declare 'RepeatedUndeleteOrganizationMetadata',
    as ArrayRef[UndeleteOrganizationMetadata()];

coerce 'RepeatedUndeleteOrganizationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::Organizations::UndeleteOrganizationMetadata'->new($_) } @$_ ] };

declare 'MapStringUndeleteOrganizationMetadata',
    as HashRef[UndeleteOrganizationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Resourcemanager::V3::Organizations::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
