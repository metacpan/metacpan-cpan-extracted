package Google::Cloud::Networksecurity::V1::ServerTlsPolicy::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ServerTlsPolicy',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ServerTlsPolicy'];

coerce 'ServerTlsPolicy',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ServerTlsPolicy'->new($_) };

declare 'RepeatedServerTlsPolicy',
    as ArrayRef[ServerTlsPolicy()];

coerce 'RepeatedServerTlsPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ServerTlsPolicy'->new($_) } @$_ ] };

declare 'MapStringServerTlsPolicy',
    as HashRef[ServerTlsPolicy()];

declare 'MTLSPolicy',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ServerTlsPolicy::MTLSPolicy'];

coerce 'MTLSPolicy',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ServerTlsPolicy::MTLSPolicy'->new($_) };

declare 'RepeatedMTLSPolicy',
    as ArrayRef[MTLSPolicy()];

coerce 'RepeatedMTLSPolicy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ServerTlsPolicy::MTLSPolicy'->new($_) } @$_ ] };

declare 'MapStringMTLSPolicy',
    as HashRef[MTLSPolicy()];

declare 'ClientValidationMode',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ServerTlsPolicy::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ServerTlsPolicy::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ServerTlsPolicy::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListServerTlsPoliciesRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ListServerTlsPoliciesRequest'];

coerce 'ListServerTlsPoliciesRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ListServerTlsPoliciesRequest'->new($_) };

declare 'RepeatedListServerTlsPoliciesRequest',
    as ArrayRef[ListServerTlsPoliciesRequest()];

coerce 'RepeatedListServerTlsPoliciesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ListServerTlsPoliciesRequest'->new($_) } @$_ ] };

declare 'MapStringListServerTlsPoliciesRequest',
    as HashRef[ListServerTlsPoliciesRequest()];

declare 'ListServerTlsPoliciesResponse',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ListServerTlsPoliciesResponse'];

coerce 'ListServerTlsPoliciesResponse',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ListServerTlsPoliciesResponse'->new($_) };

declare 'RepeatedListServerTlsPoliciesResponse',
    as ArrayRef[ListServerTlsPoliciesResponse()];

coerce 'RepeatedListServerTlsPoliciesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::ListServerTlsPoliciesResponse'->new($_) } @$_ ] };

declare 'MapStringListServerTlsPoliciesResponse',
    as HashRef[ListServerTlsPoliciesResponse()];

declare 'GetServerTlsPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ServerTlsPolicy::GetServerTlsPolicyRequest'];

coerce 'GetServerTlsPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::GetServerTlsPolicyRequest'->new($_) };

declare 'RepeatedGetServerTlsPolicyRequest',
    as ArrayRef[GetServerTlsPolicyRequest()];

coerce 'RepeatedGetServerTlsPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::GetServerTlsPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetServerTlsPolicyRequest',
    as HashRef[GetServerTlsPolicyRequest()];

declare 'CreateServerTlsPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ServerTlsPolicy::CreateServerTlsPolicyRequest'];

coerce 'CreateServerTlsPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::CreateServerTlsPolicyRequest'->new($_) };

declare 'RepeatedCreateServerTlsPolicyRequest',
    as ArrayRef[CreateServerTlsPolicyRequest()];

coerce 'RepeatedCreateServerTlsPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::CreateServerTlsPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServerTlsPolicyRequest',
    as HashRef[CreateServerTlsPolicyRequest()];

declare 'UpdateServerTlsPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ServerTlsPolicy::UpdateServerTlsPolicyRequest'];

coerce 'UpdateServerTlsPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::UpdateServerTlsPolicyRequest'->new($_) };

declare 'RepeatedUpdateServerTlsPolicyRequest',
    as ArrayRef[UpdateServerTlsPolicyRequest()];

coerce 'RepeatedUpdateServerTlsPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::UpdateServerTlsPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServerTlsPolicyRequest',
    as HashRef[UpdateServerTlsPolicyRequest()];

declare 'DeleteServerTlsPolicyRequest',
    as InstanceOf['Google::Cloud::Networksecurity::V1::ServerTlsPolicy::DeleteServerTlsPolicyRequest'];

coerce 'DeleteServerTlsPolicyRequest',
    from HashRef, via { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::DeleteServerTlsPolicyRequest'->new($_) };

declare 'RepeatedDeleteServerTlsPolicyRequest',
    as ArrayRef[DeleteServerTlsPolicyRequest()];

coerce 'RepeatedDeleteServerTlsPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networksecurity::V1::ServerTlsPolicy::DeleteServerTlsPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServerTlsPolicyRequest',
    as HashRef[DeleteServerTlsPolicyRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networksecurity::V1::ServerTlsPolicy::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
