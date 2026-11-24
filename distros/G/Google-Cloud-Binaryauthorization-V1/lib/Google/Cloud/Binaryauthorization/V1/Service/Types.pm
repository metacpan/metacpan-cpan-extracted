package Google::Cloud::Binaryauthorization::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetPolicyRequest',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Service::GetPolicyRequest'];

coerce 'GetPolicyRequest',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Service::GetPolicyRequest'->new($_) };

declare 'RepeatedGetPolicyRequest',
    as ArrayRef[GetPolicyRequest()];

coerce 'RepeatedGetPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Service::GetPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetPolicyRequest',
    as HashRef[GetPolicyRequest()];

declare 'UpdatePolicyRequest',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Service::UpdatePolicyRequest'];

coerce 'UpdatePolicyRequest',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Service::UpdatePolicyRequest'->new($_) };

declare 'RepeatedUpdatePolicyRequest',
    as ArrayRef[UpdatePolicyRequest()];

coerce 'RepeatedUpdatePolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Service::UpdatePolicyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePolicyRequest',
    as HashRef[UpdatePolicyRequest()];

declare 'CreateAttestorRequest',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Service::CreateAttestorRequest'];

coerce 'CreateAttestorRequest',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Service::CreateAttestorRequest'->new($_) };

declare 'RepeatedCreateAttestorRequest',
    as ArrayRef[CreateAttestorRequest()];

coerce 'RepeatedCreateAttestorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Service::CreateAttestorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAttestorRequest',
    as HashRef[CreateAttestorRequest()];

declare 'GetAttestorRequest',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Service::GetAttestorRequest'];

coerce 'GetAttestorRequest',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Service::GetAttestorRequest'->new($_) };

declare 'RepeatedGetAttestorRequest',
    as ArrayRef[GetAttestorRequest()];

coerce 'RepeatedGetAttestorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Service::GetAttestorRequest'->new($_) } @$_ ] };

declare 'MapStringGetAttestorRequest',
    as HashRef[GetAttestorRequest()];

declare 'UpdateAttestorRequest',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Service::UpdateAttestorRequest'];

coerce 'UpdateAttestorRequest',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Service::UpdateAttestorRequest'->new($_) };

declare 'RepeatedUpdateAttestorRequest',
    as ArrayRef[UpdateAttestorRequest()];

coerce 'RepeatedUpdateAttestorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Service::UpdateAttestorRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAttestorRequest',
    as HashRef[UpdateAttestorRequest()];

declare 'ListAttestorsRequest',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Service::ListAttestorsRequest'];

coerce 'ListAttestorsRequest',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Service::ListAttestorsRequest'->new($_) };

declare 'RepeatedListAttestorsRequest',
    as ArrayRef[ListAttestorsRequest()];

coerce 'RepeatedListAttestorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Service::ListAttestorsRequest'->new($_) } @$_ ] };

declare 'MapStringListAttestorsRequest',
    as HashRef[ListAttestorsRequest()];

declare 'ListAttestorsResponse',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Service::ListAttestorsResponse'];

coerce 'ListAttestorsResponse',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Service::ListAttestorsResponse'->new($_) };

declare 'RepeatedListAttestorsResponse',
    as ArrayRef[ListAttestorsResponse()];

coerce 'RepeatedListAttestorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Service::ListAttestorsResponse'->new($_) } @$_ ] };

declare 'MapStringListAttestorsResponse',
    as HashRef[ListAttestorsResponse()];

declare 'DeleteAttestorRequest',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Service::DeleteAttestorRequest'];

coerce 'DeleteAttestorRequest',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Service::DeleteAttestorRequest'->new($_) };

declare 'RepeatedDeleteAttestorRequest',
    as ArrayRef[DeleteAttestorRequest()];

coerce 'RepeatedDeleteAttestorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Service::DeleteAttestorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAttestorRequest',
    as HashRef[DeleteAttestorRequest()];

declare 'GetSystemPolicyRequest',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Service::GetSystemPolicyRequest'];

coerce 'GetSystemPolicyRequest',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Service::GetSystemPolicyRequest'->new($_) };

declare 'RepeatedGetSystemPolicyRequest',
    as ArrayRef[GetSystemPolicyRequest()];

coerce 'RepeatedGetSystemPolicyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Service::GetSystemPolicyRequest'->new($_) } @$_ ] };

declare 'MapStringGetSystemPolicyRequest',
    as HashRef[GetSystemPolicyRequest()];

declare 'ValidateAttestationOccurrenceRequest',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceRequest'];

coerce 'ValidateAttestationOccurrenceRequest',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceRequest'->new($_) };

declare 'RepeatedValidateAttestationOccurrenceRequest',
    as ArrayRef[ValidateAttestationOccurrenceRequest()];

coerce 'RepeatedValidateAttestationOccurrenceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceRequest'->new($_) } @$_ ] };

declare 'MapStringValidateAttestationOccurrenceRequest',
    as HashRef[ValidateAttestationOccurrenceRequest()];

declare 'ValidateAttestationOccurrenceResponse',
    as InstanceOf['Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceResponse'];

coerce 'ValidateAttestationOccurrenceResponse',
    from HashRef, via { 'Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceResponse'->new($_) };

declare 'RepeatedValidateAttestationOccurrenceResponse',
    as ArrayRef[ValidateAttestationOccurrenceResponse()];

coerce 'RepeatedValidateAttestationOccurrenceResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Binaryauthorization::V1::Service::ValidateAttestationOccurrenceResponse'->new($_) } @$_ ] };

declare 'MapStringValidateAttestationOccurrenceResponse',
    as HashRef[ValidateAttestationOccurrenceResponse()];

declare 'Result',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Binaryauthorization::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
