package Google::Cloud::Retail::V2beta::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AttributeConfigLevel',
    as (Int | Str);

declare 'SolutionType',
    as (Int | Str);

declare 'RecommendationsFilteringOption',
    as (Int | Str);

declare 'SearchSolutionUseCase',
    as (Int | Str);

declare 'Condition',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Condition'];

coerce 'Condition',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Condition'->new($_) };

declare 'RepeatedCondition',
    as ArrayRef[Condition()];

coerce 'RepeatedCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Condition'->new($_) } @$_ ] };

declare 'MapStringCondition',
    as HashRef[Condition()];

declare 'QueryTerm',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Condition::QueryTerm'];

coerce 'QueryTerm',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Condition::QueryTerm'->new($_) };

declare 'RepeatedQueryTerm',
    as ArrayRef[QueryTerm()];

coerce 'RepeatedQueryTerm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Condition::QueryTerm'->new($_) } @$_ ] };

declare 'MapStringQueryTerm',
    as HashRef[QueryTerm()];

declare 'TimeRange',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Condition::TimeRange'];

coerce 'TimeRange',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Condition::TimeRange'->new($_) };

declare 'RepeatedTimeRange',
    as ArrayRef[TimeRange()];

coerce 'RepeatedTimeRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Condition::TimeRange'->new($_) } @$_ ] };

declare 'MapStringTimeRange',
    as HashRef[TimeRange()];

declare 'Rule',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule'];

coerce 'Rule',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule'->new($_) };

declare 'RepeatedRule',
    as ArrayRef[Rule()];

coerce 'RepeatedRule',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule'->new($_) } @$_ ] };

declare 'MapStringRule',
    as HashRef[Rule()];

declare 'BoostAction',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule::BoostAction'];

coerce 'BoostAction',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule::BoostAction'->new($_) };

declare 'RepeatedBoostAction',
    as ArrayRef[BoostAction()];

coerce 'RepeatedBoostAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule::BoostAction'->new($_) } @$_ ] };

declare 'MapStringBoostAction',
    as HashRef[BoostAction()];

declare 'FilterAction',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule::FilterAction'];

coerce 'FilterAction',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule::FilterAction'->new($_) };

declare 'RepeatedFilterAction',
    as ArrayRef[FilterAction()];

coerce 'RepeatedFilterAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule::FilterAction'->new($_) } @$_ ] };

declare 'MapStringFilterAction',
    as HashRef[FilterAction()];

declare 'RedirectAction',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule::RedirectAction'];

coerce 'RedirectAction',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule::RedirectAction'->new($_) };

declare 'RepeatedRedirectAction',
    as ArrayRef[RedirectAction()];

coerce 'RepeatedRedirectAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule::RedirectAction'->new($_) } @$_ ] };

declare 'MapStringRedirectAction',
    as HashRef[RedirectAction()];

declare 'TwowaySynonymsAction',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule::TwowaySynonymsAction'];

coerce 'TwowaySynonymsAction',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule::TwowaySynonymsAction'->new($_) };

declare 'RepeatedTwowaySynonymsAction',
    as ArrayRef[TwowaySynonymsAction()];

coerce 'RepeatedTwowaySynonymsAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule::TwowaySynonymsAction'->new($_) } @$_ ] };

declare 'MapStringTwowaySynonymsAction',
    as HashRef[TwowaySynonymsAction()];

declare 'OnewaySynonymsAction',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule::OnewaySynonymsAction'];

coerce 'OnewaySynonymsAction',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule::OnewaySynonymsAction'->new($_) };

declare 'RepeatedOnewaySynonymsAction',
    as ArrayRef[OnewaySynonymsAction()];

coerce 'RepeatedOnewaySynonymsAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule::OnewaySynonymsAction'->new($_) } @$_ ] };

declare 'MapStringOnewaySynonymsAction',
    as HashRef[OnewaySynonymsAction()];

declare 'DoNotAssociateAction',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule::DoNotAssociateAction'];

coerce 'DoNotAssociateAction',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule::DoNotAssociateAction'->new($_) };

declare 'RepeatedDoNotAssociateAction',
    as ArrayRef[DoNotAssociateAction()];

coerce 'RepeatedDoNotAssociateAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule::DoNotAssociateAction'->new($_) } @$_ ] };

declare 'MapStringDoNotAssociateAction',
    as HashRef[DoNotAssociateAction()];

declare 'ReplacementAction',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule::ReplacementAction'];

coerce 'ReplacementAction',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule::ReplacementAction'->new($_) };

declare 'RepeatedReplacementAction',
    as ArrayRef[ReplacementAction()];

coerce 'RepeatedReplacementAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule::ReplacementAction'->new($_) } @$_ ] };

declare 'MapStringReplacementAction',
    as HashRef[ReplacementAction()];

declare 'IgnoreAction',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule::IgnoreAction'];

coerce 'IgnoreAction',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule::IgnoreAction'->new($_) };

declare 'RepeatedIgnoreAction',
    as ArrayRef[IgnoreAction()];

coerce 'RepeatedIgnoreAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule::IgnoreAction'->new($_) } @$_ ] };

declare 'MapStringIgnoreAction',
    as HashRef[IgnoreAction()];

declare 'ForceReturnFacetAction',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule::ForceReturnFacetAction'];

coerce 'ForceReturnFacetAction',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule::ForceReturnFacetAction'->new($_) };

declare 'RepeatedForceReturnFacetAction',
    as ArrayRef[ForceReturnFacetAction()];

coerce 'RepeatedForceReturnFacetAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule::ForceReturnFacetAction'->new($_) } @$_ ] };

declare 'MapStringForceReturnFacetAction',
    as HashRef[ForceReturnFacetAction()];

declare 'FacetPositionAdjustment',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule::ForceReturnFacetAction::FacetPositionAdjustment'];

coerce 'FacetPositionAdjustment',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule::ForceReturnFacetAction::FacetPositionAdjustment'->new($_) };

declare 'RepeatedFacetPositionAdjustment',
    as ArrayRef[FacetPositionAdjustment()];

coerce 'RepeatedFacetPositionAdjustment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule::ForceReturnFacetAction::FacetPositionAdjustment'->new($_) } @$_ ] };

declare 'MapStringFacetPositionAdjustment',
    as HashRef[FacetPositionAdjustment()];

declare 'RemoveFacetAction',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule::RemoveFacetAction'];

coerce 'RemoveFacetAction',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule::RemoveFacetAction'->new($_) };

declare 'RepeatedRemoveFacetAction',
    as ArrayRef[RemoveFacetAction()];

coerce 'RepeatedRemoveFacetAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule::RemoveFacetAction'->new($_) } @$_ ] };

declare 'MapStringRemoveFacetAction',
    as HashRef[RemoveFacetAction()];

declare 'PinAction',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule::PinAction'];

coerce 'PinAction',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule::PinAction'->new($_) };

declare 'RepeatedPinAction',
    as ArrayRef[PinAction()];

coerce 'RepeatedPinAction',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule::PinAction'->new($_) } @$_ ] };

declare 'MapStringPinAction',
    as HashRef[PinAction()];

declare 'PinMapEntry',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rule::PinAction::PinMapEntry'];

coerce 'PinMapEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rule::PinAction::PinMapEntry'->new($_) };

declare 'RepeatedPinMapEntry',
    as ArrayRef[PinMapEntry()];

coerce 'RepeatedPinMapEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rule::PinAction::PinMapEntry'->new($_) } @$_ ] };

declare 'MapStringPinMapEntry',
    as HashRef[PinMapEntry()];

declare 'Audience',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Audience'];

coerce 'Audience',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Audience'->new($_) };

declare 'RepeatedAudience',
    as ArrayRef[Audience()];

coerce 'RepeatedAudience',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Audience'->new($_) } @$_ ] };

declare 'MapStringAudience',
    as HashRef[Audience()];

declare 'ColorInfo',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::ColorInfo'];

coerce 'ColorInfo',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::ColorInfo'->new($_) };

declare 'RepeatedColorInfo',
    as ArrayRef[ColorInfo()];

coerce 'RepeatedColorInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::ColorInfo'->new($_) } @$_ ] };

declare 'MapStringColorInfo',
    as HashRef[ColorInfo()];

declare 'CustomAttribute',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::CustomAttribute'];

coerce 'CustomAttribute',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::CustomAttribute'->new($_) };

declare 'RepeatedCustomAttribute',
    as ArrayRef[CustomAttribute()];

coerce 'RepeatedCustomAttribute',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::CustomAttribute'->new($_) } @$_ ] };

declare 'MapStringCustomAttribute',
    as HashRef[CustomAttribute()];

declare 'FulfillmentInfo',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::FulfillmentInfo'];

coerce 'FulfillmentInfo',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::FulfillmentInfo'->new($_) };

declare 'RepeatedFulfillmentInfo',
    as ArrayRef[FulfillmentInfo()];

coerce 'RepeatedFulfillmentInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::FulfillmentInfo'->new($_) } @$_ ] };

declare 'MapStringFulfillmentInfo',
    as HashRef[FulfillmentInfo()];

declare 'Image',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Image'];

coerce 'Image',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Image'->new($_) };

declare 'RepeatedImage',
    as ArrayRef[Image()];

coerce 'RepeatedImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Image'->new($_) } @$_ ] };

declare 'MapStringImage',
    as HashRef[Image()];

declare 'Interval',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Interval'];

coerce 'Interval',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Interval'->new($_) };

declare 'RepeatedInterval',
    as ArrayRef[Interval()];

coerce 'RepeatedInterval',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Interval'->new($_) } @$_ ] };

declare 'MapStringInterval',
    as HashRef[Interval()];

declare 'PriceInfo',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::PriceInfo'];

coerce 'PriceInfo',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::PriceInfo'->new($_) };

declare 'RepeatedPriceInfo',
    as ArrayRef[PriceInfo()];

coerce 'RepeatedPriceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::PriceInfo'->new($_) } @$_ ] };

declare 'MapStringPriceInfo',
    as HashRef[PriceInfo()];

declare 'PriceRange',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::PriceInfo::PriceRange'];

coerce 'PriceRange',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::PriceInfo::PriceRange'->new($_) };

declare 'RepeatedPriceRange',
    as ArrayRef[PriceRange()];

coerce 'RepeatedPriceRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::PriceInfo::PriceRange'->new($_) } @$_ ] };

declare 'MapStringPriceRange',
    as HashRef[PriceRange()];

declare 'Rating',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::Rating'];

coerce 'Rating',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::Rating'->new($_) };

declare 'RepeatedRating',
    as ArrayRef[Rating()];

coerce 'RepeatedRating',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::Rating'->new($_) } @$_ ] };

declare 'MapStringRating',
    as HashRef[Rating()];

declare 'UserInfo',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::UserInfo'];

coerce 'UserInfo',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::UserInfo'->new($_) };

declare 'RepeatedUserInfo',
    as ArrayRef[UserInfo()];

coerce 'RepeatedUserInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::UserInfo'->new($_) } @$_ ] };

declare 'MapStringUserInfo',
    as HashRef[UserInfo()];

declare 'LocalInventory',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::LocalInventory'];

coerce 'LocalInventory',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::LocalInventory'->new($_) };

declare 'RepeatedLocalInventory',
    as ArrayRef[LocalInventory()];

coerce 'RepeatedLocalInventory',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::LocalInventory'->new($_) } @$_ ] };

declare 'MapStringLocalInventory',
    as HashRef[LocalInventory()];

declare 'AttributesEntry',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::LocalInventory::AttributesEntry'];

coerce 'AttributesEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::LocalInventory::AttributesEntry'->new($_) };

declare 'RepeatedAttributesEntry',
    as ArrayRef[AttributesEntry()];

coerce 'RepeatedAttributesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::LocalInventory::AttributesEntry'->new($_) } @$_ ] };

declare 'MapStringAttributesEntry',
    as HashRef[AttributesEntry()];

declare 'PinControlMetadata',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::PinControlMetadata'];

coerce 'PinControlMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::PinControlMetadata'->new($_) };

declare 'RepeatedPinControlMetadata',
    as ArrayRef[PinControlMetadata()];

coerce 'RepeatedPinControlMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::PinControlMetadata'->new($_) } @$_ ] };

declare 'MapStringPinControlMetadata',
    as HashRef[PinControlMetadata()];

declare 'ProductPins',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::PinControlMetadata::ProductPins'];

coerce 'ProductPins',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::PinControlMetadata::ProductPins'->new($_) };

declare 'RepeatedProductPins',
    as ArrayRef[ProductPins()];

coerce 'RepeatedProductPins',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::PinControlMetadata::ProductPins'->new($_) } @$_ ] };

declare 'MapStringProductPins',
    as HashRef[ProductPins()];

declare 'AllMatchedPinsEntry',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::PinControlMetadata::AllMatchedPinsEntry'];

coerce 'AllMatchedPinsEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::PinControlMetadata::AllMatchedPinsEntry'->new($_) };

declare 'RepeatedAllMatchedPinsEntry',
    as ArrayRef[AllMatchedPinsEntry()];

coerce 'RepeatedAllMatchedPinsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::PinControlMetadata::AllMatchedPinsEntry'->new($_) } @$_ ] };

declare 'MapStringAllMatchedPinsEntry',
    as HashRef[AllMatchedPinsEntry()];

declare 'DroppedPinsEntry',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::PinControlMetadata::DroppedPinsEntry'];

coerce 'DroppedPinsEntry',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::PinControlMetadata::DroppedPinsEntry'->new($_) };

declare 'RepeatedDroppedPinsEntry',
    as ArrayRef[DroppedPinsEntry()];

coerce 'RepeatedDroppedPinsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::PinControlMetadata::DroppedPinsEntry'->new($_) } @$_ ] };

declare 'MapStringDroppedPinsEntry',
    as HashRef[DroppedPinsEntry()];

declare 'StringList',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::StringList'];

coerce 'StringList',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::StringList'->new($_) };

declare 'RepeatedStringList',
    as ArrayRef[StringList()];

coerce 'RepeatedStringList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::StringList'->new($_) } @$_ ] };

declare 'MapStringStringList',
    as HashRef[StringList()];

declare 'DoubleList',
    as InstanceOf['Google::Cloud::Retail::V2beta::Common::DoubleList'];

coerce 'DoubleList',
    from HashRef, via { 'Google::Cloud::Retail::V2beta::Common::DoubleList'->new($_) };

declare 'RepeatedDoubleList',
    as ArrayRef[DoubleList()];

coerce 'RepeatedDoubleList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2beta::Common::DoubleList'->new($_) } @$_ ] };

declare 'MapStringDoubleList',
    as HashRef[DoubleList()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2beta::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
