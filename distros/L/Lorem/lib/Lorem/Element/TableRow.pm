package Lorem::Element::TableRow;
{
  $Lorem::Element::TableRow::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Cairo;
use Pango;

use Lorem::Types qw(  );
use Lorem::Element::TableCell;
extends 'Lorem::Element::Box';

with 'Lorem::Role::ConstructsElement' => {
    name  => 'cell',
    class => 'Lorem::Element::TableCell',
};

after apply_style => sub {
    my $self = shift;
    $self->set_width( $self->parent->width ) if $self->parent->width;
};


sub child_size_request {
    my ( $self, $cr ) = @_;
    
    my ( $w, $h ) = ( 0, 0 );
    
    for my $cell ( @{ $self->children } ) {
        my $size = $cell->size_request( $cr );
        $w += $cell->width ? $cell->width : $size->{width};
        $h = $size->{height} if $size->{height} > $h;
    }
    
    return { width => $w, height => $h };
}


sub child_size_allocate {
    my ( $self, $cr, $x, $y, $width, $height ) = @_;
    
    for my $cell ( @{ $self->children } ) {
        my $csize = $cell->size_request( $cr );
        $cell->size_allocate( $cr, $x, $y, $csize->{width}, $height );
        $x += $csize->{width};
    }
}

1;

