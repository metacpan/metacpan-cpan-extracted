package Google::Cloud::Dialogflow::V2::SessionEntityType::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SessionEntityType',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType'];

coerce 'SessionEntityType',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType'->new($_) };

declare 'RepeatedSessionEntityType',
    as ArrayRef[SessionEntityType()];

coerce 'RepeatedSessionEntityType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SessionEntityType::SessionEntityType'->new($_) } @$_ ] };

declare 'MapStringSessionEntityType',
    as HashRef[SessionEntityType()];

declare 'EntityOverrideMode',
    as (Int | Str);

declare 'ListSessionEntityTypesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SessionEntityType::ListSessionEntityTypesRequest'];

coerce 'ListSessionEntityTypesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SessionEntityType::ListSessionEntityTypesRequest'->new($_) };

declare 'RepeatedListSessionEntityTypesRequest',
    as ArrayRef[ListSessionEntityTypesRequest()];

coerce 'RepeatedListSessionEntityTypesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SessionEntityType::ListSessionEntityTypesRequest'->new($_) } @$_ ] };

declare 'MapStringListSessionEntityTypesRequest',
    as HashRef[ListSessionEntityTypesRequest()];

declare 'ListSessionEntityTypesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SessionEntityType::ListSessionEntityTypesResponse'];

coerce 'ListSessionEntityTypesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SessionEntityType::ListSessionEntityTypesResponse'->new($_) };

declare 'RepeatedListSessionEntityTypesResponse',
    as ArrayRef[ListSessionEntityTypesResponse()];

coerce 'RepeatedListSessionEntityTypesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SessionEntityType::ListSessionEntityTypesResponse'->new($_) } @$_ ] };

declare 'MapStringListSessionEntityTypesResponse',
    as HashRef[ListSessionEntityTypesResponse()];

declare 'GetSessionEntityTypeRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SessionEntityType::GetSessionEntityTypeRequest'];

coerce 'GetSessionEntityTypeRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SessionEntityType::GetSessionEntityTypeRequest'->new($_) };

declare 'RepeatedGetSessionEntityTypeRequest',
    as ArrayRef[GetSessionEntityTypeRequest()];

coerce 'RepeatedGetSessionEntityTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SessionEntityType::GetSessionEntityTypeRequest'->new($_) } @$_ ] };

declare 'MapStringGetSessionEntityTypeRequest',
    as HashRef[GetSessionEntityTypeRequest()];

declare 'CreateSessionEntityTypeRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SessionEntityType::CreateSessionEntityTypeRequest'];

coerce 'CreateSessionEntityTypeRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SessionEntityType::CreateSessionEntityTypeRequest'->new($_) };

declare 'RepeatedCreateSessionEntityTypeRequest',
    as ArrayRef[CreateSessionEntityTypeRequest()];

coerce 'RepeatedCreateSessionEntityTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SessionEntityType::CreateSessionEntityTypeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateSessionEntityTypeRequest',
    as HashRef[CreateSessionEntityTypeRequest()];

declare 'UpdateSessionEntityTypeRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SessionEntityType::UpdateSessionEntityTypeRequest'];

coerce 'UpdateSessionEntityTypeRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SessionEntityType::UpdateSessionEntityTypeRequest'->new($_) };

declare 'RepeatedUpdateSessionEntityTypeRequest',
    as ArrayRef[UpdateSessionEntityTypeRequest()];

coerce 'RepeatedUpdateSessionEntityTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SessionEntityType::UpdateSessionEntityTypeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateSessionEntityTypeRequest',
    as HashRef[UpdateSessionEntityTypeRequest()];

declare 'DeleteSessionEntityTypeRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::SessionEntityType::DeleteSessionEntityTypeRequest'];

coerce 'DeleteSessionEntityTypeRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::SessionEntityType::DeleteSessionEntityTypeRequest'->new($_) };

declare 'RepeatedDeleteSessionEntityTypeRequest',
    as ArrayRef[DeleteSessionEntityTypeRequest()];

coerce 'RepeatedDeleteSessionEntityTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::SessionEntityType::DeleteSessionEntityTypeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteSessionEntityTypeRequest',
    as HashRef[DeleteSessionEntityTypeRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::SessionEntityType::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
