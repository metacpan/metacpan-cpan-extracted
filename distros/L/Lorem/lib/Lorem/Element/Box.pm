package Lorem::Element::Box;
{
  $Lorem::Element::Box::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Lorem::Types qw( MaybeLoremDoesStamp );
extends 'Lorem::Element';

with 'Lorem::Role::ConstructsElement' => { class => 'Lorem::Element::Div' };
with 'Lorem::Role::ConstructsElement' => { class => 'Lorem::Element::Table' };
with 'Lorem::Role::ConstructsElement' => { class => 'Lorem::Element::Text' };

with 'Lorem::Role::HasCoordinates';
with 'Lorem::Role::HasDimensions';
with 'Lorem::Role::HasMargin';
with 'Lorem::Role::HasPadding';
with 'Lorem::Role::HasBorders';



sub imprint {
    my ( $self, $cr ) = @_;
    $_->imprint( $cr ) for ( @{ $self->children } );
    $_->_imprint_borders ( $cr );
}


sub size_request {
    my ( $self, $cr ) = @_;
    $self->apply_style( $self->merged_style );
    
    my $child_req = $self->child_size_request( $cr );
    
    my ( $w, $h ) = ( $child_req->{width}, $child_req->{height} );
    
    $w += $self->padding_left + $self->padding_right + $self->margin_left + $self->margin_right;
    $h += $self->padding_top + $self->padding_bottom + $self->margin_top + $self->margin_bottom;
    
    # set dimensions to user/style dimensions if they exist
    $h = defined $self->height && $self->height > $h ? $self->height : $h;
    $h = $self->min_height if defined $self->min_height && $self->min_height > $h;
    $h = $self->max_height if defined $self->max_height && $self->max_height < $h;
    
    $w = defined $self->width && $self->width > $w ? $self->width : $w;
    $w = $self->min_width if $self->min_width && $self->min_width > $w;
    $w = $self->max_width if $self->max_width && $self->max_width < $w;
    
    return { width => $w, height => $h };
}

sub child_size_request {
    my ( $self, $cr ) = @_;
    my ( $w, $h ) = ( 0, 0 );
    
    for my $child ( @{ $self->children }) {
        my $size = $child->size_request( $cr );
        $w = $size->{width}  if $size->{width} > $w;
        $h += $size->{height};
    }
    
    return { width => $w, height => $h };
}

sub size_allocate {
    my ( $self, $cr, $x, $y, $width, $height ) = @_;
    
    my %allocation = (width => $width, height => $height, x => $x, y => $y);
    $self->set_size_allocation( \%allocation );
    
    my $cx = $x + $self->padding_left + $self->margin_left;
    my $cy = $y + $self->padding_top + $self->margin_top;
    my $cwidth  = $width - $self->padding_left - $self->padding_right - $self->margin_left - $self->margin_right;
    my $cheight = $height - $self->padding_top - $self->padding_bottom - $self->margin_top - $self->margin_bottom;
    
    
    $self->_allocate_borders( $cr, $x, $y, $width, $height );
    $self->child_size_allocate( $cr, $cx, $cy, $cwidth, $cheight );
}

sub child_size_allocate {
    my ( $self, $cr, $x, $y, $width, $height ) = @_;
    
    for my $child ( @{ $self->children } ) {
        if ( $child->isa('Lorem::Element::Inline') ) {
            my $requistion = $child->size_request( $cr, $width );
            $child->size_allocate( $cr, $x, $y, $requistion->{width}, $requistion->{height} );
            $y += $requistion->{height};
        }
        else {
            my $requistion = $child->size_request( $cr );
            $child->size_allocate( $cr, $x, $y, $requistion->{width}, $requistion->{height} );
            $y += $requistion->{height};
        }
    }
}

sub apply_style {
    my ( $self, $style ) = @_;
    $self->_apply_margin_style( $style );
    $self->_apply_dimension_style( $style );
    $self->_apply_border_style( $style );
    $self->_apply_padding_style( $style );
}

sub inner_width {
    my ( $self ) = @_;
    
    defined $self->width ?
    $self->width - $self->padding_left - $self->padding_right - $self->margin_left - $self->margin_right
    : undef;
}

sub inner_height {
    my ( $self ) = @_;
    
    defined $self->height ?
    $self->height - $self->padding_top - $self->padding_bottom - $self->margin_top - $self->margin_bottom
    : undef;
}




1;
