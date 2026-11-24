package Google::Cloud::Resourcemanager::V3::TagBindings::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TagBinding',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagBindings::TagBinding'];

coerce 'TagBinding',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagBindings::TagBinding'->new($_) };

declare 'RepeatedTagBinding',
    as ArrayRef[TagBinding()];

coerce 'RepeatedTagBinding',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagBindings::TagBinding'->new($_) } @$_ ] };

declare 'MapStringTagBinding',
    as HashRef[TagBinding()];

declare 'CreateTagBindingMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingMetadata'];

coerce 'CreateTagBindingMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingMetadata'->new($_) };

declare 'RepeatedCreateTagBindingMetadata',
    as ArrayRef[CreateTagBindingMetadata()];

coerce 'RepeatedCreateTagBindingMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateTagBindingMetadata',
    as HashRef[CreateTagBindingMetadata()];

declare 'CreateTagBindingRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingRequest'];

coerce 'CreateTagBindingRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingRequest'->new($_) };

declare 'RepeatedCreateTagBindingRequest',
    as ArrayRef[CreateTagBindingRequest()];

coerce 'RepeatedCreateTagBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTagBindingRequest',
    as HashRef[CreateTagBindingRequest()];

declare 'DeleteTagBindingMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingMetadata'];

coerce 'DeleteTagBindingMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingMetadata'->new($_) };

declare 'RepeatedDeleteTagBindingMetadata',
    as ArrayRef[DeleteTagBindingMetadata()];

coerce 'RepeatedDeleteTagBindingMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteTagBindingMetadata',
    as HashRef[DeleteTagBindingMetadata()];

declare 'DeleteTagBindingRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingRequest'];

coerce 'DeleteTagBindingRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingRequest'->new($_) };

declare 'RepeatedDeleteTagBindingRequest',
    as ArrayRef[DeleteTagBindingRequest()];

coerce 'RepeatedDeleteTagBindingRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTagBindingRequest',
    as HashRef[DeleteTagBindingRequest()];

declare 'ListTagBindingsRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsRequest'];

coerce 'ListTagBindingsRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsRequest'->new($_) };

declare 'RepeatedListTagBindingsRequest',
    as ArrayRef[ListTagBindingsRequest()];

coerce 'RepeatedListTagBindingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsRequest'->new($_) } @$_ ] };

declare 'MapStringListTagBindingsRequest',
    as HashRef[ListTagBindingsRequest()];

declare 'ListTagBindingsResponse',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsResponse'];

coerce 'ListTagBindingsResponse',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsResponse'->new($_) };

declare 'RepeatedListTagBindingsResponse',
    as ArrayRef[ListTagBindingsResponse()];

coerce 'RepeatedListTagBindingsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsResponse'->new($_) } @$_ ] };

declare 'MapStringListTagBindingsResponse',
    as HashRef[ListTagBindingsResponse()];

declare 'ListEffectiveTagsRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsRequest'];

coerce 'ListEffectiveTagsRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsRequest'->new($_) };

declare 'RepeatedListEffectiveTagsRequest',
    as ArrayRef[ListEffectiveTagsRequest()];

coerce 'RepeatedListEffectiveTagsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsRequest'->new($_) } @$_ ] };

declare 'MapStringListEffectiveTagsRequest',
    as HashRef[ListEffectiveTagsRequest()];

declare 'ListEffectiveTagsResponse',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsResponse'];

coerce 'ListEffectiveTagsResponse',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsResponse'->new($_) };

declare 'RepeatedListEffectiveTagsResponse',
    as ArrayRef[ListEffectiveTagsResponse()];

coerce 'RepeatedListEffectiveTagsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsResponse'->new($_) } @$_ ] };

declare 'MapStringListEffectiveTagsResponse',
    as HashRef[ListEffectiveTagsResponse()];

declare 'EffectiveTag',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagBindings::EffectiveTag'];

coerce 'EffectiveTag',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagBindings::EffectiveTag'->new($_) };

declare 'RepeatedEffectiveTag',
    as ArrayRef[EffectiveTag()];

coerce 'RepeatedEffectiveTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagBindings::EffectiveTag'->new($_) } @$_ ] };

declare 'MapStringEffectiveTag',
    as HashRef[EffectiveTag()];

1;

__END__

=head1 NAME

Google::Cloud::Resourcemanager::V3::TagBindings::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
