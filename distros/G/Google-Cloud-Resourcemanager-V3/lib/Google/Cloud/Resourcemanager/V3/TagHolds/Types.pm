package Google::Cloud::Resourcemanager::V3::TagHolds::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TagHold',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagHolds::TagHold'];

coerce 'TagHold',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagHolds::TagHold'->new($_) };

declare 'RepeatedTagHold',
    as ArrayRef[TagHold()];

coerce 'RepeatedTagHold',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagHolds::TagHold'->new($_) } @$_ ] };

declare 'MapStringTagHold',
    as HashRef[TagHold()];

declare 'CreateTagHoldRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldRequest'];

coerce 'CreateTagHoldRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldRequest'->new($_) };

declare 'RepeatedCreateTagHoldRequest',
    as ArrayRef[CreateTagHoldRequest()];

coerce 'RepeatedCreateTagHoldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTagHoldRequest',
    as HashRef[CreateTagHoldRequest()];

declare 'CreateTagHoldMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldMetadata'];

coerce 'CreateTagHoldMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldMetadata'->new($_) };

declare 'RepeatedCreateTagHoldMetadata',
    as ArrayRef[CreateTagHoldMetadata()];

coerce 'RepeatedCreateTagHoldMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateTagHoldMetadata',
    as HashRef[CreateTagHoldMetadata()];

declare 'DeleteTagHoldRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagHolds::DeleteTagHoldRequest'];

coerce 'DeleteTagHoldRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagHolds::DeleteTagHoldRequest'->new($_) };

declare 'RepeatedDeleteTagHoldRequest',
    as ArrayRef[DeleteTagHoldRequest()];

coerce 'RepeatedDeleteTagHoldRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagHolds::DeleteTagHoldRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTagHoldRequest',
    as HashRef[DeleteTagHoldRequest()];

declare 'DeleteTagHoldMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagHolds::DeleteTagHoldMetadata'];

coerce 'DeleteTagHoldMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagHolds::DeleteTagHoldMetadata'->new($_) };

declare 'RepeatedDeleteTagHoldMetadata',
    as ArrayRef[DeleteTagHoldMetadata()];

coerce 'RepeatedDeleteTagHoldMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagHolds::DeleteTagHoldMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteTagHoldMetadata',
    as HashRef[DeleteTagHoldMetadata()];

declare 'ListTagHoldsRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsRequest'];

coerce 'ListTagHoldsRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsRequest'->new($_) };

declare 'RepeatedListTagHoldsRequest',
    as ArrayRef[ListTagHoldsRequest()];

coerce 'RepeatedListTagHoldsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsRequest'->new($_) } @$_ ] };

declare 'MapStringListTagHoldsRequest',
    as HashRef[ListTagHoldsRequest()];

declare 'ListTagHoldsResponse',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsResponse'];

coerce 'ListTagHoldsResponse',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsResponse'->new($_) };

declare 'RepeatedListTagHoldsResponse',
    as ArrayRef[ListTagHoldsResponse()];

coerce 'RepeatedListTagHoldsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsResponse'->new($_) } @$_ ] };

declare 'MapStringListTagHoldsResponse',
    as HashRef[ListTagHoldsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Resourcemanager::V3::TagHolds::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
