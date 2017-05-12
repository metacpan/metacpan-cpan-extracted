package Lorem::Style::Element::Border;
{
  $Lorem::Style::Element::Border::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Cairo;
use Pango;

with 'Lorem::Role::HasSizeAllocation';

use Lorem::Constants qw( %LoremStyleBorderWidth );
use Lorem::Types qw( LoremStyleBorderWidth LoremStyleBorderStyle LoremStyleColor );

use MooseX::Types::Moose qw( Int );

has 'parent' => (
    is => 'rw',
);

has 'width' => (
    is => 'rw',
    isa =>  LoremStyleBorderWidth,
);

has 'style' => (
    is => 'rw',
    isa => LoremStyleBorderStyle,
);

has 'color' => (
    is => 'rw',
    isa => LoremStyleColor,
);

sub imprint {
    my ( $self, $cr ) = @_;
    my $coords = $self->size_allocation;
   
    if ( $self->style ne 'none' ) {
        $cr->set_line_width( $self->_cairo_width );
        $cr->move_to( 0, 0 );
        $cr->move_to( $coords->{x1}, $coords->{y1} );
        $cr->line_to( $coords->{x2} , $coords->{y2} );
        $cr->stroke;
    }
}

sub size_allocate  {
    my ( $self, $cr, $x1, $y1, $x2, $y2 ) = @_;
    my %allocation = ( x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2 );
    $self->set_size_allocation( \%allocation );
}

sub _cairo_width {
    my ( $self ) = @_;
    
    $self->width;
    #return is_Int $self->width   ? $self->width : $LoremStyleBorderWidth{ $self->width };
    #return $LoremStyleBorderWidth{ $self->width };
}

1;
