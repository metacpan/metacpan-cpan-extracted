package Lorem::Role::HasDimensions;
{
  $Lorem::Role::HasDimensions::VERSION = '0.22';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

use Lorem::Util qw(percent_of);
use Lorem::Types qw(LoremStyleDimension LoremStyleLength LoremStyleRelativeLength);

has [qw(width height)] => (
    is => 'rw',
    isa => 'Maybe[Num]',
    default => undef,
);

has [qw(min_width min_height)] => (
    is => 'rw',
    isa => 'Maybe[Num]',
    default => undef,
);

has [qw(max_width max_height)] => (
    is => 'rw',
    isa => 'Maybe[Num]',
    default => undef,
);

sub _apply_dimension_style {
    my ( $self, $style ) = @_;
    
    my ( $w, $h );
    
    if ( defined $style->width ) {
        is_LoremStyleRelativeLength( $style->width ) ?
        $self->set_width( percent_of $style->width, $self->parent->inner_width ) :
        $self->set_width( $style->width );
    }

    if ( defined $style->height ) {
        is_LoremStyleRelativeLength( $style->height ) ?
        $self->set_height( percent_of $style->height, $self->parent->inner_height ) :
        $self->set_height( $style->height );
    }

    if ( defined $style->min_width ) {
        is_LoremStyleRelativeLength( $style->min_width ) ?
        $self->set_min_width( percent_of $style->min_width, $self->parent->inner_width ):
        $self->set_min_width( $style->min_width );
    }    
    if ( defined $style->min_height ) {
        is_LoremStyleRelativeLength( $style->min_height ) ?
        $self->set_min_height( percent_of $style->min_height, $self->parent->inner_height ):
        $self->set_min_height( $style->min_height );
    }

    if ( defined $style->max_width ) {
        is_LoremStyleRelativeLength( $style->max_width ) ?
        $self->set_max_width( percent_of $style->max_width, $self->parent->inner_width ):
        $self->set_max_width( $style->max_width );
    }    
    if ( defined $style->max_height ) {
        is_LoremStyleRelativeLength( $style->max_height ) ?
        $self->set_max_height( percent_of $style->max_height, $self->parent->inner_height ):
        $self->set_max_height( $style->max_height );
    }
}

1;
