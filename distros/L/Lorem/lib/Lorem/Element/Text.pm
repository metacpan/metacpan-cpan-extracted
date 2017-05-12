package Lorem::Element::Text;
{
  $Lorem::Element::Text::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

with 'MooseX::Clone';

use Cairo;
use Pango;

extends 'Lorem::Element::Inline';

has '+parent' => (
    required => 0,
);

has 'content' => (
    is  => 'rw',
    isa => 'Str',
    default => '',
    trigger => sub {
        return if ! $_[0]->_has_layout;
        $_[0]->_layout->set_markup( $_[1] );
    }
);

has '_layout' => (
    is => 'rw',
    isa => 'Object',
    lazy_build => 1,
    reader => '_get_layout',
    writer => '_set_layout',
    predicate => '_has_layout',
);

sub _on_set_parent {
    my $self = shift;
}

sub _layout {
    my ( $self, $cr ) = @_;
    $self->_set_layout( $self->_build__layout( $cr ) ) if ! $self->_has_layout;
    return $self->_get_layout;
}

sub _build__layout {
    my ( $self, $cr ) = @_;
    my $layout = Pango::Cairo::create_layout( $cr );
    $self->_set_layout( $layout );
    
    # parse markup
    my ( $newatts, $text) = Pango->parse_markup( $self->content );
    $layout->set_text( $text );
    
    # apply style (with additional attributes from markup)
    $self->_apply_style_to_layout( $newatts ); # must happen before parsing markup
    
    return $layout;
}

sub imprint {
    my ( $self, $cr ) = @_;
    confess "must pass a context to 'imprint'" if ! $cr;
    
    my $allocated = $self->size_allocation;
    
    my $layout = $self->_layout( $cr );
    #$layout->set_width( $allocated->{width} * Pango->scale );
    $cr->move_to ( $allocated->{x}, $allocated->{y} );
    Pango::Cairo::show_layout( $cr, $layout );
}

sub size_request {
    my ( $self, $cr, $w ) = @_;
    
    my $layout = $self->_layout ( $cr );
    
    my $te = $layout->get_extents;
    # my $w  = defined $self->width  ? $self->width  : defined $self->parent->inner_width ? $self->parent->inner_width : $te->{width} / Pango->scale;
    
    if ( ! defined $w ) {
        if ( defined $self->width ) {
            $w = $self->width;
        }
        elsif ( defined $self->parent->inner_width ) {
            $w = $self->parent->inner_width;
        }
        else {
            $w = $te->{width} / Pango->scale
        }
    }
    
    #
    ## set the layout width now so we can figure out what the height is
    $layout->set_width( $w * Pango->scale );
    
    # now get the extents again to figure out the height
    $te = $layout->get_extents;
    my $h  = defined $self->height ? $self->height : $te->{height} / Pango->scale;
    
    return { width => $w, height => $h };
}

sub size_allocate {
    my ( $self, $cr, $x, $y, $width, $height ) = @_;
    
    #$width  = $self->parent->width  if $self->parent->width;
    #$height = $self->parent->height if $self->parent->height;
   
    # adjust for vertical alignment
    if ( $self->parent->size_allocation ) {
        my $pheight = $self->parent->size_allocation->{height};

        if ( $self->parent->merged_style->vertical_align && $self->parent->merged_style->vertical_align eq 'middle' && $pheight > $height ) {
            my $delta = $pheight - $height;
            $y += $delta / 2 ;
        }
        if ( $self->parent->merged_style->vertical_align && $self->parent->merged_style->vertical_align eq 'bottom' && $pheight > $height ) {
            my $delta = $pheight - $height;
            $y += $delta;
        }
    }
    
    my %allocation = (width => $width, height => $height, x => $x, y => $y);
    my $layout = $self->_layout( $cr );
    $layout->set_width( $width * Pango->scale );
    $self->set_size_allocation( \%allocation );
}

sub _apply_style_to_layout  {
    my ( $self, $additional_atts ) = @_;
    my $layout = $self->_get_layout;
    my $style  = $self->merged_style;
    
    my $attr_list = $style->attr_list;
    
    my $att_iter = $additional_atts->get_iterator;
    while ( defined $att_iter ) {
        my @attributes = $att_iter->get_attrs;
        $attr_list->insert( $_ ) for @attributes;
        
        my $val = $att_iter->next;
        last if ! $val;
    }
    
    $layout->set_attributes( $attr_list );
    $layout->set_alignment( $style->text_align ) if $style->text_align;
}
1;
