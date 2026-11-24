package Google::Actions::Sdk::V2::Conversation::Media::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Media',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Media::Media'];

coerce 'Media',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Media::Media'->new($_) };

declare 'RepeatedMedia',
    as ArrayRef[Media()];

coerce 'RepeatedMedia',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Media::Media'->new($_) } @$_ ] };

declare 'MapStringMedia',
    as HashRef[Media()];

declare 'MediaType',
    as (Int | Str);

declare 'OptionalMediaControls',
    as (Int | Str);

declare 'MediaObject',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Media::MediaObject'];

coerce 'MediaObject',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Media::MediaObject'->new($_) };

declare 'RepeatedMediaObject',
    as ArrayRef[MediaObject()];

coerce 'RepeatedMediaObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Media::MediaObject'->new($_) } @$_ ] };

declare 'MapStringMediaObject',
    as HashRef[MediaObject()];

declare 'MediaImage',
    as InstanceOf['Google::Actions::Sdk::V2::Conversation::Media::MediaImage'];

coerce 'MediaImage',
    from HashRef, via { 'Google::Actions::Sdk::V2::Conversation::Media::MediaImage'->new($_) };

declare 'RepeatedMediaImage',
    as ArrayRef[MediaImage()];

coerce 'RepeatedMediaImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Actions::Sdk::V2::Conversation::Media::MediaImage'->new($_) } @$_ ] };

declare 'MapStringMediaImage',
    as HashRef[MediaImage()];

1;

__END__

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Media::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
