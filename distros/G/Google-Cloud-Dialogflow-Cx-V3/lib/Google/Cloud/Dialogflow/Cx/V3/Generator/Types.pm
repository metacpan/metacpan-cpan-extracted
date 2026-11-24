package Google::Cloud::Dialogflow::Cx::V3::Generator::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Generator',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Generator::Generator'];

coerce 'Generator',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Generator::Generator'->new($_) };

declare 'RepeatedGenerator',
    as ArrayRef[Generator()];

coerce 'RepeatedGenerator',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Generator::Generator'->new($_) } @$_ ] };

declare 'MapStringGenerator',
    as HashRef[Generator()];

declare 'Placeholder',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Generator::Generator::Placeholder'];

coerce 'Placeholder',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Generator::Generator::Placeholder'->new($_) };

declare 'RepeatedPlaceholder',
    as ArrayRef[Placeholder()];

coerce 'RepeatedPlaceholder',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Generator::Generator::Placeholder'->new($_) } @$_ ] };

declare 'MapStringPlaceholder',
    as HashRef[Placeholder()];

declare 'ModelParameter',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Generator::Generator::ModelParameter'];

coerce 'ModelParameter',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Generator::Generator::ModelParameter'->new($_) };

declare 'RepeatedModelParameter',
    as ArrayRef[ModelParameter()];

coerce 'RepeatedModelParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Generator::Generator::ModelParameter'->new($_) } @$_ ] };

declare 'MapStringModelParameter',
    as HashRef[ModelParameter()];

declare 'Phrase',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Generator::Phrase'];

coerce 'Phrase',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Generator::Phrase'->new($_) };

declare 'RepeatedPhrase',
    as ArrayRef[Phrase()];

coerce 'RepeatedPhrase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Generator::Phrase'->new($_) } @$_ ] };

declare 'MapStringPhrase',
    as HashRef[Phrase()];

declare 'ListGeneratorsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsRequest'];

coerce 'ListGeneratorsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsRequest'->new($_) };

declare 'RepeatedListGeneratorsRequest',
    as ArrayRef[ListGeneratorsRequest()];

coerce 'RepeatedListGeneratorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsRequest'->new($_) } @$_ ] };

declare 'MapStringListGeneratorsRequest',
    as HashRef[ListGeneratorsRequest()];

declare 'ListGeneratorsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsResponse'];

coerce 'ListGeneratorsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsResponse'->new($_) };

declare 'RepeatedListGeneratorsResponse',
    as ArrayRef[ListGeneratorsResponse()];

coerce 'RepeatedListGeneratorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Generator::ListGeneratorsResponse'->new($_) } @$_ ] };

declare 'MapStringListGeneratorsResponse',
    as HashRef[ListGeneratorsResponse()];

declare 'GetGeneratorRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Generator::GetGeneratorRequest'];

coerce 'GetGeneratorRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Generator::GetGeneratorRequest'->new($_) };

declare 'RepeatedGetGeneratorRequest',
    as ArrayRef[GetGeneratorRequest()];

coerce 'RepeatedGetGeneratorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Generator::GetGeneratorRequest'->new($_) } @$_ ] };

declare 'MapStringGetGeneratorRequest',
    as HashRef[GetGeneratorRequest()];

declare 'CreateGeneratorRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Generator::CreateGeneratorRequest'];

coerce 'CreateGeneratorRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Generator::CreateGeneratorRequest'->new($_) };

declare 'RepeatedCreateGeneratorRequest',
    as ArrayRef[CreateGeneratorRequest()];

coerce 'RepeatedCreateGeneratorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Generator::CreateGeneratorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateGeneratorRequest',
    as HashRef[CreateGeneratorRequest()];

declare 'UpdateGeneratorRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Generator::UpdateGeneratorRequest'];

coerce 'UpdateGeneratorRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Generator::UpdateGeneratorRequest'->new($_) };

declare 'RepeatedUpdateGeneratorRequest',
    as ArrayRef[UpdateGeneratorRequest()];

coerce 'RepeatedUpdateGeneratorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Generator::UpdateGeneratorRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateGeneratorRequest',
    as HashRef[UpdateGeneratorRequest()];

declare 'DeleteGeneratorRequest',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::Generator::DeleteGeneratorRequest'];

coerce 'DeleteGeneratorRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::Generator::DeleteGeneratorRequest'->new($_) };

declare 'RepeatedDeleteGeneratorRequest',
    as ArrayRef[DeleteGeneratorRequest()];

coerce 'RepeatedDeleteGeneratorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::Generator::DeleteGeneratorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteGeneratorRequest',
    as HashRef[DeleteGeneratorRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::Generator::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
