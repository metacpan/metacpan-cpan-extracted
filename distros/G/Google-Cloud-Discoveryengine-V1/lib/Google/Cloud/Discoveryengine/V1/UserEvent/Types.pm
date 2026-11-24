package Google::Cloud::Discoveryengine::V1::UserEvent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'UserEvent',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent'];

coerce 'UserEvent',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent'->new($_) };

declare 'RepeatedUserEvent',
    as ArrayRef[UserEvent()];

coerce 'RepeatedUserEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent'->new($_) } @$_ ] };

declare 'MapStringUserEvent',
    as HashRef[UserEvent()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::UserEvent::UserEvent::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'PageInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::UserEvent::PageInfo'];

coerce 'PageInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::UserEvent::PageInfo'->new($_) };

declare 'RepeatedPageInfo',
    as ArrayRef[PageInfo()];

coerce 'RepeatedPageInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::UserEvent::PageInfo'->new($_) } @$_ ] };

declare 'MapStringPageInfo',
    as HashRef[PageInfo()];

declare 'SearchInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::UserEvent::SearchInfo'];

coerce 'SearchInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::UserEvent::SearchInfo'->new($_) };

declare 'RepeatedSearchInfo',
    as ArrayRef[SearchInfo()];

coerce 'RepeatedSearchInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::UserEvent::SearchInfo'->new($_) } @$_ ] };

declare 'MapStringSearchInfo',
    as HashRef[SearchInfo()];

declare 'CompletionInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::UserEvent::CompletionInfo'];

coerce 'CompletionInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::UserEvent::CompletionInfo'->new($_) };

declare 'RepeatedCompletionInfo',
    as ArrayRef[CompletionInfo()];

coerce 'RepeatedCompletionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::UserEvent::CompletionInfo'->new($_) } @$_ ] };

declare 'MapStringCompletionInfo',
    as HashRef[CompletionInfo()];

declare 'TransactionInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::UserEvent::TransactionInfo'];

coerce 'TransactionInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::UserEvent::TransactionInfo'->new($_) };

declare 'RepeatedTransactionInfo',
    as ArrayRef[TransactionInfo()];

coerce 'RepeatedTransactionInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::UserEvent::TransactionInfo'->new($_) } @$_ ] };

declare 'MapStringTransactionInfo',
    as HashRef[TransactionInfo()];

declare 'DocumentInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::UserEvent::DocumentInfo'];

coerce 'DocumentInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::UserEvent::DocumentInfo'->new($_) };

declare 'RepeatedDocumentInfo',
    as ArrayRef[DocumentInfo()];

coerce 'RepeatedDocumentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::UserEvent::DocumentInfo'->new($_) } @$_ ] };

declare 'MapStringDocumentInfo',
    as HashRef[DocumentInfo()];

declare 'PanelInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::UserEvent::PanelInfo'];

coerce 'PanelInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::UserEvent::PanelInfo'->new($_) };

declare 'RepeatedPanelInfo',
    as ArrayRef[PanelInfo()];

coerce 'RepeatedPanelInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::UserEvent::PanelInfo'->new($_) } @$_ ] };

declare 'MapStringPanelInfo',
    as HashRef[PanelInfo()];

declare 'MediaInfo',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::UserEvent::MediaInfo'];

coerce 'MediaInfo',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::UserEvent::MediaInfo'->new($_) };

declare 'RepeatedMediaInfo',
    as ArrayRef[MediaInfo()];

coerce 'RepeatedMediaInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::UserEvent::MediaInfo'->new($_) } @$_ ] };

declare 'MapStringMediaInfo',
    as HashRef[MediaInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::UserEvent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
