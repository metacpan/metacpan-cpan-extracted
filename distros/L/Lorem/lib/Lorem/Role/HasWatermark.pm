package Lorem::Role::HasWatermark;
{
  $Lorem::Role::HasWatermark::VERSION = '0.22';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;


use MooseX::Types::Moose qw( Undef );
use Lorem::Types qw( LoremWatermark );

use Lorem::Element::Watermark;

has 'watermark' => (
    is => 'rw',
    isa => LoremWatermark | Undef,
    default => undef,
    coerce => 1,
);

sub _imprint_watermark {
    my ( $self, $cr ) = @_;
    return if ! $self->watermark;
    $self->watermark->size_request( $cr );
    $self->watermark->size_allocate( $cr, 0, 0, $self->parent->width, $self->parent->height );
    $self->watermark->imprint( $cr );
}

1;
