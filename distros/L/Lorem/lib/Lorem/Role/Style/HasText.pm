package Lorem::Role::Style::HasText;
{
  $Lorem::Role::Style::HasText::VERSION = '0.22';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

use Lorem::Types qw(LoremStyleFontFamily LoremStyleFontStyle LoremStyleFontSize
LoremStyleFontWeight LoremStyleFontVariant LoremStyleTextAlign LoremStyleTextAlign
LoremStyleTextDecoration LoremStyleTextUnderline);

use Lorem::Util qw( color2rgb );


has 'font_family' => (
    is => 'rw',
    isa => LoremStyleFontFamily,
    traits  => [qw/Inherit/],
);

has 'font_style' => (
    is => 'rw',
    isa => LoremStyleFontStyle,
    traits  => [qw/Inherit/],
);

has 'font_size' => (
    is => 'rw',
    isa => LoremStyleFontSize,
    traits  => [qw/Inherit/],
);

has 'font_weight' => (
    is => 'rw',
    isa => LoremStyleFontWeight,
    traits  => [qw/Inherit/],
);

has 'font_variant' => (
    is => 'rw',
    isa => LoremStyleFontVariant,
    traits  => [qw/Inherit/],
);

has 'text_align' => (
    is => 'rw',
    isa => LoremStyleTextAlign,
    traits  => [qw/Inherit/],
);

has 'text_decoration' => (
    is => 'rw',
    isa => LoremStyleFontFamily,
    traits  => [qw/Inherit/],
);

has 'text_underline' => (
    is => 'rw',
    isa => LoremStyleTextUnderline,
    traits  => [qw/Inherit/],
);

sub attr_list {
    my ( $self ) = @_;
    my $list = Pango::AttrList->new;
    #$list->insert( Pango::Color->parse( $self->color ) );
    
    my $fd = Pango::FontDescription->new();
    $fd->set_size( $self->font_size * Pango->scale ) if $self->font_size;
    $fd->set_family( $self->font_family ) if $self->font_family;
    $fd->set_weight( $self->font_weight ) if $self->font_weight;
    $fd->set_variant( $self->font_variant ) if $self->font_variant;
    $fd->set_style( $self->font_style ) if $self->font_style;
    
    my $attr = Pango::AttrFontDesc->new( $fd );
    $list->insert( $attr );
    
    $attr = Pango::AttrUnderline->new( $self->text_underline ) if $self->text_underline;
    $list->insert( $attr );
    
    $attr = Pango::AttrForeground->new( color2rgb ( $self->color ) ) if $self->color;
    $list->insert( $attr );
    
    return $list;
}







1;
