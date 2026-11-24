package Google::Cloud::Dialogflow::Cx::V3beta1::Example::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateExampleRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Example::CreateExampleRequest'];

coerce 'CreateExampleRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::CreateExampleRequest'->new($_) };

declare 'RepeatedCreateExampleRequest',
    as ArrayRef[CreateExampleRequest()];

coerce 'RepeatedCreateExampleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::CreateExampleRequest'->new($_) } @$_ ] };

declare 'MapStringCreateExampleRequest',
    as HashRef[CreateExampleRequest()];

declare 'DeleteExampleRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Example::DeleteExampleRequest'];

coerce 'DeleteExampleRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::DeleteExampleRequest'->new($_) };

declare 'RepeatedDeleteExampleRequest',
    as ArrayRef[DeleteExampleRequest()];

coerce 'RepeatedDeleteExampleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::DeleteExampleRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteExampleRequest',
    as HashRef[DeleteExampleRequest()];

declare 'ListExamplesRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Example::ListExamplesRequest'];

coerce 'ListExamplesRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::ListExamplesRequest'->new($_) };

declare 'RepeatedListExamplesRequest',
    as ArrayRef[ListExamplesRequest()];

coerce 'RepeatedListExamplesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::ListExamplesRequest'->new($_) } @$_ ] };

declare 'MapStringListExamplesRequest',
    as HashRef[ListExamplesRequest()];

declare 'ListExamplesResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Example::ListExamplesResponse'];

coerce 'ListExamplesResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::ListExamplesResponse'->new($_) };

declare 'RepeatedListExamplesResponse',
    as ArrayRef[ListExamplesResponse()];

coerce 'RepeatedListExamplesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::ListExamplesResponse'->new($_) } @$_ ] };

declare 'MapStringListExamplesResponse',
    as HashRef[ListExamplesResponse()];

declare 'GetExampleRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Example::GetExampleRequest'];

coerce 'GetExampleRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::GetExampleRequest'->new($_) };

declare 'RepeatedGetExampleRequest',
    as ArrayRef[GetExampleRequest()];

coerce 'RepeatedGetExampleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::GetExampleRequest'->new($_) } @$_ ] };

declare 'MapStringGetExampleRequest',
    as HashRef[GetExampleRequest()];

declare 'UpdateExampleRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Example::UpdateExampleRequest'];

coerce 'UpdateExampleRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::UpdateExampleRequest'->new($_) };

declare 'RepeatedUpdateExampleRequest',
    as ArrayRef[UpdateExampleRequest()];

coerce 'RepeatedUpdateExampleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::UpdateExampleRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateExampleRequest',
    as HashRef[UpdateExampleRequest()];

declare 'Example',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example'];

coerce 'Example',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example'->new($_) };

declare 'RepeatedExample',
    as ArrayRef[Example()];

coerce 'RepeatedExample',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Example::Example'->new($_) } @$_ ] };

declare 'MapStringExample',
    as HashRef[Example()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Example::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
