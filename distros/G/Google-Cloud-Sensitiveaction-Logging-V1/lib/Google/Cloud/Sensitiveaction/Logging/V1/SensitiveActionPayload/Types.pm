package Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SensitiveAction',
    as InstanceOf['Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::SensitiveAction'];

coerce 'SensitiveAction',
    from HashRef, via { 'Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::SensitiveAction'->new($_) };

declare 'RepeatedSensitiveAction',
    as ArrayRef[SensitiveAction()];

coerce 'RepeatedSensitiveAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::SensitiveAction'->new($_) } @$_ ] };

declare 'MapStringSensitiveAction',
    as HashRef[SensitiveAction()];

declare 'SourceLogId',
    as InstanceOf['Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::SensitiveAction::SourceLogId'];

coerce 'SourceLogId',
    from HashRef, via { 'Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::SensitiveAction::SourceLogId'->new($_) };

declare 'RepeatedSourceLogId',
    as ArrayRef[SourceLogId()];

coerce 'RepeatedSourceLogId',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::SensitiveAction::SourceLogId'->new($_) } @$_ ] };

declare 'MapStringSourceLogId',
    as HashRef[SourceLogId()];

1;

__END__

=head1 NAME

Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
