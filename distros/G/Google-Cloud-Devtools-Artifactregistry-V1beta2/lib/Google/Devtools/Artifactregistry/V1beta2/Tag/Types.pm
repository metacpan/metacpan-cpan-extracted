package Google::Devtools::Artifactregistry::V1beta2::Tag::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Tag',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Tag::Tag'];

coerce 'Tag',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Tag::Tag'->new($_) };

declare 'RepeatedTag',
    as ArrayRef[Tag()];

coerce 'RepeatedTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Tag::Tag'->new($_) } @$_ ] };

declare 'MapStringTag',
    as HashRef[Tag()];

declare 'ListTagsRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Tag::ListTagsRequest'];

coerce 'ListTagsRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Tag::ListTagsRequest'->new($_) };

declare 'RepeatedListTagsRequest',
    as ArrayRef[ListTagsRequest()];

coerce 'RepeatedListTagsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Tag::ListTagsRequest'->new($_) } @$_ ] };

declare 'MapStringListTagsRequest',
    as HashRef[ListTagsRequest()];

declare 'ListTagsResponse',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Tag::ListTagsResponse'];

coerce 'ListTagsResponse',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Tag::ListTagsResponse'->new($_) };

declare 'RepeatedListTagsResponse',
    as ArrayRef[ListTagsResponse()];

coerce 'RepeatedListTagsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Tag::ListTagsResponse'->new($_) } @$_ ] };

declare 'MapStringListTagsResponse',
    as HashRef[ListTagsResponse()];

declare 'GetTagRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Tag::GetTagRequest'];

coerce 'GetTagRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Tag::GetTagRequest'->new($_) };

declare 'RepeatedGetTagRequest',
    as ArrayRef[GetTagRequest()];

coerce 'RepeatedGetTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Tag::GetTagRequest'->new($_) } @$_ ] };

declare 'MapStringGetTagRequest',
    as HashRef[GetTagRequest()];

declare 'CreateTagRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Tag::CreateTagRequest'];

coerce 'CreateTagRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Tag::CreateTagRequest'->new($_) };

declare 'RepeatedCreateTagRequest',
    as ArrayRef[CreateTagRequest()];

coerce 'RepeatedCreateTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Tag::CreateTagRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTagRequest',
    as HashRef[CreateTagRequest()];

declare 'UpdateTagRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Tag::UpdateTagRequest'];

coerce 'UpdateTagRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Tag::UpdateTagRequest'->new($_) };

declare 'RepeatedUpdateTagRequest',
    as ArrayRef[UpdateTagRequest()];

coerce 'RepeatedUpdateTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Tag::UpdateTagRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTagRequest',
    as HashRef[UpdateTagRequest()];

declare 'DeleteTagRequest',
    as InstanceOf['Google::Devtools::Artifactregistry::V1beta2::Tag::DeleteTagRequest'];

coerce 'DeleteTagRequest',
    from HashRef, via { 'Google::Devtools::Artifactregistry::V1beta2::Tag::DeleteTagRequest'->new($_) };

declare 'RepeatedDeleteTagRequest',
    as ArrayRef[DeleteTagRequest()];

coerce 'RepeatedDeleteTagRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Devtools::Artifactregistry::V1beta2::Tag::DeleteTagRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTagRequest',
    as HashRef[DeleteTagRequest()];

1;

__END__

=head1 NAME

Google::Devtools::Artifactregistry::V1beta2::Tag::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
