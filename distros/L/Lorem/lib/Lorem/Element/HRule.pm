package Lorem::Element::HRule;
{
  $Lorem::Element::HRule::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Cairo;
use Pango;

extends 'Lorem::Element::Box';

sub imprint {
    my ( $self, $cr ) = @_;
    my $allocated = $self->size_allocation;
    
    die 'you must call size_allocate on this element before imprinting it'
        if ! $allocated;
    
    $cr->set_line_width( $allocated->{height} );
    $cr->move_to( $allocated->{x}, $allocated->{y} );
    $cr->line_to( $allocated->{x} + $allocated->{width}, $allocated->{y} );
    $cr->stroke;
}

sub size_request {
    my ( $self, $cr ) = @_;
    my $w  = defined $self->width  ? $self->width  : 100 ;
    my $h  = defined $self->height ? $self->height : 1 ;
    return { width => $w, height => $h };
}

sub size_allocate {
    my ( $self, $cr, $x, $y, $width, $height ) = @_;
    
    my %allocation = (width => $width, height => $height, x => $x, y => $y);
    $self->set_size_allocation( \%allocation );
}


1;
