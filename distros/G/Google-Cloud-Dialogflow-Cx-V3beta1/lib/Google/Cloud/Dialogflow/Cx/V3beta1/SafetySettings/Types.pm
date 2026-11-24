package Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SafetySettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings'];

coerce 'SafetySettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings'->new($_) };

declare 'RepeatedSafetySettings',
    as ArrayRef[SafetySettings()];

coerce 'RepeatedSafetySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings'->new($_) } @$_ ] };

declare 'MapStringSafetySettings',
    as HashRef[SafetySettings()];

declare 'PhraseMatchStrategy',
    as (Int | Str);

declare 'Phrase',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings::Phrase'];

coerce 'Phrase',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings::Phrase'->new($_) };

declare 'RepeatedPhrase',
    as ArrayRef[Phrase()];

coerce 'RepeatedPhrase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings::Phrase'->new($_) } @$_ ] };

declare 'MapStringPhrase',
    as HashRef[Phrase()];

declare 'RaiSettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings::RaiSettings'];

coerce 'RaiSettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings::RaiSettings'->new($_) };

declare 'RepeatedRaiSettings',
    as ArrayRef[RaiSettings()];

coerce 'RepeatedRaiSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings::RaiSettings'->new($_) } @$_ ] };

declare 'MapStringRaiSettings',
    as HashRef[RaiSettings()];

declare 'SafetyFilterLevel',
    as (Int | Str);

declare 'SafetyCategory',
    as (Int | Str);

declare 'CategoryFilter',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings::RaiSettings::CategoryFilter'];

coerce 'CategoryFilter',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings::RaiSettings::CategoryFilter'->new($_) };

declare 'RepeatedCategoryFilter',
    as ArrayRef[CategoryFilter()];

coerce 'RepeatedCategoryFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings::RaiSettings::CategoryFilter'->new($_) } @$_ ] };

declare 'MapStringCategoryFilter',
    as HashRef[CategoryFilter()];

declare 'PromptSecuritySettings',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings::PromptSecuritySettings'];

coerce 'PromptSecuritySettings',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings::PromptSecuritySettings'->new($_) };

declare 'RepeatedPromptSecuritySettings',
    as ArrayRef[PromptSecuritySettings()];

coerce 'RepeatedPromptSecuritySettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::SafetySettings::PromptSecuritySettings'->new($_) } @$_ ] };

declare 'MapStringPromptSecuritySettings',
    as HashRef[PromptSecuritySettings()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::SafetySettings::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
