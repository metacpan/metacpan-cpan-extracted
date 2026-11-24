package Google::Cloud::Dialogflow::V2beta1::PhoneNumber::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PhoneNumber',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber'];

coerce 'PhoneNumber',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber'->new($_) };

declare 'RepeatedPhoneNumber',
    as ArrayRef[PhoneNumber()];

coerce 'RepeatedPhoneNumber',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber'->new($_) } @$_ ] };

declare 'MapStringPhoneNumber',
    as HashRef[PhoneNumber()];

declare 'LifecycleState',
    as (Int | Str);

declare 'AllowedSipTrunks',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber::AllowedSipTrunks'];

coerce 'AllowedSipTrunks',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber::AllowedSipTrunks'->new($_) };

declare 'RepeatedAllowedSipTrunks',
    as ArrayRef[AllowedSipTrunks()];

coerce 'RepeatedAllowedSipTrunks',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::PhoneNumber::AllowedSipTrunks'->new($_) } @$_ ] };

declare 'MapStringAllowedSipTrunks',
    as HashRef[AllowedSipTrunks()];

declare 'DeletePhoneNumberRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::PhoneNumber::DeletePhoneNumberRequest'];

coerce 'DeletePhoneNumberRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::DeletePhoneNumberRequest'->new($_) };

declare 'RepeatedDeletePhoneNumberRequest',
    as ArrayRef[DeletePhoneNumberRequest()];

coerce 'RepeatedDeletePhoneNumberRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::DeletePhoneNumberRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePhoneNumberRequest',
    as HashRef[DeletePhoneNumberRequest()];

declare 'UndeletePhoneNumberRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::PhoneNumber::UndeletePhoneNumberRequest'];

coerce 'UndeletePhoneNumberRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::UndeletePhoneNumberRequest'->new($_) };

declare 'RepeatedUndeletePhoneNumberRequest',
    as ArrayRef[UndeletePhoneNumberRequest()];

coerce 'RepeatedUndeletePhoneNumberRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::UndeletePhoneNumberRequest'->new($_) } @$_ ] };

declare 'MapStringUndeletePhoneNumberRequest',
    as HashRef[UndeletePhoneNumberRequest()];

declare 'ListPhoneNumbersRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersRequest'];

coerce 'ListPhoneNumbersRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersRequest'->new($_) };

declare 'RepeatedListPhoneNumbersRequest',
    as ArrayRef[ListPhoneNumbersRequest()];

coerce 'RepeatedListPhoneNumbersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersRequest'->new($_) } @$_ ] };

declare 'MapStringListPhoneNumbersRequest',
    as HashRef[ListPhoneNumbersRequest()];

declare 'ListPhoneNumbersResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersResponse'];

coerce 'ListPhoneNumbersResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersResponse'->new($_) };

declare 'RepeatedListPhoneNumbersResponse',
    as ArrayRef[ListPhoneNumbersResponse()];

coerce 'RepeatedListPhoneNumbersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersResponse'->new($_) } @$_ ] };

declare 'MapStringListPhoneNumbersResponse',
    as HashRef[ListPhoneNumbersResponse()];

declare 'UpdatePhoneNumberRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::PhoneNumber::UpdatePhoneNumberRequest'];

coerce 'UpdatePhoneNumberRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::UpdatePhoneNumberRequest'->new($_) };

declare 'RepeatedUpdatePhoneNumberRequest',
    as ArrayRef[UpdatePhoneNumberRequest()];

coerce 'RepeatedUpdatePhoneNumberRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::UpdatePhoneNumberRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePhoneNumberRequest',
    as HashRef[UpdatePhoneNumberRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::PhoneNumber::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
