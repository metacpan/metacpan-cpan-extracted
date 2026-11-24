package Google::Devicesandservices::Health::V4::DataSource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataSource',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSource::DataSource'];

coerce 'DataSource',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSource::DataSource'->new($_) };

declare 'RepeatedDataSource',
    as ArrayRef[DataSource()];

coerce 'RepeatedDataSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSource::DataSource'->new($_) } @$_ ] };

declare 'MapStringDataSource',
    as HashRef[DataSource()];

declare 'RecordingMethod',
    as (Int | Str);

declare 'Platform',
    as (Int | Str);

declare 'Device',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSource::DataSource::Device'];

coerce 'Device',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSource::DataSource::Device'->new($_) };

declare 'RepeatedDevice',
    as ArrayRef[Device()];

coerce 'RepeatedDevice',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSource::DataSource::Device'->new($_) } @$_ ] };

declare 'MapStringDevice',
    as HashRef[Device()];

declare 'FormFactor',
    as (Int | Str);

declare 'Application',
    as InstanceOf['Google::Devicesandservices::Health::V4::DataSource::DataSource::Application'];

coerce 'Application',
    from HashRef, via { 'Google::Devicesandservices::Health::V4::DataSource::DataSource::Application'->new($_) };

declare 'RepeatedApplication',
    as ArrayRef[Application()];

coerce 'RepeatedApplication',
    from ArrayRef[HashRef], via { [ map { 'Google::Devicesandservices::Health::V4::DataSource::DataSource::Application'->new($_) } @$_ ] };

declare 'MapStringApplication',
    as HashRef[Application()];

1;

__END__

=head1 NAME

Google::Devicesandservices::Health::V4::DataSource::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
