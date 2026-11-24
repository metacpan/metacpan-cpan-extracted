package Google::Cloud::Essentialcontacts::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Contact',
    as InstanceOf['Google::Cloud::Essentialcontacts::V1::Service::Contact'];

coerce 'Contact',
    from HashRef, via { 'Google::Cloud::Essentialcontacts::V1::Service::Contact'->new($_) };

declare 'RepeatedContact',
    as ArrayRef[Contact()];

coerce 'RepeatedContact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Essentialcontacts::V1::Service::Contact'->new($_) } @$_ ] };

declare 'MapStringContact',
    as HashRef[Contact()];

declare 'ListContactsRequest',
    as InstanceOf['Google::Cloud::Essentialcontacts::V1::Service::ListContactsRequest'];

coerce 'ListContactsRequest',
    from HashRef, via { 'Google::Cloud::Essentialcontacts::V1::Service::ListContactsRequest'->new($_) };

declare 'RepeatedListContactsRequest',
    as ArrayRef[ListContactsRequest()];

coerce 'RepeatedListContactsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Essentialcontacts::V1::Service::ListContactsRequest'->new($_) } @$_ ] };

declare 'MapStringListContactsRequest',
    as HashRef[ListContactsRequest()];

declare 'ListContactsResponse',
    as InstanceOf['Google::Cloud::Essentialcontacts::V1::Service::ListContactsResponse'];

coerce 'ListContactsResponse',
    from HashRef, via { 'Google::Cloud::Essentialcontacts::V1::Service::ListContactsResponse'->new($_) };

declare 'RepeatedListContactsResponse',
    as ArrayRef[ListContactsResponse()];

coerce 'RepeatedListContactsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Essentialcontacts::V1::Service::ListContactsResponse'->new($_) } @$_ ] };

declare 'MapStringListContactsResponse',
    as HashRef[ListContactsResponse()];

declare 'GetContactRequest',
    as InstanceOf['Google::Cloud::Essentialcontacts::V1::Service::GetContactRequest'];

coerce 'GetContactRequest',
    from HashRef, via { 'Google::Cloud::Essentialcontacts::V1::Service::GetContactRequest'->new($_) };

declare 'RepeatedGetContactRequest',
    as ArrayRef[GetContactRequest()];

coerce 'RepeatedGetContactRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Essentialcontacts::V1::Service::GetContactRequest'->new($_) } @$_ ] };

declare 'MapStringGetContactRequest',
    as HashRef[GetContactRequest()];

declare 'DeleteContactRequest',
    as InstanceOf['Google::Cloud::Essentialcontacts::V1::Service::DeleteContactRequest'];

coerce 'DeleteContactRequest',
    from HashRef, via { 'Google::Cloud::Essentialcontacts::V1::Service::DeleteContactRequest'->new($_) };

declare 'RepeatedDeleteContactRequest',
    as ArrayRef[DeleteContactRequest()];

coerce 'RepeatedDeleteContactRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Essentialcontacts::V1::Service::DeleteContactRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteContactRequest',
    as HashRef[DeleteContactRequest()];

declare 'CreateContactRequest',
    as InstanceOf['Google::Cloud::Essentialcontacts::V1::Service::CreateContactRequest'];

coerce 'CreateContactRequest',
    from HashRef, via { 'Google::Cloud::Essentialcontacts::V1::Service::CreateContactRequest'->new($_) };

declare 'RepeatedCreateContactRequest',
    as ArrayRef[CreateContactRequest()];

coerce 'RepeatedCreateContactRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Essentialcontacts::V1::Service::CreateContactRequest'->new($_) } @$_ ] };

declare 'MapStringCreateContactRequest',
    as HashRef[CreateContactRequest()];

declare 'UpdateContactRequest',
    as InstanceOf['Google::Cloud::Essentialcontacts::V1::Service::UpdateContactRequest'];

coerce 'UpdateContactRequest',
    from HashRef, via { 'Google::Cloud::Essentialcontacts::V1::Service::UpdateContactRequest'->new($_) };

declare 'RepeatedUpdateContactRequest',
    as ArrayRef[UpdateContactRequest()];

coerce 'RepeatedUpdateContactRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Essentialcontacts::V1::Service::UpdateContactRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateContactRequest',
    as HashRef[UpdateContactRequest()];

declare 'ComputeContactsRequest',
    as InstanceOf['Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsRequest'];

coerce 'ComputeContactsRequest',
    from HashRef, via { 'Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsRequest'->new($_) };

declare 'RepeatedComputeContactsRequest',
    as ArrayRef[ComputeContactsRequest()];

coerce 'RepeatedComputeContactsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsRequest'->new($_) } @$_ ] };

declare 'MapStringComputeContactsRequest',
    as HashRef[ComputeContactsRequest()];

declare 'ComputeContactsResponse',
    as InstanceOf['Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsResponse'];

coerce 'ComputeContactsResponse',
    from HashRef, via { 'Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsResponse'->new($_) };

declare 'RepeatedComputeContactsResponse',
    as ArrayRef[ComputeContactsResponse()];

coerce 'RepeatedComputeContactsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Essentialcontacts::V1::Service::ComputeContactsResponse'->new($_) } @$_ ] };

declare 'MapStringComputeContactsResponse',
    as HashRef[ComputeContactsResponse()];

declare 'SendTestMessageRequest',
    as InstanceOf['Google::Cloud::Essentialcontacts::V1::Service::SendTestMessageRequest'];

coerce 'SendTestMessageRequest',
    from HashRef, via { 'Google::Cloud::Essentialcontacts::V1::Service::SendTestMessageRequest'->new($_) };

declare 'RepeatedSendTestMessageRequest',
    as ArrayRef[SendTestMessageRequest()];

coerce 'RepeatedSendTestMessageRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Essentialcontacts::V1::Service::SendTestMessageRequest'->new($_) } @$_ ] };

declare 'MapStringSendTestMessageRequest',
    as HashRef[SendTestMessageRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Essentialcontacts::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
