package Google::Cloud::Notebooks::Logging::V1::RuntimeLog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RuntimeEvent',
    as InstanceOf['Google::Cloud::Notebooks::Logging::V1::RuntimeLog::RuntimeEvent'];

coerce 'RuntimeEvent',
    from HashRef, via { 'Google::Cloud::Notebooks::Logging::V1::RuntimeLog::RuntimeEvent'->new($_) };

declare 'RepeatedRuntimeEvent',
    as ArrayRef[RuntimeEvent()];

coerce 'RepeatedRuntimeEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::Logging::V1::RuntimeLog::RuntimeEvent'->new($_) } @$_ ] };

declare 'MapStringRuntimeEvent',
    as HashRef[RuntimeEvent()];

declare 'EventType',
    as (Int | Str);

declare 'DetailsEntry',
    as InstanceOf['Google::Cloud::Notebooks::Logging::V1::RuntimeLog::RuntimeEvent::DetailsEntry'];

coerce 'DetailsEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::Logging::V1::RuntimeLog::RuntimeEvent::DetailsEntry'->new($_) };

declare 'RepeatedDetailsEntry',
    as ArrayRef[DetailsEntry()];

coerce 'RepeatedDetailsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::Logging::V1::RuntimeLog::RuntimeEvent::DetailsEntry'->new($_) } @$_ ] };

declare 'MapStringDetailsEntry',
    as HashRef[DetailsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::Logging::V1::RuntimeLog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
