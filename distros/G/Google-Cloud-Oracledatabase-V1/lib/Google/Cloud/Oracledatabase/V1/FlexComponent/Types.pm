package Google::Cloud::Oracledatabase::V1::FlexComponent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FlexComponent',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponent'];

coerce 'FlexComponent',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponent'->new($_) };

declare 'RepeatedFlexComponent',
    as ArrayRef[FlexComponent()];

coerce 'RepeatedFlexComponent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponent'->new($_) } @$_ ] };

declare 'MapStringFlexComponent',
    as HashRef[FlexComponent()];

declare 'FlexComponentProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponentProperties'];

coerce 'FlexComponentProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponentProperties'->new($_) };

declare 'RepeatedFlexComponentProperties',
    as ArrayRef[FlexComponentProperties()];

coerce 'RepeatedFlexComponentProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::FlexComponent::FlexComponentProperties'->new($_) } @$_ ] };

declare 'MapStringFlexComponentProperties',
    as HashRef[FlexComponentProperties()];

declare 'HardwareType',
    as (Int | Str);

declare 'ListFlexComponentsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::FlexComponent::ListFlexComponentsRequest'];

coerce 'ListFlexComponentsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::FlexComponent::ListFlexComponentsRequest'->new($_) };

declare 'RepeatedListFlexComponentsRequest',
    as ArrayRef[ListFlexComponentsRequest()];

coerce 'RepeatedListFlexComponentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::FlexComponent::ListFlexComponentsRequest'->new($_) } @$_ ] };

declare 'MapStringListFlexComponentsRequest',
    as HashRef[ListFlexComponentsRequest()];

declare 'ListFlexComponentsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::FlexComponent::ListFlexComponentsResponse'];

coerce 'ListFlexComponentsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::FlexComponent::ListFlexComponentsResponse'->new($_) };

declare 'RepeatedListFlexComponentsResponse',
    as ArrayRef[ListFlexComponentsResponse()];

coerce 'RepeatedListFlexComponentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::FlexComponent::ListFlexComponentsResponse'->new($_) } @$_ ] };

declare 'MapStringListFlexComponentsResponse',
    as HashRef[ListFlexComponentsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::FlexComponent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
