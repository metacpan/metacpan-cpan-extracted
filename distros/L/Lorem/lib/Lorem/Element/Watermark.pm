package Lorem::Element::Watermark;
{
  $Lorem::Element::Watermark::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
extends 'Lorem::Element::Box';
with 'MooseX::Clone';


has 'content' => (
    is => 'rw',
    isa => 'Maybe[Lorem::Element]',
);

sub BUILD {
    my $self = shift;
    $_->set_parent( $self ) for $self->content;
}

sub size_allocate  {
    my ( $self, $cr, $x, $y, $width, $height ) = @_;
    
    my %allocation = (width => $width, height => $height, x => $x, y => $y);
    
    my $req = $self->content->size_request( $cr );
    
    $x = ( $width - $req->{width} ) / 2;
    
    $y = ( $height - $req->{height} ) / 2;
    
    
    $self->content->size_allocate( $cr, $x, $y, $width, $height);
    
    
    $self->set_size_allocation( \%allocation );
}


sub imprint {
    my ( $self, $cr ) = @_;
    
    $self->content->imprint( $cr );
}


1;
