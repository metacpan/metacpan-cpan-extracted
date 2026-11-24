package Google::Cloud::Resourcemanager::V3::TagValues::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TagValue',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagValues::TagValue'];

coerce 'TagValue',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagValues::TagValue'->new($_) };

declare 'RepeatedTagValue',
    as ArrayRef[TagValue()];

coerce 'RepeatedTagValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagValues::TagValue'->new($_) } @$_ ] };

declare 'MapStringTagValue',
    as HashRef[TagValue()];

declare 'ListTagValuesRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesRequest'];

coerce 'ListTagValuesRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesRequest'->new($_) };

declare 'RepeatedListTagValuesRequest',
    as ArrayRef[ListTagValuesRequest()];

coerce 'RepeatedListTagValuesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesRequest'->new($_) } @$_ ] };

declare 'MapStringListTagValuesRequest',
    as HashRef[ListTagValuesRequest()];

declare 'ListTagValuesResponse',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse'];

coerce 'ListTagValuesResponse',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse'->new($_) };

declare 'RepeatedListTagValuesResponse',
    as ArrayRef[ListTagValuesResponse()];

coerce 'RepeatedListTagValuesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse'->new($_) } @$_ ] };

declare 'MapStringListTagValuesResponse',
    as HashRef[ListTagValuesResponse()];

declare 'GetTagValueRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagValues::GetTagValueRequest'];

coerce 'GetTagValueRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagValues::GetTagValueRequest'->new($_) };

declare 'RepeatedGetTagValueRequest',
    as ArrayRef[GetTagValueRequest()];

coerce 'RepeatedGetTagValueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagValues::GetTagValueRequest'->new($_) } @$_ ] };

declare 'MapStringGetTagValueRequest',
    as HashRef[GetTagValueRequest()];

declare 'GetNamespacedTagValueRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagValues::GetNamespacedTagValueRequest'];

coerce 'GetNamespacedTagValueRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagValues::GetNamespacedTagValueRequest'->new($_) };

declare 'RepeatedGetNamespacedTagValueRequest',
    as ArrayRef[GetNamespacedTagValueRequest()];

coerce 'RepeatedGetNamespacedTagValueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagValues::GetNamespacedTagValueRequest'->new($_) } @$_ ] };

declare 'MapStringGetNamespacedTagValueRequest',
    as HashRef[GetNamespacedTagValueRequest()];

declare 'CreateTagValueRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueRequest'];

coerce 'CreateTagValueRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueRequest'->new($_) };

declare 'RepeatedCreateTagValueRequest',
    as ArrayRef[CreateTagValueRequest()];

coerce 'RepeatedCreateTagValueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTagValueRequest',
    as HashRef[CreateTagValueRequest()];

declare 'CreateTagValueMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueMetadata'];

coerce 'CreateTagValueMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueMetadata'->new($_) };

declare 'RepeatedCreateTagValueMetadata',
    as ArrayRef[CreateTagValueMetadata()];

coerce 'RepeatedCreateTagValueMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateTagValueMetadata',
    as HashRef[CreateTagValueMetadata()];

declare 'UpdateTagValueRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueRequest'];

coerce 'UpdateTagValueRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueRequest'->new($_) };

declare 'RepeatedUpdateTagValueRequest',
    as ArrayRef[UpdateTagValueRequest()];

coerce 'RepeatedUpdateTagValueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTagValueRequest',
    as HashRef[UpdateTagValueRequest()];

declare 'UpdateTagValueMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueMetadata'];

coerce 'UpdateTagValueMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueMetadata'->new($_) };

declare 'RepeatedUpdateTagValueMetadata',
    as ArrayRef[UpdateTagValueMetadata()];

coerce 'RepeatedUpdateTagValueMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateTagValueMetadata',
    as HashRef[UpdateTagValueMetadata()];

declare 'DeleteTagValueRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueRequest'];

coerce 'DeleteTagValueRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueRequest'->new($_) };

declare 'RepeatedDeleteTagValueRequest',
    as ArrayRef[DeleteTagValueRequest()];

coerce 'RepeatedDeleteTagValueRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTagValueRequest',
    as HashRef[DeleteTagValueRequest()];

declare 'DeleteTagValueMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueMetadata'];

coerce 'DeleteTagValueMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueMetadata'->new($_) };

declare 'RepeatedDeleteTagValueMetadata',
    as ArrayRef[DeleteTagValueMetadata()];

coerce 'RepeatedDeleteTagValueMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteTagValueMetadata',
    as HashRef[DeleteTagValueMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Resourcemanager::V3::TagValues::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
