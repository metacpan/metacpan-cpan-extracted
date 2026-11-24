package Google::Cloud::Servicehealth::Logging::V1::EventLog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EventLog',
    as InstanceOf['Google::Cloud::Servicehealth::Logging::V1::EventLog::EventLog'];

coerce 'EventLog',
    from HashRef, via { 'Google::Cloud::Servicehealth::Logging::V1::EventLog::EventLog'->new($_) };

declare 'RepeatedEventLog',
    as ArrayRef[EventLog()];

coerce 'RepeatedEventLog',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicehealth::Logging::V1::EventLog::EventLog'->new($_) } @$_ ] };

declare 'MapStringEventLog',
    as HashRef[EventLog()];

declare 'EventCategory',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'DetailedState',
    as (Int | Str);

declare 'Relevance',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Servicehealth::Logging::V1::EventLog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
