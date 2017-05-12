package Lorem::Element::Watermark;
{
  $Lorem::Element::Watermark::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Cairo;
use Pango;

use Lorem::Element::Text;
use Lorem::Types qw( LoremText );

extends 'Lorem::Element::Box';

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
    $self->content->size_allocate( $cr, $x, $y, $width, $height);
    $self->set_size_allocation( \%allocation );
}


sub imprint {
    my ( $self, $cr ) = @_;
    
    $self->content->imprint( $cr );
}


1;
