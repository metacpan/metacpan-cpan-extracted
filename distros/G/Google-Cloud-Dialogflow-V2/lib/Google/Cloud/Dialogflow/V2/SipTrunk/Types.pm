package Google::Cloud::Dialogflow::V2::SipTrunk::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateSipTrunkRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SipTrunk::CreateSipTrunkRequest'];

coerce 'CreateSipTrunkRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SipTrunk::CreateSipTrunkRequest'->new($_) };

declare 'RepeatedCreateSipTrunkRequest',
    as ArrayRef[CreateSipTrunkRequest()];

coerce 'RepeatedCreateSipTrunkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SipTrunk::CreateSipTrunkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSipTrunkRequest',
    as HashRef[CreateSipTrunkRequest()];

declare 'DeleteSipTrunkRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SipTrunk::DeleteSipTrunkRequest'];

coerce 'DeleteSipTrunkRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SipTrunk::DeleteSipTrunkRequest'->new($_) };

declare 'RepeatedDeleteSipTrunkRequest',
    as ArrayRef[DeleteSipTrunkRequest()];

coerce 'RepeatedDeleteSipTrunkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SipTrunk::DeleteSipTrunkRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSipTrunkRequest',
    as HashRef[DeleteSipTrunkRequest()];

declare 'ListSipTrunksRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SipTrunk::ListSipTrunksRequest'];

coerce 'ListSipTrunksRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SipTrunk::ListSipTrunksRequest'->new($_) };

declare 'RepeatedListSipTrunksRequest',
    as ArrayRef[ListSipTrunksRequest()];

coerce 'RepeatedListSipTrunksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SipTrunk::ListSipTrunksRequest'->new($_) } @$_ ] };

declare 'MapStringListSipTrunksRequest',
    as HashRef[ListSipTrunksRequest()];

declare 'ListSipTrunksResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SipTrunk::ListSipTrunksResponse'];

coerce 'ListSipTrunksResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SipTrunk::ListSipTrunksResponse'->new($_) };

declare 'RepeatedListSipTrunksResponse',
    as ArrayRef[ListSipTrunksResponse()];

coerce 'RepeatedListSipTrunksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SipTrunk::ListSipTrunksResponse'->new($_) } @$_ ] };

declare 'MapStringListSipTrunksResponse',
    as HashRef[ListSipTrunksResponse()];

declare 'GetSipTrunkRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SipTrunk::GetSipTrunkRequest'];

coerce 'GetSipTrunkRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SipTrunk::GetSipTrunkRequest'->new($_) };

declare 'RepeatedGetSipTrunkRequest',
    as ArrayRef[GetSipTrunkRequest()];

coerce 'RepeatedGetSipTrunkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SipTrunk::GetSipTrunkRequest'->new($_) } @$_ ] };

declare 'MapStringGetSipTrunkRequest',
    as HashRef[GetSipTrunkRequest()];

declare 'UpdateSipTrunkRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SipTrunk::UpdateSipTrunkRequest'];

coerce 'UpdateSipTrunkRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SipTrunk::UpdateSipTrunkRequest'->new($_) };

declare 'RepeatedUpdateSipTrunkRequest',
    as ArrayRef[UpdateSipTrunkRequest()];

coerce 'RepeatedUpdateSipTrunkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SipTrunk::UpdateSipTrunkRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSipTrunkRequest',
    as HashRef[UpdateSipTrunkRequest()];

declare 'SipTrunk',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunk'];

coerce 'SipTrunk',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunk'->new($_) };

declare 'RepeatedSipTrunk',
    as ArrayRef[SipTrunk()];

coerce 'RepeatedSipTrunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SipTrunk::SipTrunk'->new($_) } @$_ ] };

declare 'MapStringSipTrunk',
    as HashRef[SipTrunk()];

declare 'GoogleRootCertFile',
    as (Int | Str);

declare 'Connection',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SipTrunk::Connection'];

coerce 'Connection',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SipTrunk::Connection'->new($_) };

declare 'RepeatedConnection',
    as ArrayRef[Connection()];

coerce 'RepeatedConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SipTrunk::Connection'->new($_) } @$_ ] };

declare 'MapStringConnection',
    as HashRef[Connection()];

declare 'State',
    as (Int | Str);

declare 'CertificateState',
    as (Int | Str);

declare 'ErrorDetails',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SipTrunk::Connection::ErrorDetails'];

coerce 'ErrorDetails',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SipTrunk::Connection::ErrorDetails'->new($_) };

declare 'RepeatedErrorDetails',
    as ArrayRef[ErrorDetails()];

coerce 'RepeatedErrorDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SipTrunk::Connection::ErrorDetails'->new($_) } @$_ ] };

declare 'MapStringErrorDetails',
    as HashRef[ErrorDetails()];

declare 'SipHostname',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SipTrunk::SipHostname'];

coerce 'SipHostname',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SipTrunk::SipHostname'->new($_) };

declare 'RepeatedSipHostname',
    as ArrayRef[SipHostname()];

coerce 'RepeatedSipHostname',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SipTrunk::SipHostname'->new($_) } @$_ ] };

declare 'MapStringSipHostname',
    as HashRef[SipHostname()];

declare 'ConnectionState',
    as (Int | Str);

declare 'HostnameCertificateState',
    as (Int | Str);

declare 'HostnameErrorDetails',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SipTrunk::SipHostname::HostnameErrorDetails'];

coerce 'HostnameErrorDetails',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SipTrunk::SipHostname::HostnameErrorDetails'->new($_) };

declare 'RepeatedHostnameErrorDetails',
    as ArrayRef[HostnameErrorDetails()];

coerce 'RepeatedHostnameErrorDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SipTrunk::SipHostname::HostnameErrorDetails'->new($_) } @$_ ] };

declare 'MapStringHostnameErrorDetails',
    as HashRef[HostnameErrorDetails()];

declare 'ProbeDetails',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SipTrunk::ProbeDetails'];

coerce 'ProbeDetails',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SipTrunk::ProbeDetails'->new($_) };

declare 'RepeatedProbeDetails',
    as ArrayRef[ProbeDetails()];

coerce 'RepeatedProbeDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SipTrunk::ProbeDetails'->new($_) } @$_ ] };

declare 'MapStringProbeDetails',
    as HashRef[ProbeDetails()];

declare 'ProbeStatus',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::SipTrunk::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
