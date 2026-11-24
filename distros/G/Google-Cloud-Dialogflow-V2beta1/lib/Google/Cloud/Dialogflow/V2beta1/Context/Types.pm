package Google::Cloud::Dialogflow::V2beta1::Context::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Context',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Context::Context'];

coerce 'Context',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Context::Context'->new($_) };

declare 'RepeatedContext',
    as ArrayRef[Context()];

coerce 'RepeatedContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Context::Context'->new($_) } @$_ ] };

declare 'MapStringContext',
    as HashRef[Context()];

declare 'ListContextsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Context::ListContextsRequest'];

coerce 'ListContextsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Context::ListContextsRequest'->new($_) };

declare 'RepeatedListContextsRequest',
    as ArrayRef[ListContextsRequest()];

coerce 'RepeatedListContextsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Context::ListContextsRequest'->new($_) } @$_ ] };

declare 'MapStringListContextsRequest',
    as HashRef[ListContextsRequest()];

declare 'ListContextsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Context::ListContextsResponse'];

coerce 'ListContextsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Context::ListContextsResponse'->new($_) };

declare 'RepeatedListContextsResponse',
    as ArrayRef[ListContextsResponse()];

coerce 'RepeatedListContextsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Context::ListContextsResponse'->new($_) } @$_ ] };

declare 'MapStringListContextsResponse',
    as HashRef[ListContextsResponse()];

declare 'GetContextRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Context::GetContextRequest'];

coerce 'GetContextRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Context::GetContextRequest'->new($_) };

declare 'RepeatedGetContextRequest',
    as ArrayRef[GetContextRequest()];

coerce 'RepeatedGetContextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Context::GetContextRequest'->new($_) } @$_ ] };

declare 'MapStringGetContextRequest',
    as HashRef[GetContextRequest()];

declare 'CreateContextRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Context::CreateContextRequest'];

coerce 'CreateContextRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Context::CreateContextRequest'->new($_) };

declare 'RepeatedCreateContextRequest',
    as ArrayRef[CreateContextRequest()];

coerce 'RepeatedCreateContextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Context::CreateContextRequest'->new($_) } @$_ ] };

declare 'MapStringCreateContextRequest',
    as HashRef[CreateContextRequest()];

declare 'UpdateContextRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Context::UpdateContextRequest'];

coerce 'UpdateContextRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Context::UpdateContextRequest'->new($_) };

declare 'RepeatedUpdateContextRequest',
    as ArrayRef[UpdateContextRequest()];

coerce 'RepeatedUpdateContextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Context::UpdateContextRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateContextRequest',
    as HashRef[UpdateContextRequest()];

declare 'DeleteContextRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Context::DeleteContextRequest'];

coerce 'DeleteContextRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Context::DeleteContextRequest'->new($_) };

declare 'RepeatedDeleteContextRequest',
    as ArrayRef[DeleteContextRequest()];

coerce 'RepeatedDeleteContextRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Context::DeleteContextRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteContextRequest',
    as HashRef[DeleteContextRequest()];

declare 'DeleteAllContextsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2beta1::Context::DeleteAllContextsRequest'];

coerce 'DeleteAllContextsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2beta1::Context::DeleteAllContextsRequest'->new($_) };

declare 'RepeatedDeleteAllContextsRequest',
    as ArrayRef[DeleteAllContextsRequest()];

coerce 'RepeatedDeleteAllContextsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2beta1::Context::DeleteAllContextsRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAllContextsRequest',
    as HashRef[DeleteAllContextsRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2beta1::Context::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
