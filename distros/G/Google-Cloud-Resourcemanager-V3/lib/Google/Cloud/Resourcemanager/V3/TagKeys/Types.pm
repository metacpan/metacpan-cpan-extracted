package Google::Cloud::Resourcemanager::V3::TagKeys::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Purpose',
    as (Int | Str);

declare 'TagKey',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagKeys::TagKey'];

coerce 'TagKey',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagKeys::TagKey'->new($_) };

declare 'RepeatedTagKey',
    as ArrayRef[TagKey()];

coerce 'RepeatedTagKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagKeys::TagKey'->new($_) } @$_ ] };

declare 'MapStringTagKey',
    as HashRef[TagKey()];

declare 'PurposeDataEntry',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagKeys::TagKey::PurposeDataEntry'];

coerce 'PurposeDataEntry',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagKeys::TagKey::PurposeDataEntry'->new($_) };

declare 'RepeatedPurposeDataEntry',
    as ArrayRef[PurposeDataEntry()];

coerce 'RepeatedPurposeDataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagKeys::TagKey::PurposeDataEntry'->new($_) } @$_ ] };

declare 'MapStringPurposeDataEntry',
    as HashRef[PurposeDataEntry()];

declare 'ListTagKeysRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysRequest'];

coerce 'ListTagKeysRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysRequest'->new($_) };

declare 'RepeatedListTagKeysRequest',
    as ArrayRef[ListTagKeysRequest()];

coerce 'RepeatedListTagKeysRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysRequest'->new($_) } @$_ ] };

declare 'MapStringListTagKeysRequest',
    as HashRef[ListTagKeysRequest()];

declare 'ListTagKeysResponse',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysResponse'];

coerce 'ListTagKeysResponse',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysResponse'->new($_) };

declare 'RepeatedListTagKeysResponse',
    as ArrayRef[ListTagKeysResponse()];

coerce 'RepeatedListTagKeysResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysResponse'->new($_) } @$_ ] };

declare 'MapStringListTagKeysResponse',
    as HashRef[ListTagKeysResponse()];

declare 'GetTagKeyRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagKeys::GetTagKeyRequest'];

coerce 'GetTagKeyRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagKeys::GetTagKeyRequest'->new($_) };

declare 'RepeatedGetTagKeyRequest',
    as ArrayRef[GetTagKeyRequest()];

coerce 'RepeatedGetTagKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagKeys::GetTagKeyRequest'->new($_) } @$_ ] };

declare 'MapStringGetTagKeyRequest',
    as HashRef[GetTagKeyRequest()];

declare 'GetNamespacedTagKeyRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagKeys::GetNamespacedTagKeyRequest'];

coerce 'GetNamespacedTagKeyRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagKeys::GetNamespacedTagKeyRequest'->new($_) };

declare 'RepeatedGetNamespacedTagKeyRequest',
    as ArrayRef[GetNamespacedTagKeyRequest()];

coerce 'RepeatedGetNamespacedTagKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagKeys::GetNamespacedTagKeyRequest'->new($_) } @$_ ] };

declare 'MapStringGetNamespacedTagKeyRequest',
    as HashRef[GetNamespacedTagKeyRequest()];

declare 'CreateTagKeyRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyRequest'];

coerce 'CreateTagKeyRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyRequest'->new($_) };

declare 'RepeatedCreateTagKeyRequest',
    as ArrayRef[CreateTagKeyRequest()];

coerce 'RepeatedCreateTagKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTagKeyRequest',
    as HashRef[CreateTagKeyRequest()];

declare 'CreateTagKeyMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyMetadata'];

coerce 'CreateTagKeyMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyMetadata'->new($_) };

declare 'RepeatedCreateTagKeyMetadata',
    as ArrayRef[CreateTagKeyMetadata()];

coerce 'RepeatedCreateTagKeyMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateTagKeyMetadata',
    as HashRef[CreateTagKeyMetadata()];

declare 'UpdateTagKeyRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyRequest'];

coerce 'UpdateTagKeyRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyRequest'->new($_) };

declare 'RepeatedUpdateTagKeyRequest',
    as ArrayRef[UpdateTagKeyRequest()];

coerce 'RepeatedUpdateTagKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTagKeyRequest',
    as HashRef[UpdateTagKeyRequest()];

declare 'UpdateTagKeyMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyMetadata'];

coerce 'UpdateTagKeyMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyMetadata'->new($_) };

declare 'RepeatedUpdateTagKeyMetadata',
    as ArrayRef[UpdateTagKeyMetadata()];

coerce 'RepeatedUpdateTagKeyMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyMetadata'->new($_) } @$_ ] };

declare 'MapStringUpdateTagKeyMetadata',
    as HashRef[UpdateTagKeyMetadata()];

declare 'DeleteTagKeyRequest',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyRequest'];

coerce 'DeleteTagKeyRequest',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyRequest'->new($_) };

declare 'RepeatedDeleteTagKeyRequest',
    as ArrayRef[DeleteTagKeyRequest()];

coerce 'RepeatedDeleteTagKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTagKeyRequest',
    as HashRef[DeleteTagKeyRequest()];

declare 'DeleteTagKeyMetadata',
    as InstanceOf['Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyMetadata'];

coerce 'DeleteTagKeyMetadata',
    from HashRef, via { 'Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyMetadata'->new($_) };

declare 'RepeatedDeleteTagKeyMetadata',
    as ArrayRef[DeleteTagKeyMetadata()];

coerce 'RepeatedDeleteTagKeyMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteTagKeyMetadata',
    as HashRef[DeleteTagKeyMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Resourcemanager::V3::TagKeys::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
