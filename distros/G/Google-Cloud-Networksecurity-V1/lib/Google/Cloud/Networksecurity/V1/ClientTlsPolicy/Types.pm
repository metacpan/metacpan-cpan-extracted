package Google::Cloud::Networksecurity::V1::ClientTlsPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ClientTlsPolicy',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy'];

coerce 'ClientTlsPolicy',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy'->new($_) };

declare 'RepeatedClientTlsPolicy',
    as ArrayRef[ClientTlsPolicy()];

coerce 'RepeatedClientTlsPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy'->new($_) } @$_ ] };

declare 'MapStringClientTlsPolicy',
    as HashRef[ClientTlsPolicy()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ClientTlsPolicy::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListClientTlsPoliciesRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesRequest'];

coerce 'ListClientTlsPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesRequest'->new($_) };

declare 'RepeatedListClientTlsPoliciesRequest',
    as ArrayRef[ListClientTlsPoliciesRequest()];

coerce 'RepeatedListClientTlsPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListClientTlsPoliciesRequest',
    as HashRef[ListClientTlsPoliciesRequest()];

declare 'ListClientTlsPoliciesResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesResponse'];

coerce 'ListClientTlsPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesResponse'->new($_) };

declare 'RepeatedListClientTlsPoliciesResponse',
    as ArrayRef[ListClientTlsPoliciesResponse()];

coerce 'RepeatedListClientTlsPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::ListClientTlsPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListClientTlsPoliciesResponse',
    as HashRef[ListClientTlsPoliciesResponse()];

declare 'GetClientTlsPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ClientTlsPolicy::GetClientTlsPolicyRequest'];

coerce 'GetClientTlsPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::GetClientTlsPolicyRequest'->new($_) };

declare 'RepeatedGetClientTlsPolicyRequest',
    as ArrayRef[GetClientTlsPolicyRequest()];

coerce 'RepeatedGetClientTlsPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::GetClientTlsPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetClientTlsPolicyRequest',
    as HashRef[GetClientTlsPolicyRequest()];

declare 'CreateClientTlsPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ClientTlsPolicy::CreateClientTlsPolicyRequest'];

coerce 'CreateClientTlsPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::CreateClientTlsPolicyRequest'->new($_) };

declare 'RepeatedCreateClientTlsPolicyRequest',
    as ArrayRef[CreateClientTlsPolicyRequest()];

coerce 'RepeatedCreateClientTlsPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::CreateClientTlsPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateClientTlsPolicyRequest',
    as HashRef[CreateClientTlsPolicyRequest()];

declare 'UpdateClientTlsPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ClientTlsPolicy::UpdateClientTlsPolicyRequest'];

coerce 'UpdateClientTlsPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::UpdateClientTlsPolicyRequest'->new($_) };

declare 'RepeatedUpdateClientTlsPolicyRequest',
    as ArrayRef[UpdateClientTlsPolicyRequest()];

coerce 'RepeatedUpdateClientTlsPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::UpdateClientTlsPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateClientTlsPolicyRequest',
    as HashRef[UpdateClientTlsPolicyRequest()];

declare 'DeleteClientTlsPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ClientTlsPolicy::DeleteClientTlsPolicyRequest'];

coerce 'DeleteClientTlsPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::DeleteClientTlsPolicyRequest'->new($_) };

declare 'RepeatedDeleteClientTlsPolicyRequest',
    as ArrayRef[DeleteClientTlsPolicyRequest()];

coerce 'RepeatedDeleteClientTlsPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ClientTlsPolicy::DeleteClientTlsPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteClientTlsPolicyRequest',
    as HashRef[DeleteClientTlsPolicyRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::ClientTlsPolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
