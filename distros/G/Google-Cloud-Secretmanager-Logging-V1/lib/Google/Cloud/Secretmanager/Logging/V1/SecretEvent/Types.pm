package Google::Cloud::Secretmanager::Logging::V1::SecretEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SecretEvent',
    as InstanceOf['Google::Cloud::Secretmanager::Logging::V1::SecretEvent::SecretEvent'];

coerce 'SecretEvent',
    from HashRef, via { 'Google::Cloud::Secretmanager::Logging::V1::SecretEvent::SecretEvent'->new($_) };

declare 'RepeatedSecretEvent',
    as ArrayRef[SecretEvent()];

coerce 'RepeatedSecretEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Secretmanager::Logging::V1::SecretEvent::SecretEvent'->new($_) } @$_ ] };

declare 'MapStringSecretEvent',
    as HashRef[SecretEvent()];

declare 'EventType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Secretmanager::Logging::V1::SecretEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
