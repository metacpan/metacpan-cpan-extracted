package Google::Cloud::Discoveryengine::V1alpha::Session::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FileSource',
    as (Int | Str);

declare 'Session',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Session::Session'];

coerce 'Session',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Session::Session'->new($_) };

declare 'RepeatedSession',
    as ArrayRef[Session()];

coerce 'RepeatedSession',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Session::Session'->new($_) } @$_ ] };

declare 'MapStringSession',
    as HashRef[Session()];

declare 'State',
    as (Int | Str);

declare 'Turn',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Session::Session::Turn'];

coerce 'Turn',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Session::Session::Turn'->new($_) };

declare 'RepeatedTurn',
    as ArrayRef[Turn()];

coerce 'RepeatedTurn',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Session::Session::Turn'->new($_) } @$_ ] };

declare 'MapStringTurn',
    as HashRef[Turn()];

declare 'QueryConfigEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Session::Session::Turn::QueryConfigEntry'];

coerce 'QueryConfigEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Session::Session::Turn::QueryConfigEntry'->new($_) };

declare 'RepeatedQueryConfigEntry',
    as ArrayRef[QueryConfigEntry()];

coerce 'RepeatedQueryConfigEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Session::Session::Turn::QueryConfigEntry'->new($_) } @$_ ] };

declare 'MapStringQueryConfigEntry',
    as HashRef[QueryConfigEntry()];

declare 'Query',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Session::Query'];

coerce 'Query',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Session::Query'->new($_) };

declare 'RepeatedQuery',
    as ArrayRef[Query()];

coerce 'RepeatedQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Session::Query'->new($_) } @$_ ] };

declare 'MapStringQuery',
    as HashRef[Query()];

declare 'ImageCharacteristics',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Session::ImageCharacteristics'];

coerce 'ImageCharacteristics',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Session::ImageCharacteristics'->new($_) };

declare 'RepeatedImageCharacteristics',
    as ArrayRef[ImageCharacteristics()];

coerce 'RepeatedImageCharacteristics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Session::ImageCharacteristics'->new($_) } @$_ ] };

declare 'MapStringImageCharacteristics',
    as HashRef[ImageCharacteristics()];

declare 'ColorSpace',
    as (Int | Str);

declare 'VideoCharacteristics',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Session::VideoCharacteristics'];

coerce 'VideoCharacteristics',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Session::VideoCharacteristics'->new($_) };

declare 'RepeatedVideoCharacteristics',
    as ArrayRef[VideoCharacteristics()];

coerce 'RepeatedVideoCharacteristics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Session::VideoCharacteristics'->new($_) } @$_ ] };

declare 'MapStringVideoCharacteristics',
    as HashRef[VideoCharacteristics()];

declare 'FileCharacteristics',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Session::FileCharacteristics'];

coerce 'FileCharacteristics',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Session::FileCharacteristics'->new($_) };

declare 'RepeatedFileCharacteristics',
    as ArrayRef[FileCharacteristics()];

coerce 'RepeatedFileCharacteristics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Session::FileCharacteristics'->new($_) } @$_ ] };

declare 'MapStringFileCharacteristics',
    as HashRef[FileCharacteristics()];

declare 'CharacteristicsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Session::FileCharacteristics::CharacteristicsEntry'];

coerce 'CharacteristicsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Session::FileCharacteristics::CharacteristicsEntry'->new($_) };

declare 'RepeatedCharacteristicsEntry',
    as ArrayRef[CharacteristicsEntry()];

coerce 'RepeatedCharacteristicsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Session::FileCharacteristics::CharacteristicsEntry'->new($_) } @$_ ] };

declare 'MapStringCharacteristicsEntry',
    as HashRef[CharacteristicsEntry()];

declare 'FileView',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Session::FileView'];

coerce 'FileView',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Session::FileView'->new($_) };

declare 'RepeatedFileView',
    as ArrayRef[FileView()];

coerce 'RepeatedFileView',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Session::FileView'->new($_) } @$_ ] };

declare 'MapStringFileView',
    as HashRef[FileView()];

declare 'FileMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata'];

coerce 'FileMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata'->new($_) };

declare 'RepeatedFileMetadata',
    as ArrayRef[FileMetadata()];

coerce 'RepeatedFileMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata'->new($_) } @$_ ] };

declare 'MapStringFileMetadata',
    as HashRef[FileMetadata()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'ViewsEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata::ViewsEntry'];

coerce 'ViewsEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata::ViewsEntry'->new($_) };

declare 'RepeatedViewsEntry',
    as ArrayRef[ViewsEntry()];

coerce 'RepeatedViewsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::Session::FileMetadata::ViewsEntry'->new($_) } @$_ ] };

declare 'MapStringViewsEntry',
    as HashRef[ViewsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Session::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
