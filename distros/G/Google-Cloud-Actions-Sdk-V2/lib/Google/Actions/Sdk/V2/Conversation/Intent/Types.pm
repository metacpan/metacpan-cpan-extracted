package Google::Actions::Sdk::V2::Conversation::Intent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Intent',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Intent::Intent'];

coerce 'Intent',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Intent::Intent'->new($_) };

declare 'RepeatedIntent',
    as ArrayRef[Intent()];

coerce 'RepeatedIntent',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Intent::Intent'->new($_) } @$_ ] };

declare 'MapStringIntent',
    as HashRef[Intent()];

declare 'ParamsEntry',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Intent::Intent::ParamsEntry'];

coerce 'ParamsEntry',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Intent::Intent::ParamsEntry'->new($_) };

declare 'RepeatedParamsEntry',
    as ArrayRef[ParamsEntry()];

coerce 'RepeatedParamsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Intent::Intent::ParamsEntry'->new($_) } @$_ ] };

declare 'MapStringParamsEntry',
    as HashRef[ParamsEntry()];

declare 'IntentParameterValue',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Intent::IntentParameterValue'];

coerce 'IntentParameterValue',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Intent::IntentParameterValue'->new($_) };

declare 'RepeatedIntentParameterValue',
    as ArrayRef[IntentParameterValue()];

coerce 'RepeatedIntentParameterValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Intent::IntentParameterValue'->new($_) } @$_ ] };

declare 'MapStringIntentParameterValue',
    as HashRef[IntentParameterValue()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Intent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
