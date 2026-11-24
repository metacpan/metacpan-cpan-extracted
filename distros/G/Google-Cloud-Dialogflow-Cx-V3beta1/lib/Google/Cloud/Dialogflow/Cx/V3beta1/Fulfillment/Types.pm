package Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Fulfillment',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment'];

coerce 'Fulfillment',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment'->new($_) };

declare 'RepeatedFulfillment',
    as ArrayRef[Fulfillment()];

coerce 'RepeatedFulfillment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment'->new($_) } @$_ ] };

declare 'MapStringFulfillment',
    as HashRef[Fulfillment()];

declare 'SetParameterAction',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::SetParameterAction'];

coerce 'SetParameterAction',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::SetParameterAction'->new($_) };

declare 'RepeatedSetParameterAction',
    as ArrayRef[SetParameterAction()];

coerce 'RepeatedSetParameterAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::SetParameterAction'->new($_) } @$_ ] };

declare 'MapStringSetParameterAction',
    as HashRef[SetParameterAction()];

declare 'ConditionalCases',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::ConditionalCases'];

coerce 'ConditionalCases',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::ConditionalCases'->new($_) };

declare 'RepeatedConditionalCases',
    as ArrayRef[ConditionalCases()];

coerce 'RepeatedConditionalCases',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::ConditionalCases'->new($_) } @$_ ] };

declare 'MapStringConditionalCases',
    as HashRef[ConditionalCases()];

declare 'Case',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::ConditionalCases::Case'];

coerce 'Case',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::ConditionalCases::Case'->new($_) };

declare 'RepeatedCase',
    as ArrayRef[Case()];

coerce 'RepeatedCase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::ConditionalCases::Case'->new($_) } @$_ ] };

declare 'MapStringCase',
    as HashRef[Case()];

declare 'CaseContent',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::ConditionalCases::Case::CaseContent'];

coerce 'CaseContent',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::ConditionalCases::Case::CaseContent'->new($_) };

declare 'RepeatedCaseContent',
    as ArrayRef[CaseContent()];

coerce 'RepeatedCaseContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::ConditionalCases::Case::CaseContent'->new($_) } @$_ ] };

declare 'MapStringCaseContent',
    as HashRef[CaseContent()];

declare 'GeneratorSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::GeneratorSettings'];

coerce 'GeneratorSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::GeneratorSettings'->new($_) };

declare 'RepeatedGeneratorSettings',
    as ArrayRef[GeneratorSettings()];

coerce 'RepeatedGeneratorSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::GeneratorSettings'->new($_) } @$_ ] };

declare 'MapStringGeneratorSettings',
    as HashRef[GeneratorSettings()];

declare 'InputParametersEntry',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::GeneratorSettings::InputParametersEntry'];

coerce 'InputParametersEntry',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::GeneratorSettings::InputParametersEntry'->new($_) };

declare 'RepeatedInputParametersEntry',
    as ArrayRef[InputParametersEntry()];

coerce 'RepeatedInputParametersEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Fulfillment::GeneratorSettings::InputParametersEntry'->new($_) } @$_ ] };

declare 'MapStringInputParametersEntry',
    as HashRef[InputParametersEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::Fulfillment::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
