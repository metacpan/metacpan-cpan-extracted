package Google::Cloud::Dialogflow::V2::Intent::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'IntentView',
    as (Int | Str);

declare 'Intent',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent'];

coerce 'Intent',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent'->new($_) };

declare 'RepeatedIntent',
    as ArrayRef[Intent()];

coerce 'RepeatedIntent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent'->new($_) } @$_ ] };

declare 'MapStringIntent',
    as HashRef[Intent()];

declare 'WebhookState',
    as (Int | Str);

declare 'TrainingPhrase',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::TrainingPhrase'];

coerce 'TrainingPhrase',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::TrainingPhrase'->new($_) };

declare 'RepeatedTrainingPhrase',
    as ArrayRef[TrainingPhrase()];

coerce 'RepeatedTrainingPhrase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::TrainingPhrase'->new($_) } @$_ ] };

declare 'MapStringTrainingPhrase',
    as HashRef[TrainingPhrase()];

declare 'Type',
    as (Int | Str);

declare 'Part',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::TrainingPhrase::Part'];

coerce 'Part',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::TrainingPhrase::Part'->new($_) };

declare 'RepeatedPart',
    as ArrayRef[Part()];

coerce 'RepeatedPart',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::TrainingPhrase::Part'->new($_) } @$_ ] };

declare 'MapStringPart',
    as HashRef[Part()];

declare 'Parameter',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Parameter'];

coerce 'Parameter',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Parameter'->new($_) };

declare 'RepeatedParameter',
    as ArrayRef[Parameter()];

coerce 'RepeatedParameter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Parameter'->new($_) } @$_ ] };

declare 'MapStringParameter',
    as HashRef[Parameter()];

declare 'Message',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message'];

coerce 'Message',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message'->new($_) };

declare 'RepeatedMessage',
    as ArrayRef[Message()];

coerce 'RepeatedMessage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message'->new($_) } @$_ ] };

declare 'MapStringMessage',
    as HashRef[Message()];

declare 'Platform',
    as (Int | Str);

declare 'Text',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Text'];

coerce 'Text',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Text'->new($_) };

declare 'RepeatedText',
    as ArrayRef[Text()];

coerce 'RepeatedText',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Text'->new($_) } @$_ ] };

declare 'MapStringText',
    as HashRef[Text()];

declare 'Image',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Image'];

coerce 'Image',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Image'->new($_) };

declare 'RepeatedImage',
    as ArrayRef[Image()];

coerce 'RepeatedImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Image'->new($_) } @$_ ] };

declare 'MapStringImage',
    as HashRef[Image()];

declare 'QuickReplies',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::QuickReplies'];

coerce 'QuickReplies',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::QuickReplies'->new($_) };

declare 'RepeatedQuickReplies',
    as ArrayRef[QuickReplies()];

coerce 'RepeatedQuickReplies',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::QuickReplies'->new($_) } @$_ ] };

declare 'MapStringQuickReplies',
    as HashRef[QuickReplies()];

declare 'Card',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Card'];

coerce 'Card',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Card'->new($_) };

declare 'RepeatedCard',
    as ArrayRef[Card()];

coerce 'RepeatedCard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Card'->new($_) } @$_ ] };

declare 'MapStringCard',
    as HashRef[Card()];

declare 'Button',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Card::Button'];

coerce 'Button',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Card::Button'->new($_) };

declare 'RepeatedButton',
    as ArrayRef[Button()];

coerce 'RepeatedButton',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Card::Button'->new($_) } @$_ ] };

declare 'MapStringButton',
    as HashRef[Button()];

declare 'SimpleResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::SimpleResponse'];

coerce 'SimpleResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::SimpleResponse'->new($_) };

declare 'RepeatedSimpleResponse',
    as ArrayRef[SimpleResponse()];

coerce 'RepeatedSimpleResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::SimpleResponse'->new($_) } @$_ ] };

declare 'MapStringSimpleResponse',
    as HashRef[SimpleResponse()];

declare 'SimpleResponses',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::SimpleResponses'];

coerce 'SimpleResponses',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::SimpleResponses'->new($_) };

declare 'RepeatedSimpleResponses',
    as ArrayRef[SimpleResponses()];

coerce 'RepeatedSimpleResponses',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::SimpleResponses'->new($_) } @$_ ] };

declare 'MapStringSimpleResponses',
    as HashRef[SimpleResponses()];

declare 'BasicCard',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BasicCard'];

coerce 'BasicCard',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BasicCard'->new($_) };

declare 'RepeatedBasicCard',
    as ArrayRef[BasicCard()];

coerce 'RepeatedBasicCard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BasicCard'->new($_) } @$_ ] };

declare 'MapStringBasicCard',
    as HashRef[BasicCard()];

declare 'Button',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BasicCard::Button'];

coerce 'Button',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BasicCard::Button'->new($_) };

declare 'RepeatedButton',
    as ArrayRef[Button()];

coerce 'RepeatedButton',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BasicCard::Button'->new($_) } @$_ ] };

declare 'MapStringButton',
    as HashRef[Button()];

declare 'OpenUriAction',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BasicCard::Button::OpenUriAction'];

coerce 'OpenUriAction',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BasicCard::Button::OpenUriAction'->new($_) };

declare 'RepeatedOpenUriAction',
    as ArrayRef[OpenUriAction()];

coerce 'RepeatedOpenUriAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BasicCard::Button::OpenUriAction'->new($_) } @$_ ] };

declare 'MapStringOpenUriAction',
    as HashRef[OpenUriAction()];

declare 'Suggestion',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Suggestion'];

coerce 'Suggestion',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Suggestion'->new($_) };

declare 'RepeatedSuggestion',
    as ArrayRef[Suggestion()];

coerce 'RepeatedSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Suggestion'->new($_) } @$_ ] };

declare 'MapStringSuggestion',
    as HashRef[Suggestion()];

declare 'Suggestions',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Suggestions'];

coerce 'Suggestions',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Suggestions'->new($_) };

declare 'RepeatedSuggestions',
    as ArrayRef[Suggestions()];

coerce 'RepeatedSuggestions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::Suggestions'->new($_) } @$_ ] };

declare 'MapStringSuggestions',
    as HashRef[Suggestions()];

declare 'LinkOutSuggestion',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::LinkOutSuggestion'];

coerce 'LinkOutSuggestion',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::LinkOutSuggestion'->new($_) };

declare 'RepeatedLinkOutSuggestion',
    as ArrayRef[LinkOutSuggestion()];

coerce 'RepeatedLinkOutSuggestion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::LinkOutSuggestion'->new($_) } @$_ ] };

declare 'MapStringLinkOutSuggestion',
    as HashRef[LinkOutSuggestion()];

declare 'ListSelect',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::ListSelect'];

coerce 'ListSelect',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::ListSelect'->new($_) };

declare 'RepeatedListSelect',
    as ArrayRef[ListSelect()];

coerce 'RepeatedListSelect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::ListSelect'->new($_) } @$_ ] };

declare 'MapStringListSelect',
    as HashRef[ListSelect()];

declare 'Item',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::ListSelect::Item'];

coerce 'Item',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::ListSelect::Item'->new($_) };

declare 'RepeatedItem',
    as ArrayRef[Item()];

coerce 'RepeatedItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::ListSelect::Item'->new($_) } @$_ ] };

declare 'MapStringItem',
    as HashRef[Item()];

declare 'CarouselSelect',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::CarouselSelect'];

coerce 'CarouselSelect',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::CarouselSelect'->new($_) };

declare 'RepeatedCarouselSelect',
    as ArrayRef[CarouselSelect()];

coerce 'RepeatedCarouselSelect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::CarouselSelect'->new($_) } @$_ ] };

declare 'MapStringCarouselSelect',
    as HashRef[CarouselSelect()];

declare 'Item',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::CarouselSelect::Item'];

coerce 'Item',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::CarouselSelect::Item'->new($_) };

declare 'RepeatedItem',
    as ArrayRef[Item()];

coerce 'RepeatedItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::CarouselSelect::Item'->new($_) } @$_ ] };

declare 'MapStringItem',
    as HashRef[Item()];

declare 'SelectItemInfo',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::SelectItemInfo'];

coerce 'SelectItemInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::SelectItemInfo'->new($_) };

declare 'RepeatedSelectItemInfo',
    as ArrayRef[SelectItemInfo()];

coerce 'RepeatedSelectItemInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::SelectItemInfo'->new($_) } @$_ ] };

declare 'MapStringSelectItemInfo',
    as HashRef[SelectItemInfo()];

declare 'MediaContent',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::MediaContent'];

coerce 'MediaContent',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::MediaContent'->new($_) };

declare 'RepeatedMediaContent',
    as ArrayRef[MediaContent()];

coerce 'RepeatedMediaContent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::MediaContent'->new($_) } @$_ ] };

declare 'MapStringMediaContent',
    as HashRef[MediaContent()];

declare 'ResponseMediaType',
    as (Int | Str);

declare 'ResponseMediaObject',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::MediaContent::ResponseMediaObject'];

coerce 'ResponseMediaObject',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::MediaContent::ResponseMediaObject'->new($_) };

declare 'RepeatedResponseMediaObject',
    as ArrayRef[ResponseMediaObject()];

coerce 'RepeatedResponseMediaObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::MediaContent::ResponseMediaObject'->new($_) } @$_ ] };

declare 'MapStringResponseMediaObject',
    as HashRef[ResponseMediaObject()];

declare 'BrowseCarouselCard',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BrowseCarouselCard'];

coerce 'BrowseCarouselCard',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BrowseCarouselCard'->new($_) };

declare 'RepeatedBrowseCarouselCard',
    as ArrayRef[BrowseCarouselCard()];

coerce 'RepeatedBrowseCarouselCard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BrowseCarouselCard'->new($_) } @$_ ] };

declare 'MapStringBrowseCarouselCard',
    as HashRef[BrowseCarouselCard()];

declare 'ImageDisplayOptions',
    as (Int | Str);

declare 'BrowseCarouselCardItem',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BrowseCarouselCard::BrowseCarouselCardItem'];

coerce 'BrowseCarouselCardItem',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BrowseCarouselCard::BrowseCarouselCardItem'->new($_) };

declare 'RepeatedBrowseCarouselCardItem',
    as ArrayRef[BrowseCarouselCardItem()];

coerce 'RepeatedBrowseCarouselCardItem',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BrowseCarouselCard::BrowseCarouselCardItem'->new($_) } @$_ ] };

declare 'MapStringBrowseCarouselCardItem',
    as HashRef[BrowseCarouselCardItem()];

declare 'OpenUrlAction',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BrowseCarouselCard::BrowseCarouselCardItem::OpenUrlAction'];

coerce 'OpenUrlAction',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BrowseCarouselCard::BrowseCarouselCardItem::OpenUrlAction'->new($_) };

declare 'RepeatedOpenUrlAction',
    as ArrayRef[OpenUrlAction()];

coerce 'RepeatedOpenUrlAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::BrowseCarouselCard::BrowseCarouselCardItem::OpenUrlAction'->new($_) } @$_ ] };

declare 'MapStringOpenUrlAction',
    as HashRef[OpenUrlAction()];

declare 'UrlTypeHint',
    as (Int | Str);

declare 'TableCard',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::TableCard'];

coerce 'TableCard',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::TableCard'->new($_) };

declare 'RepeatedTableCard',
    as ArrayRef[TableCard()];

coerce 'RepeatedTableCard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::TableCard'->new($_) } @$_ ] };

declare 'MapStringTableCard',
    as HashRef[TableCard()];

declare 'ColumnProperties',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::ColumnProperties'];

coerce 'ColumnProperties',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::ColumnProperties'->new($_) };

declare 'RepeatedColumnProperties',
    as ArrayRef[ColumnProperties()];

coerce 'RepeatedColumnProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::ColumnProperties'->new($_) } @$_ ] };

declare 'MapStringColumnProperties',
    as HashRef[ColumnProperties()];

declare 'HorizontalAlignment',
    as (Int | Str);

declare 'TableCardRow',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::TableCardRow'];

coerce 'TableCardRow',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::TableCardRow'->new($_) };

declare 'RepeatedTableCardRow',
    as ArrayRef[TableCardRow()];

coerce 'RepeatedTableCardRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::TableCardRow'->new($_) } @$_ ] };

declare 'MapStringTableCardRow',
    as HashRef[TableCardRow()];

declare 'TableCardCell',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::Message::TableCardCell'];

coerce 'TableCardCell',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::TableCardCell'->new($_) };

declare 'RepeatedTableCardCell',
    as ArrayRef[TableCardCell()];

coerce 'RepeatedTableCardCell',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::Message::TableCardCell'->new($_) } @$_ ] };

declare 'MapStringTableCardCell',
    as HashRef[TableCardCell()];

declare 'FollowupIntentInfo',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::Intent::FollowupIntentInfo'];

coerce 'FollowupIntentInfo',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::Intent::FollowupIntentInfo'->new($_) };

declare 'RepeatedFollowupIntentInfo',
    as ArrayRef[FollowupIntentInfo()];

coerce 'RepeatedFollowupIntentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::Intent::FollowupIntentInfo'->new($_) } @$_ ] };

declare 'MapStringFollowupIntentInfo',
    as HashRef[FollowupIntentInfo()];

declare 'ListIntentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::ListIntentsRequest'];

coerce 'ListIntentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::ListIntentsRequest'->new($_) };

declare 'RepeatedListIntentsRequest',
    as ArrayRef[ListIntentsRequest()];

coerce 'RepeatedListIntentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::ListIntentsRequest'->new($_) } @$_ ] };

declare 'MapStringListIntentsRequest',
    as HashRef[ListIntentsRequest()];

declare 'ListIntentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::ListIntentsResponse'];

coerce 'ListIntentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::ListIntentsResponse'->new($_) };

declare 'RepeatedListIntentsResponse',
    as ArrayRef[ListIntentsResponse()];

coerce 'RepeatedListIntentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::ListIntentsResponse'->new($_) } @$_ ] };

declare 'MapStringListIntentsResponse',
    as HashRef[ListIntentsResponse()];

declare 'GetIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::GetIntentRequest'];

coerce 'GetIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::GetIntentRequest'->new($_) };

declare 'RepeatedGetIntentRequest',
    as ArrayRef[GetIntentRequest()];

coerce 'RepeatedGetIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::GetIntentRequest'->new($_) } @$_ ] };

declare 'MapStringGetIntentRequest',
    as HashRef[GetIntentRequest()];

declare 'CreateIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::CreateIntentRequest'];

coerce 'CreateIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::CreateIntentRequest'->new($_) };

declare 'RepeatedCreateIntentRequest',
    as ArrayRef[CreateIntentRequest()];

coerce 'RepeatedCreateIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::CreateIntentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateIntentRequest',
    as HashRef[CreateIntentRequest()];

declare 'UpdateIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::UpdateIntentRequest'];

coerce 'UpdateIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::UpdateIntentRequest'->new($_) };

declare 'RepeatedUpdateIntentRequest',
    as ArrayRef[UpdateIntentRequest()];

coerce 'RepeatedUpdateIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::UpdateIntentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateIntentRequest',
    as HashRef[UpdateIntentRequest()];

declare 'DeleteIntentRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::DeleteIntentRequest'];

coerce 'DeleteIntentRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::DeleteIntentRequest'->new($_) };

declare 'RepeatedDeleteIntentRequest',
    as ArrayRef[DeleteIntentRequest()];

coerce 'RepeatedDeleteIntentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::DeleteIntentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteIntentRequest',
    as HashRef[DeleteIntentRequest()];

declare 'BatchUpdateIntentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::BatchUpdateIntentsRequest'];

coerce 'BatchUpdateIntentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::BatchUpdateIntentsRequest'->new($_) };

declare 'RepeatedBatchUpdateIntentsRequest',
    as ArrayRef[BatchUpdateIntentsRequest()];

coerce 'RepeatedBatchUpdateIntentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::BatchUpdateIntentsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateIntentsRequest',
    as HashRef[BatchUpdateIntentsRequest()];

declare 'BatchUpdateIntentsResponse',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::BatchUpdateIntentsResponse'];

coerce 'BatchUpdateIntentsResponse',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::BatchUpdateIntentsResponse'->new($_) };

declare 'RepeatedBatchUpdateIntentsResponse',
    as ArrayRef[BatchUpdateIntentsResponse()];

coerce 'RepeatedBatchUpdateIntentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::BatchUpdateIntentsResponse'->new($_) } @$_ ] };

declare 'MapStringBatchUpdateIntentsResponse',
    as HashRef[BatchUpdateIntentsResponse()];

declare 'BatchDeleteIntentsRequest',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::BatchDeleteIntentsRequest'];

coerce 'BatchDeleteIntentsRequest',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::BatchDeleteIntentsRequest'->new($_) };

declare 'RepeatedBatchDeleteIntentsRequest',
    as ArrayRef[BatchDeleteIntentsRequest()];

coerce 'RepeatedBatchDeleteIntentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::BatchDeleteIntentsRequest'->new($_) } @$_ ] };

declare 'MapStringBatchDeleteIntentsRequest',
    as HashRef[BatchDeleteIntentsRequest()];

declare 'IntentBatch',
    as InstanceOf['Google::Cloud::Dialogflow::V2::Intent::IntentBatch'];

coerce 'IntentBatch',
    from HashRef, via { 'Google::Cloud::Dialogflow::V2::Intent::IntentBatch'->new($_) };

declare 'RepeatedIntentBatch',
    as ArrayRef[IntentBatch()];

coerce 'RepeatedIntentBatch',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::V2::Intent::IntentBatch'->new($_) } @$_ ] };

declare 'MapStringIntentBatch',
    as HashRef[IntentBatch()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::V2::Intent::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
