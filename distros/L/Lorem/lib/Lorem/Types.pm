package Lorem::Types;
{
  $Lorem::Types::VERSION = '0.22';
}

use MooseX::Types
    -declare => [ qw(
LoremAttrTextAlign
LoremElement
LoremText
LoremWatermark
LoremDoesStamp
MaybeLoremDoesStamp
LoremDocumentObject
LoremStyle
LoremStyleElementBorder
LoremStyleFontFamily
LoremStyleFontSize
LoremStyleFontStyle
LoremStyleFontWeight
LoremStyleFontVariant
LoremStyleBorderWidth
LoremStyleBorderStyle
LoremStyleColor
LoremStyleDimension
LoremStyleLength
LoremStyleRelativeLength
LoremStyleTextAlign
LoremStyleTextDecoration
LoremStyleTextUnderline
LoremStyleVerticalAlign
)];

use MooseX::Types::Moose qw( Int Num Str );

type LoremDoesStamp,
    where { $_ && $_->does('Lorem::Role::Stamp') };

type MaybeLoremDoesStamp,
    where { ! defined $_ || $_->does('Lorem::Role::Stamp') };

type LoremDocumentObject,
    where { $_ &&  $_->isa('Lorem::Element') || $_->isa('Lorem') };


# elements
class_type LoremElement,
    { class => 'Lorem::Element' };
    
class_type LoremText,
    { class => 'Lorem::Element::Text' };

coerce LoremText,
    from Str,
    via {  Lorem::Element::Text->new( content => $_ ) };
    
class_type LoremWatermark,
    { class => 'Lorem::Element::Watermark' };

coerce LoremWatermark,
    from LoremElement,
    via {  Lorem::Element::Watermark->new( content => $_ ) };
    
# element attributes
subtype LoremAttrTextAlign,
    as Str,
    where { $_ =~ /left|right|center/ };
 

# style values
class_type LoremStyle,
    { class => 'Lorem::Style' };

coerce LoremStyle,
    from Str,
    via { 'Lorem::Style'->new( $_ ) };

subtype LoremStyleBorderWidth,
    as Str,
    where { $_ =~ /\d+\.?\d*/ ||  $_ =~ /thin|medium|thick/ };

subtype LoremStyleBorderStyle,
    as Str,
    where { $_ =~ /none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset/ };
    
type LoremStyleDimension,
    where { is_LoremStyleLength($_) || is_LoremStyleRelativeLength($_) };
  
subtype LoremStyleColor,
    as Str;  

class_type LoremStyleElementBorder,
    { class => 'Lorem::Style::Element::Border' };   

subtype LoremStyleFontFamily,
    as Str;

subtype LoremStyleFontSize,
    as Num;
    
subtype LoremStyleFontWeight,
    as Str,
    where { $_ =~ /normal|bold|bolder|lighter/ };

subtype LoremStyleFontStyle,
    as Str,
    where  { $_ =~ /normal|italic|oblique|inherit/ };
    
type LoremStyleLength,
    where { is_Num($_) || is_Str($_) && $_ =~ /\d+%/ };

type LoremStyleRelativeLength,
    where { is_Str($_) && $_ =~ /\d+%/ };
    
subtype LoremStyleFontVariant,
    as Str,
    where  { $_ =~ /normal|small-caps|inherit/ };

subtype LoremStyleTextAlign,
    as Str,
    where { $_ =~ /left|right|center|inherit/ };

subtype LoremStyleTextDecoration,
    as Str,
    where { $_ =~ /overline|line-through|underline|blink/ };
    
subtype LoremStyleTextUnderline,
    as Str,
    where  { $_ =~ /normal|small-caps|inherit/ };
    
subtype LoremStyleVerticalAlign,
    as Str,
    where { $_ =~ /baseline|sub|super|top|text-top|middle|bottom|text-bottom|inherit/ };

    
1;
