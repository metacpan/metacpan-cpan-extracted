package Google::Devicesandservices::Health::V4::MedicalDeviceInfo::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MedicalDeviceInfo',
    as InstanceOf['Google::Devicesandservices::Health::V4::MedicalDeviceInfo::MedicalDeviceInfo'];

coerce 'MedicalDeviceInfo',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::MedicalDeviceInfo::MedicalDeviceInfo'->new($_) };

declare 'RepeatedMedicalDeviceInfo',
    as ArrayRef[MedicalDeviceInfo()];

coerce 'RepeatedMedicalDeviceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::MedicalDeviceInfo::MedicalDeviceInfo'->new($_) } @$_ ] };

declare 'MapStringMedicalDeviceInfo',
    as HashRef[MedicalDeviceInfo()];

1;

__END__

=head1 NAME

Google::Devicesandservices::Health::V4::MedicalDeviceInfo::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
