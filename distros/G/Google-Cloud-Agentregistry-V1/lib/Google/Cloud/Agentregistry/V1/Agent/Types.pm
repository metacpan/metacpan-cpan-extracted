package Google::Cloud::Agentregistry::V1::Agent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Agent',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Agent::Agent'];

coerce 'Agent',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Agent::Agent'->new($_) };

declare 'RepeatedAgent',
    as ArrayRef[Agent()];

coerce 'RepeatedAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Agent::Agent'->new($_) } @$_ ] };

declare 'MapStringAgent',
    as HashRef[Agent()];

declare 'Protocol',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Agent::Agent::Protocol'];

coerce 'Protocol',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Agent::Agent::Protocol'->new($_) };

declare 'RepeatedProtocol',
    as ArrayRef[Protocol()];

coerce 'RepeatedProtocol',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Agent::Agent::Protocol'->new($_) } @$_ ] };

declare 'MapStringProtocol',
    as HashRef[Protocol()];

declare 'Type',
    as (Int | Str);

declare 'Skill',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Agent::Agent::Skill'];

coerce 'Skill',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Agent::Agent::Skill'->new($_) };

declare 'RepeatedSkill',
    as ArrayRef[Skill()];

coerce 'RepeatedSkill',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Agent::Agent::Skill'->new($_) } @$_ ] };

declare 'MapStringSkill',
    as HashRef[Skill()];

declare 'Card',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Agent::Agent::Card'];

coerce 'Card',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Agent::Agent::Card'->new($_) };

declare 'RepeatedCard',
    as ArrayRef[Card()];

coerce 'RepeatedCard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Agent::Agent::Card'->new($_) } @$_ ] };

declare 'MapStringCard',
    as HashRef[Card()];

declare 'Type',
    as (Int | Str);

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Agentregistry::V1::Agent::Agent::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::Agent::Agent::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::Agent::Agent::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Agentregistry::V1::Agent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
