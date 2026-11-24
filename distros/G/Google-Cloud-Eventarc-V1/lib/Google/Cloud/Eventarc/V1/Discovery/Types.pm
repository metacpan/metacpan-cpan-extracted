package Google::Cloud::Eventarc::V1::Discovery::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Provider',
    as InstanceOf['Google::Cloud::Eventarc::V1::Discovery::Provider'];

coerce 'Provider',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Discovery::Provider'->new($_) };

declare 'RepeatedProvider',
    as ArrayRef[Provider()];

coerce 'RepeatedProvider',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Discovery::Provider'->new($_) } @$_ ] };

declare 'MapStringProvider',
    as HashRef[Provider()];

declare 'EventType',
    as InstanceOf['Google::Cloud::Eventarc::V1::Discovery::EventType'];

coerce 'EventType',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Discovery::EventType'->new($_) };

declare 'RepeatedEventType',
    as ArrayRef[EventType()];

coerce 'RepeatedEventType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Discovery::EventType'->new($_) } @$_ ] };

declare 'MapStringEventType',
    as HashRef[EventType()];

declare 'FilteringAttribute',
    as InstanceOf['Google::Cloud::Eventarc::V1::Discovery::FilteringAttribute'];

coerce 'FilteringAttribute',
    from HashRef, via { 'Google::Cloud::Eventarc::V1::Discovery::FilteringAttribute'->new($_) };

declare 'RepeatedFilteringAttribute',
    as ArrayRef[FilteringAttribute()];

coerce 'RepeatedFilteringAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Eventarc::V1::Discovery::FilteringAttribute'->new($_) } @$_ ] };

declare 'MapStringFilteringAttribute',
    as HashRef[FilteringAttribute()];

1;

__END__

=head1 NAME

Google::Cloud::Eventarc::V1::Discovery::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
