package Google::Cloud::Agentregistry::V1::AiApplication::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AiApplication',
    as InstanceOf['Google::Cloud::Agentregistry::V1::AiApplication::AiApplication'];

coerce 'AiApplication',
    from HashRef, via { 'Google::Cloud::Agentregistry::V1::AiApplication::AiApplication'->new($_) };

declare 'RepeatedAiApplication',
    as ArrayRef[AiApplication()];

coerce 'RepeatedAiApplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Agentregistry::V1::AiApplication::AiApplication'->new($_) } @$_ ] };

declare 'MapStringAiApplication',
    as HashRef[AiApplication()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Agentregistry::V1::AiApplication::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
