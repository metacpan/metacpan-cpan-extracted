package Google::Devicesandservices::Health::V4::DataCoordinates::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CivilDateTime',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime'];

coerce 'CivilDateTime',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime'->new($_) };

declare 'RepeatedCivilDateTime',
    as ArrayRef[CivilDateTime()];

coerce 'RepeatedCivilDateTime',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataCoordinates::CivilDateTime'->new($_) } @$_ ] };

declare 'MapStringCivilDateTime',
    as HashRef[CivilDateTime()];

declare 'CivilTimeInterval',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataCoordinates::CivilTimeInterval'];

coerce 'CivilTimeInterval',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataCoordinates::CivilTimeInterval'->new($_) };

declare 'RepeatedCivilTimeInterval',
    as ArrayRef[CivilTimeInterval()];

coerce 'RepeatedCivilTimeInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataCoordinates::CivilTimeInterval'->new($_) } @$_ ] };

declare 'MapStringCivilTimeInterval',
    as HashRef[CivilTimeInterval()];

declare 'ObservationTimeInterval',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataCoordinates::ObservationTimeInterval'];

coerce 'ObservationTimeInterval',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataCoordinates::ObservationTimeInterval'->new($_) };

declare 'RepeatedObservationTimeInterval',
    as ArrayRef[ObservationTimeInterval()];

coerce 'RepeatedObservationTimeInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataCoordinates::ObservationTimeInterval'->new($_) } @$_ ] };

declare 'MapStringObservationTimeInterval',
    as HashRef[ObservationTimeInterval()];

declare 'SessionTimeInterval',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataCoordinates::SessionTimeInterval'];

coerce 'SessionTimeInterval',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataCoordinates::SessionTimeInterval'->new($_) };

declare 'RepeatedSessionTimeInterval',
    as ArrayRef[SessionTimeInterval()];

coerce 'RepeatedSessionTimeInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataCoordinates::SessionTimeInterval'->new($_) } @$_ ] };

declare 'MapStringSessionTimeInterval',
    as HashRef[SessionTimeInterval()];

declare 'ObservationSampleTime',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataCoordinates::ObservationSampleTime'];

coerce 'ObservationSampleTime',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataCoordinates::ObservationSampleTime'->new($_) };

declare 'RepeatedObservationSampleTime',
    as ArrayRef[ObservationSampleTime()];

coerce 'RepeatedObservationSampleTime',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataCoordinates::ObservationSampleTime'->new($_) } @$_ ] };

declare 'MapStringObservationSampleTime',
    as HashRef[ObservationSampleTime()];

1;

__END__

=head1 NAME

Google::Devicesandservices::Health::V4::DataCoordinates::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
