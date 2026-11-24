package Google::Cloud::Documentai::V1beta3::Document::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Document',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document'];

coerce 'Document',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document'->new($_) };

declare 'RepeatedDocument',
    as ArrayRef[Document()];

coerce 'RepeatedDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document'->new($_) } @$_ ] };

declare 'MapStringDocument',
    as HashRef[Document()];

declare 'ShardInfo',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::ShardInfo'];

coerce 'ShardInfo',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::ShardInfo'->new($_) };

declare 'RepeatedShardInfo',
    as ArrayRef[ShardInfo()];

coerce 'RepeatedShardInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::ShardInfo'->new($_) } @$_ ] };

declare 'MapStringShardInfo',
    as HashRef[ShardInfo()];

declare 'Style',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Style'];

coerce 'Style',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Style'->new($_) };

declare 'RepeatedStyle',
    as ArrayRef[Style()];

coerce 'RepeatedStyle',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Style'->new($_) } @$_ ] };

declare 'MapStringStyle',
    as HashRef[Style()];

declare 'FontSize',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Style::FontSize'];

coerce 'FontSize',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Style::FontSize'->new($_) };

declare 'RepeatedFontSize',
    as ArrayRef[FontSize()];

coerce 'RepeatedFontSize',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Style::FontSize'->new($_) } @$_ ] };

declare 'MapStringFontSize',
    as HashRef[FontSize()];

declare 'Page',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page'];

coerce 'Page',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page'->new($_) };

declare 'RepeatedPage',
    as ArrayRef[Page()];

coerce 'RepeatedPage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page'->new($_) } @$_ ] };

declare 'MapStringPage',
    as HashRef[Page()];

declare 'Dimension',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Dimension'];

coerce 'Dimension',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Dimension'->new($_) };

declare 'RepeatedDimension',
    as ArrayRef[Dimension()];

coerce 'RepeatedDimension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Dimension'->new($_) } @$_ ] };

declare 'MapStringDimension',
    as HashRef[Dimension()];

declare 'Image',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Image'];

coerce 'Image',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Image'->new($_) };

declare 'RepeatedImage',
    as ArrayRef[Image()];

coerce 'RepeatedImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Image'->new($_) } @$_ ] };

declare 'MapStringImage',
    as HashRef[Image()];

declare 'Matrix',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Matrix'];

coerce 'Matrix',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Matrix'->new($_) };

declare 'RepeatedMatrix',
    as ArrayRef[Matrix()];

coerce 'RepeatedMatrix',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Matrix'->new($_) } @$_ ] };

declare 'MapStringMatrix',
    as HashRef[Matrix()];

declare 'Layout',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Layout'];

coerce 'Layout',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Layout'->new($_) };

declare 'RepeatedLayout',
    as ArrayRef[Layout()];

coerce 'RepeatedLayout',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Layout'->new($_) } @$_ ] };

declare 'MapStringLayout',
    as HashRef[Layout()];

declare 'Orientation',
    as (Int | Str);

declare 'Block',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Block'];

coerce 'Block',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Block'->new($_) };

declare 'RepeatedBlock',
    as ArrayRef[Block()];

coerce 'RepeatedBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Block'->new($_) } @$_ ] };

declare 'MapStringBlock',
    as HashRef[Block()];

declare 'Paragraph',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Paragraph'];

coerce 'Paragraph',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Paragraph'->new($_) };

declare 'RepeatedParagraph',
    as ArrayRef[Paragraph()];

coerce 'RepeatedParagraph',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Paragraph'->new($_) } @$_ ] };

declare 'MapStringParagraph',
    as HashRef[Paragraph()];

declare 'Line',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Line'];

coerce 'Line',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Line'->new($_) };

declare 'RepeatedLine',
    as ArrayRef[Line()];

coerce 'RepeatedLine',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Line'->new($_) } @$_ ] };

declare 'MapStringLine',
    as HashRef[Line()];

declare 'Token',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Token'];

coerce 'Token',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Token'->new($_) };

declare 'RepeatedToken',
    as ArrayRef[Token()];

coerce 'RepeatedToken',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Token'->new($_) } @$_ ] };

declare 'MapStringToken',
    as HashRef[Token()];

declare 'DetectedBreak',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Token::DetectedBreak'];

coerce 'DetectedBreak',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Token::DetectedBreak'->new($_) };

declare 'RepeatedDetectedBreak',
    as ArrayRef[DetectedBreak()];

coerce 'RepeatedDetectedBreak',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Token::DetectedBreak'->new($_) } @$_ ] };

declare 'MapStringDetectedBreak',
    as HashRef[DetectedBreak()];

declare 'Type',
    as (Int | Str);

declare 'StyleInfo',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Token::StyleInfo'];

coerce 'StyleInfo',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Token::StyleInfo'->new($_) };

declare 'RepeatedStyleInfo',
    as ArrayRef[StyleInfo()];

coerce 'RepeatedStyleInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Token::StyleInfo'->new($_) } @$_ ] };

declare 'MapStringStyleInfo',
    as HashRef[StyleInfo()];

declare 'Symbol',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Symbol'];

coerce 'Symbol',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Symbol'->new($_) };

declare 'RepeatedSymbol',
    as ArrayRef[Symbol()];

coerce 'RepeatedSymbol',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Symbol'->new($_) } @$_ ] };

declare 'MapStringSymbol',
    as HashRef[Symbol()];

declare 'VisualElement',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::VisualElement'];

coerce 'VisualElement',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::VisualElement'->new($_) };

declare 'RepeatedVisualElement',
    as ArrayRef[VisualElement()];

coerce 'RepeatedVisualElement',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::VisualElement'->new($_) } @$_ ] };

declare 'MapStringVisualElement',
    as HashRef[VisualElement()];

declare 'Table',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Table'];

coerce 'Table',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Table'->new($_) };

declare 'RepeatedTable',
    as ArrayRef[Table()];

coerce 'RepeatedTable',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Table'->new($_) } @$_ ] };

declare 'MapStringTable',
    as HashRef[Table()];

declare 'TableRow',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Table::TableRow'];

coerce 'TableRow',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Table::TableRow'->new($_) };

declare 'RepeatedTableRow',
    as ArrayRef[TableRow()];

coerce 'RepeatedTableRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Table::TableRow'->new($_) } @$_ ] };

declare 'MapStringTableRow',
    as HashRef[TableRow()];

declare 'TableCell',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::Table::TableCell'];

coerce 'TableCell',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Table::TableCell'->new($_) };

declare 'RepeatedTableCell',
    as ArrayRef[TableCell()];

coerce 'RepeatedTableCell',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::Table::TableCell'->new($_) } @$_ ] };

declare 'MapStringTableCell',
    as HashRef[TableCell()];

declare 'FormField',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::FormField'];

coerce 'FormField',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::FormField'->new($_) };

declare 'RepeatedFormField',
    as ArrayRef[FormField()];

coerce 'RepeatedFormField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::FormField'->new($_) } @$_ ] };

declare 'MapStringFormField',
    as HashRef[FormField()];

declare 'DetectedBarcode',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::DetectedBarcode'];

coerce 'DetectedBarcode',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::DetectedBarcode'->new($_) };

declare 'RepeatedDetectedBarcode',
    as ArrayRef[DetectedBarcode()];

coerce 'RepeatedDetectedBarcode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::DetectedBarcode'->new($_) } @$_ ] };

declare 'MapStringDetectedBarcode',
    as HashRef[DetectedBarcode()];

declare 'DetectedLanguage',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::DetectedLanguage'];

coerce 'DetectedLanguage',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::DetectedLanguage'->new($_) };

declare 'RepeatedDetectedLanguage',
    as ArrayRef[DetectedLanguage()];

coerce 'RepeatedDetectedLanguage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::DetectedLanguage'->new($_) } @$_ ] };

declare 'MapStringDetectedLanguage',
    as HashRef[DetectedLanguage()];

declare 'ImageQualityScores',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::ImageQualityScores'];

coerce 'ImageQualityScores',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::ImageQualityScores'->new($_) };

declare 'RepeatedImageQualityScores',
    as ArrayRef[ImageQualityScores()];

coerce 'RepeatedImageQualityScores',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::ImageQualityScores'->new($_) } @$_ ] };

declare 'MapStringImageQualityScores',
    as HashRef[ImageQualityScores()];

declare 'DetectedDefect',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Page::ImageQualityScores::DetectedDefect'];

coerce 'DetectedDefect',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::ImageQualityScores::DetectedDefect'->new($_) };

declare 'RepeatedDetectedDefect',
    as ArrayRef[DetectedDefect()];

coerce 'RepeatedDetectedDefect',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Page::ImageQualityScores::DetectedDefect'->new($_) } @$_ ] };

declare 'MapStringDetectedDefect',
    as HashRef[DetectedDefect()];

declare 'Entity',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Entity'];

coerce 'Entity',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Entity'->new($_) };

declare 'RepeatedEntity',
    as ArrayRef[Entity()];

coerce 'RepeatedEntity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Entity'->new($_) } @$_ ] };

declare 'MapStringEntity',
    as HashRef[Entity()];

declare 'Method',
    as (Int | Str);

declare 'NormalizedValue',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Entity::NormalizedValue'];

coerce 'NormalizedValue',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Entity::NormalizedValue'->new($_) };

declare 'RepeatedNormalizedValue',
    as ArrayRef[NormalizedValue()];

coerce 'RepeatedNormalizedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Entity::NormalizedValue'->new($_) } @$_ ] };

declare 'MapStringNormalizedValue',
    as HashRef[NormalizedValue()];

declare 'EntityRelation',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::EntityRelation'];

coerce 'EntityRelation',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::EntityRelation'->new($_) };

declare 'RepeatedEntityRelation',
    as ArrayRef[EntityRelation()];

coerce 'RepeatedEntityRelation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::EntityRelation'->new($_) } @$_ ] };

declare 'MapStringEntityRelation',
    as HashRef[EntityRelation()];

declare 'TextAnchor',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::TextAnchor'];

coerce 'TextAnchor',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::TextAnchor'->new($_) };

declare 'RepeatedTextAnchor',
    as ArrayRef[TextAnchor()];

coerce 'RepeatedTextAnchor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::TextAnchor'->new($_) } @$_ ] };

declare 'MapStringTextAnchor',
    as HashRef[TextAnchor()];

declare 'TextSegment',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::TextAnchor::TextSegment'];

coerce 'TextSegment',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::TextAnchor::TextSegment'->new($_) };

declare 'RepeatedTextSegment',
    as ArrayRef[TextSegment()];

coerce 'RepeatedTextSegment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::TextAnchor::TextSegment'->new($_) } @$_ ] };

declare 'MapStringTextSegment',
    as HashRef[TextSegment()];

declare 'PageAnchor',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::PageAnchor'];

coerce 'PageAnchor',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::PageAnchor'->new($_) };

declare 'RepeatedPageAnchor',
    as ArrayRef[PageAnchor()];

coerce 'RepeatedPageAnchor',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::PageAnchor'->new($_) } @$_ ] };

declare 'MapStringPageAnchor',
    as HashRef[PageAnchor()];

declare 'PageRef',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::PageAnchor::PageRef'];

coerce 'PageRef',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::PageAnchor::PageRef'->new($_) };

declare 'RepeatedPageRef',
    as ArrayRef[PageRef()];

coerce 'RepeatedPageRef',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::PageAnchor::PageRef'->new($_) } @$_ ] };

declare 'MapStringPageRef',
    as HashRef[PageRef()];

declare 'LayoutType',
    as (Int | Str);

declare 'Provenance',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Provenance'];

coerce 'Provenance',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Provenance'->new($_) };

declare 'RepeatedProvenance',
    as ArrayRef[Provenance()];

coerce 'RepeatedProvenance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Provenance'->new($_) } @$_ ] };

declare 'MapStringProvenance',
    as HashRef[Provenance()];

declare 'OperationType',
    as (Int | Str);

declare 'Parent',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Provenance::Parent'];

coerce 'Parent',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Provenance::Parent'->new($_) };

declare 'RepeatedParent',
    as ArrayRef[Parent()];

coerce 'RepeatedParent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Provenance::Parent'->new($_) } @$_ ] };

declare 'MapStringParent',
    as HashRef[Parent()];

declare 'Revision',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Revision'];

coerce 'Revision',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Revision'->new($_) };

declare 'RepeatedRevision',
    as ArrayRef[Revision()];

coerce 'RepeatedRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Revision'->new($_) } @$_ ] };

declare 'MapStringRevision',
    as HashRef[Revision()];

declare 'HumanReview',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Revision::HumanReview'];

coerce 'HumanReview',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Revision::HumanReview'->new($_) };

declare 'RepeatedHumanReview',
    as ArrayRef[HumanReview()];

coerce 'RepeatedHumanReview',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Revision::HumanReview'->new($_) } @$_ ] };

declare 'MapStringHumanReview',
    as HashRef[HumanReview()];

declare 'TextChange',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::TextChange'];

coerce 'TextChange',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::TextChange'->new($_) };

declare 'RepeatedTextChange',
    as ArrayRef[TextChange()];

coerce 'RepeatedTextChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::TextChange'->new($_) } @$_ ] };

declare 'MapStringTextChange',
    as HashRef[TextChange()];

declare 'Annotations',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::Annotations'];

coerce 'Annotations',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::Annotations'->new($_) };

declare 'RepeatedAnnotations',
    as ArrayRef[Annotations()];

coerce 'RepeatedAnnotations',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::Annotations'->new($_) } @$_ ] };

declare 'MapStringAnnotations',
    as HashRef[Annotations()];

declare 'DocumentLayout',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout'];

coerce 'DocumentLayout',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout'->new($_) };

declare 'RepeatedDocumentLayout',
    as ArrayRef[DocumentLayout()];

coerce 'RepeatedDocumentLayout',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout'->new($_) } @$_ ] };

declare 'MapStringDocumentLayout',
    as HashRef[DocumentLayout()];

declare 'DocumentLayoutBlock',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock'];

coerce 'DocumentLayoutBlock',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock'->new($_) };

declare 'RepeatedDocumentLayoutBlock',
    as ArrayRef[DocumentLayoutBlock()];

coerce 'RepeatedDocumentLayoutBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock'->new($_) } @$_ ] };

declare 'MapStringDocumentLayoutBlock',
    as HashRef[DocumentLayoutBlock()];

declare 'LayoutPageSpan',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutPageSpan'];

coerce 'LayoutPageSpan',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutPageSpan'->new($_) };

declare 'RepeatedLayoutPageSpan',
    as ArrayRef[LayoutPageSpan()];

coerce 'RepeatedLayoutPageSpan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutPageSpan'->new($_) } @$_ ] };

declare 'MapStringLayoutPageSpan',
    as HashRef[LayoutPageSpan()];

declare 'LayoutTextBlock',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutTextBlock'];

coerce 'LayoutTextBlock',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutTextBlock'->new($_) };

declare 'RepeatedLayoutTextBlock',
    as ArrayRef[LayoutTextBlock()];

coerce 'RepeatedLayoutTextBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutTextBlock'->new($_) } @$_ ] };

declare 'MapStringLayoutTextBlock',
    as HashRef[LayoutTextBlock()];

declare 'LayoutTableBlock',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutTableBlock'];

coerce 'LayoutTableBlock',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutTableBlock'->new($_) };

declare 'RepeatedLayoutTableBlock',
    as ArrayRef[LayoutTableBlock()];

coerce 'RepeatedLayoutTableBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutTableBlock'->new($_) } @$_ ] };

declare 'MapStringLayoutTableBlock',
    as HashRef[LayoutTableBlock()];

declare 'LayoutTableRow',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutTableRow'];

coerce 'LayoutTableRow',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutTableRow'->new($_) };

declare 'RepeatedLayoutTableRow',
    as ArrayRef[LayoutTableRow()];

coerce 'RepeatedLayoutTableRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutTableRow'->new($_) } @$_ ] };

declare 'MapStringLayoutTableRow',
    as HashRef[LayoutTableRow()];

declare 'LayoutTableCell',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutTableCell'];

coerce 'LayoutTableCell',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutTableCell'->new($_) };

declare 'RepeatedLayoutTableCell',
    as ArrayRef[LayoutTableCell()];

coerce 'RepeatedLayoutTableCell',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutTableCell'->new($_) } @$_ ] };

declare 'MapStringLayoutTableCell',
    as HashRef[LayoutTableCell()];

declare 'LayoutListBlock',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutListBlock'];

coerce 'LayoutListBlock',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutListBlock'->new($_) };

declare 'RepeatedLayoutListBlock',
    as ArrayRef[LayoutListBlock()];

coerce 'RepeatedLayoutListBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutListBlock'->new($_) } @$_ ] };

declare 'MapStringLayoutListBlock',
    as HashRef[LayoutListBlock()];

declare 'LayoutListEntry',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutListEntry'];

coerce 'LayoutListEntry',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutListEntry'->new($_) };

declare 'RepeatedLayoutListEntry',
    as ArrayRef[LayoutListEntry()];

coerce 'RepeatedLayoutListEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutListEntry'->new($_) } @$_ ] };

declare 'MapStringLayoutListEntry',
    as HashRef[LayoutListEntry()];

declare 'LayoutImageBlock',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutImageBlock'];

coerce 'LayoutImageBlock',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutImageBlock'->new($_) };

declare 'RepeatedLayoutImageBlock',
    as ArrayRef[LayoutImageBlock()];

coerce 'RepeatedLayoutImageBlock',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::DocumentLayout::DocumentLayoutBlock::LayoutImageBlock'->new($_) } @$_ ] };

declare 'MapStringLayoutImageBlock',
    as HashRef[LayoutImageBlock()];

declare 'ChunkedDocument',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument'];

coerce 'ChunkedDocument',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument'->new($_) };

declare 'RepeatedChunkedDocument',
    as ArrayRef[ChunkedDocument()];

coerce 'RepeatedChunkedDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument'->new($_) } @$_ ] };

declare 'MapStringChunkedDocument',
    as HashRef[ChunkedDocument()];

declare 'Chunk',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk'];

coerce 'Chunk',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk'->new($_) };

declare 'RepeatedChunk',
    as ArrayRef[Chunk()];

coerce 'RepeatedChunk',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk'->new($_) } @$_ ] };

declare 'MapStringChunk',
    as HashRef[Chunk()];

declare 'ChunkPageSpan',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ChunkPageSpan'];

coerce 'ChunkPageSpan',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ChunkPageSpan'->new($_) };

declare 'RepeatedChunkPageSpan',
    as ArrayRef[ChunkPageSpan()];

coerce 'RepeatedChunkPageSpan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ChunkPageSpan'->new($_) } @$_ ] };

declare 'MapStringChunkPageSpan',
    as HashRef[ChunkPageSpan()];

declare 'ChunkPageHeader',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ChunkPageHeader'];

coerce 'ChunkPageHeader',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ChunkPageHeader'->new($_) };

declare 'RepeatedChunkPageHeader',
    as ArrayRef[ChunkPageHeader()];

coerce 'RepeatedChunkPageHeader',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ChunkPageHeader'->new($_) } @$_ ] };

declare 'MapStringChunkPageHeader',
    as HashRef[ChunkPageHeader()];

declare 'ChunkPageFooter',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ChunkPageFooter'];

coerce 'ChunkPageFooter',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ChunkPageFooter'->new($_) };

declare 'RepeatedChunkPageFooter',
    as ArrayRef[ChunkPageFooter()];

coerce 'RepeatedChunkPageFooter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ChunkPageFooter'->new($_) } @$_ ] };

declare 'MapStringChunkPageFooter',
    as HashRef[ChunkPageFooter()];

declare 'ImageChunkField',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ImageChunkField'];

coerce 'ImageChunkField',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ImageChunkField'->new($_) };

declare 'RepeatedImageChunkField',
    as ArrayRef[ImageChunkField()];

coerce 'RepeatedImageChunkField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ImageChunkField'->new($_) } @$_ ] };

declare 'MapStringImageChunkField',
    as HashRef[ImageChunkField()];

declare 'TableChunkField',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::TableChunkField'];

coerce 'TableChunkField',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::TableChunkField'->new($_) };

declare 'RepeatedTableChunkField',
    as ArrayRef[TableChunkField()];

coerce 'RepeatedTableChunkField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::TableChunkField'->new($_) } @$_ ] };

declare 'MapStringTableChunkField',
    as HashRef[TableChunkField()];

declare 'ChunkField',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ChunkField'];

coerce 'ChunkField',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ChunkField'->new($_) };

declare 'RepeatedChunkField',
    as ArrayRef[ChunkField()];

coerce 'RepeatedChunkField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::ChunkedDocument::Chunk::ChunkField'->new($_) } @$_ ] };

declare 'MapStringChunkField',
    as HashRef[ChunkField()];

declare 'BlobAsset',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::BlobAsset'];

coerce 'BlobAsset',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::BlobAsset'->new($_) };

declare 'RepeatedBlobAsset',
    as ArrayRef[BlobAsset()];

coerce 'RepeatedBlobAsset',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::BlobAsset'->new($_) } @$_ ] };

declare 'MapStringBlobAsset',
    as HashRef[BlobAsset()];

declare 'EntityValidationOutput',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::EntityValidationOutput'];

coerce 'EntityValidationOutput',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::EntityValidationOutput'->new($_) };

declare 'RepeatedEntityValidationOutput',
    as ArrayRef[EntityValidationOutput()];

coerce 'RepeatedEntityValidationOutput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::EntityValidationOutput'->new($_) } @$_ ] };

declare 'MapStringEntityValidationOutput',
    as HashRef[EntityValidationOutput()];

declare 'ValidationResult',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::EntityValidationOutput::ValidationResult'];

coerce 'ValidationResult',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::EntityValidationOutput::ValidationResult'->new($_) };

declare 'RepeatedValidationResult',
    as ArrayRef[ValidationResult()];

coerce 'RepeatedValidationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::EntityValidationOutput::ValidationResult'->new($_) } @$_ ] };

declare 'MapStringValidationResult',
    as HashRef[ValidationResult()];

declare 'ValidationResultType',
    as (Int | Str);

declare 'EntitiesRevision',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::Document::EntitiesRevision'];

coerce 'EntitiesRevision',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::Document::EntitiesRevision'->new($_) };

declare 'RepeatedEntitiesRevision',
    as ArrayRef[EntitiesRevision()];

coerce 'RepeatedEntitiesRevision',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::Document::EntitiesRevision'->new($_) } @$_ ] };

declare 'MapStringEntitiesRevision',
    as HashRef[EntitiesRevision()];

declare 'RevisionRef',
    as InstanceOf['Google::Cloud::Documentai::V1beta3::Document::RevisionRef'];

coerce 'RevisionRef',
    from HashRef, via { 'Google::Cloud::Documentai::V1beta3::Document::RevisionRef'->new($_) };

declare 'RepeatedRevisionRef',
    as ArrayRef[RevisionRef()];

coerce 'RepeatedRevisionRef',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Documentai::V1beta3::Document::RevisionRef'->new($_) } @$_ ] };

declare 'MapStringRevisionRef',
    as HashRef[RevisionRef()];

declare 'RevisionCase',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Documentai::V1beta3::Document::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
