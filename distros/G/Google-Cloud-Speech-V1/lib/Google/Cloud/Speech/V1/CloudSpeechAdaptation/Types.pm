package Google::Cloud::Speech::V1::CloudSpeechAdaptation::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreatePhraseSetRequest',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreatePhraseSetRequest'];

coerce 'CreatePhraseSetRequest',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreatePhraseSetRequest'->new($_) };

declare 'RepeatedCreatePhraseSetRequest',
    as ArrayRef[CreatePhraseSetRequest()];

coerce 'RepeatedCreatePhraseSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreatePhraseSetRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePhraseSetRequest',
    as HashRef[CreatePhraseSetRequest()];

declare 'UpdatePhraseSetRequest',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeechAdaptation::UpdatePhraseSetRequest'];

coerce 'UpdatePhraseSetRequest',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::UpdatePhraseSetRequest'->new($_) };

declare 'RepeatedUpdatePhraseSetRequest',
    as ArrayRef[UpdatePhraseSetRequest()];

coerce 'RepeatedUpdatePhraseSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::UpdatePhraseSetRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePhraseSetRequest',
    as HashRef[UpdatePhraseSetRequest()];

declare 'GetPhraseSetRequest',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeechAdaptation::GetPhraseSetRequest'];

coerce 'GetPhraseSetRequest',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::GetPhraseSetRequest'->new($_) };

declare 'RepeatedGetPhraseSetRequest',
    as ArrayRef[GetPhraseSetRequest()];

coerce 'RepeatedGetPhraseSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::GetPhraseSetRequest'->new($_) } @$_ ] };

declare 'MapStringGetPhraseSetRequest',
    as HashRef[GetPhraseSetRequest()];

declare 'ListPhraseSetRequest',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListPhraseSetRequest'];

coerce 'ListPhraseSetRequest',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListPhraseSetRequest'->new($_) };

declare 'RepeatedListPhraseSetRequest',
    as ArrayRef[ListPhraseSetRequest()];

coerce 'RepeatedListPhraseSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListPhraseSetRequest'->new($_) } @$_ ] };

declare 'MapStringListPhraseSetRequest',
    as HashRef[ListPhraseSetRequest()];

declare 'ListPhraseSetResponse',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListPhraseSetResponse'];

coerce 'ListPhraseSetResponse',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListPhraseSetResponse'->new($_) };

declare 'RepeatedListPhraseSetResponse',
    as ArrayRef[ListPhraseSetResponse()];

coerce 'RepeatedListPhraseSetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListPhraseSetResponse'->new($_) } @$_ ] };

declare 'MapStringListPhraseSetResponse',
    as HashRef[ListPhraseSetResponse()];

declare 'DeletePhraseSetRequest',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeechAdaptation::DeletePhraseSetRequest'];

coerce 'DeletePhraseSetRequest',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::DeletePhraseSetRequest'->new($_) };

declare 'RepeatedDeletePhraseSetRequest',
    as ArrayRef[DeletePhraseSetRequest()];

coerce 'RepeatedDeletePhraseSetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::DeletePhraseSetRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePhraseSetRequest',
    as HashRef[DeletePhraseSetRequest()];

declare 'CreateCustomClassRequest',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreateCustomClassRequest'];

coerce 'CreateCustomClassRequest',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreateCustomClassRequest'->new($_) };

declare 'RepeatedCreateCustomClassRequest',
    as ArrayRef[CreateCustomClassRequest()];

coerce 'RepeatedCreateCustomClassRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::CreateCustomClassRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCustomClassRequest',
    as HashRef[CreateCustomClassRequest()];

declare 'UpdateCustomClassRequest',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeechAdaptation::UpdateCustomClassRequest'];

coerce 'UpdateCustomClassRequest',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::UpdateCustomClassRequest'->new($_) };

declare 'RepeatedUpdateCustomClassRequest',
    as ArrayRef[UpdateCustomClassRequest()];

coerce 'RepeatedUpdateCustomClassRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::UpdateCustomClassRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCustomClassRequest',
    as HashRef[UpdateCustomClassRequest()];

declare 'GetCustomClassRequest',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeechAdaptation::GetCustomClassRequest'];

coerce 'GetCustomClassRequest',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::GetCustomClassRequest'->new($_) };

declare 'RepeatedGetCustomClassRequest',
    as ArrayRef[GetCustomClassRequest()];

coerce 'RepeatedGetCustomClassRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::GetCustomClassRequest'->new($_) } @$_ ] };

declare 'MapStringGetCustomClassRequest',
    as HashRef[GetCustomClassRequest()];

declare 'ListCustomClassesRequest',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListCustomClassesRequest'];

coerce 'ListCustomClassesRequest',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListCustomClassesRequest'->new($_) };

declare 'RepeatedListCustomClassesRequest',
    as ArrayRef[ListCustomClassesRequest()];

coerce 'RepeatedListCustomClassesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListCustomClassesRequest'->new($_) } @$_ ] };

declare 'MapStringListCustomClassesRequest',
    as HashRef[ListCustomClassesRequest()];

declare 'ListCustomClassesResponse',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListCustomClassesResponse'];

coerce 'ListCustomClassesResponse',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListCustomClassesResponse'->new($_) };

declare 'RepeatedListCustomClassesResponse',
    as ArrayRef[ListCustomClassesResponse()];

coerce 'RepeatedListCustomClassesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::ListCustomClassesResponse'->new($_) } @$_ ] };

declare 'MapStringListCustomClassesResponse',
    as HashRef[ListCustomClassesResponse()];

declare 'DeleteCustomClassRequest',
    as InstanceOf['Google::Cloud::Speech::V1::CloudSpeechAdaptation::DeleteCustomClassRequest'];

coerce 'DeleteCustomClassRequest',
    from HashRef, via { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::DeleteCustomClassRequest'->new($_) };

declare 'RepeatedDeleteCustomClassRequest',
    as ArrayRef[DeleteCustomClassRequest()];

coerce 'RepeatedDeleteCustomClassRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Speech::V1::CloudSpeechAdaptation::DeleteCustomClassRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCustomClassRequest',
    as HashRef[DeleteCustomClassRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Speech::V1::CloudSpeechAdaptation::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
