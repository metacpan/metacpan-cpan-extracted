package Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CustomTuningModel',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::CustomTuningModel'];

coerce 'CustomTuningModel',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::CustomTuningModel'->new($_) };

declare 'RepeatedCustomTuningModel',
    as ArrayRef[CustomTuningModel()];

coerce 'RepeatedCustomTuningModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::CustomTuningModel'->new($_) } @$_ ] };

declare 'MapStringCustomTuningModel',
    as HashRef[CustomTuningModel()];

declare 'ModelState',
    as (Int | Str);

declare 'MetricsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::CustomTuningModel::MetricsEntry'];

coerce 'MetricsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::CustomTuningModel::MetricsEntry'->new($_) };

declare 'RepeatedMetricsEntry',
    as ArrayRef[MetricsEntry()];

coerce 'RepeatedMetricsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::CustomTuningModel::MetricsEntry'->new($_) } @$_ ] };

declare 'MapStringMetricsEntry',
    as HashRef[MetricsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::CustomTuningModel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
