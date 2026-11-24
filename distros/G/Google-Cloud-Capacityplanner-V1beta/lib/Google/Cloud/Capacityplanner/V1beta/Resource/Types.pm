package Google::Cloud::Capacityplanner::V1beta::Resource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Unit',
    as (Int | Str);

declare 'ResourceContainer',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Resource::ResourceContainer'];

coerce 'ResourceContainer',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Resource::ResourceContainer'->new($_) };

declare 'RepeatedResourceContainer',
    as ArrayRef[ResourceContainer()];

coerce 'RepeatedResourceContainer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Resource::ResourceContainer'->new($_) } @$_ ] };

declare 'MapStringResourceContainer',
    as HashRef[ResourceContainer()];

declare 'Type',
    as (Int | Str);

declare 'ResourceIdKey',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Resource::ResourceIdKey'];

coerce 'ResourceIdKey',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Resource::ResourceIdKey'->new($_) };

declare 'RepeatedResourceIdKey',
    as ArrayRef[ResourceIdKey()];

coerce 'RepeatedResourceIdKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Resource::ResourceIdKey'->new($_) } @$_ ] };

declare 'MapStringResourceIdKey',
    as HashRef[ResourceIdKey()];

declare 'ResourceIdentifier',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Resource::ResourceIdentifier'];

coerce 'ResourceIdentifier',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Resource::ResourceIdentifier'->new($_) };

declare 'RepeatedResourceIdentifier',
    as ArrayRef[ResourceIdentifier()];

coerce 'RepeatedResourceIdentifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Resource::ResourceIdentifier'->new($_) } @$_ ] };

declare 'MapStringResourceIdentifier',
    as HashRef[ResourceIdentifier()];

declare 'ResourceAttribute',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Resource::ResourceAttribute'];

coerce 'ResourceAttribute',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Resource::ResourceAttribute'->new($_) };

declare 'RepeatedResourceAttribute',
    as ArrayRef[ResourceAttribute()];

coerce 'RepeatedResourceAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Resource::ResourceAttribute'->new($_) } @$_ ] };

declare 'MapStringResourceAttribute',
    as HashRef[ResourceAttribute()];

declare 'ResourceValue',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Resource::ResourceValue'];

coerce 'ResourceValue',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Resource::ResourceValue'->new($_) };

declare 'RepeatedResourceValue',
    as ArrayRef[ResourceValue()];

coerce 'RepeatedResourceValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Resource::ResourceValue'->new($_) } @$_ ] };

declare 'MapStringResourceValue',
    as HashRef[ResourceValue()];

declare 'Value',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Resource::Value'];

coerce 'Value',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Resource::Value'->new($_) };

declare 'RepeatedValue',
    as ArrayRef[Value()];

coerce 'RepeatedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Resource::Value'->new($_) } @$_ ] };

declare 'MapStringValue',
    as HashRef[Value()];

1;

__END__

=head1 NAME

Google::Cloud::Capacityplanner::V1beta::Resource::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
