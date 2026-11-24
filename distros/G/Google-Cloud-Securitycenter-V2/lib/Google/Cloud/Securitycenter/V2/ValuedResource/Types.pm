package Google::Cloud::Securitycenter::V2::ValuedResource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ValuedResource',
    as InstanceOf['Google::Cloud::Securitycenter::V2::ValuedResource::ValuedResource'];

coerce 'ValuedResource',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::ValuedResource::ValuedResource'->new($_) };

declare 'RepeatedValuedResource',
    as ArrayRef[ValuedResource()];

coerce 'RepeatedValuedResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::ValuedResource::ValuedResource'->new($_) } @$_ ] };

declare 'MapStringValuedResource',
    as HashRef[ValuedResource()];

declare 'ResourceValue',
    as (Int | Str);

declare 'ResourceValueConfigMetadata',
    as InstanceOf['Google::Cloud::Securitycenter::V2::ValuedResource::ResourceValueConfigMetadata'];

coerce 'ResourceValueConfigMetadata',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::ValuedResource::ResourceValueConfigMetadata'->new($_) };

declare 'RepeatedResourceValueConfigMetadata',
    as ArrayRef[ResourceValueConfigMetadata()];

coerce 'RepeatedResourceValueConfigMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::ValuedResource::ResourceValueConfigMetadata'->new($_) } @$_ ] };

declare 'MapStringResourceValueConfigMetadata',
    as HashRef[ResourceValueConfigMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::ValuedResource::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
