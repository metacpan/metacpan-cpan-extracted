package Lorem::Element::Page;
{
  $Lorem::Element::Page::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;


use Cairo;
use Pango;

use Lorem::Element::TableRow;


extends 'Lorem::Element::Box';
with 'Lorem::Role::HasHeaderFooter';
with 'Lorem::Role::HasWatermark';
with 'Lorem::Role::ConstructsElement' => { class => 'Lorem::Element::Div'  };
with 'Lorem::Role::ConstructsElement' => { class => 'Lorem::Element::Spacer'  };
with 'Lorem::Role::ConstructsElement' => { class => 'Lorem::Element::Text'  };
with 'Lorem::Role::ConstructsElement' => { class => 'Lorem::Element::Table' };
with 'Lorem::Role::ConstructsElement' => {
    name  => 'hr',
    class => 'Lorem::Element::HRule',
};



sub imprint {
    my ( $self, $cr ) = @_;
    
    die 'you did not supply a context, usage: $page->imprint( $cr )' if ! $cr;
    
    
    $self->size_request( $cr );
    $self->size_allocate( $cr, 0, 0, $self->parent->width, $self->parent->height );
    $self->_imprint_watermark( $cr );
    $self->_imprint_borders ( $cr );
    
    if ( $self->header ) {
        $self->header->size_allocate( $cr, 0, 0, $self->parent->width, $self->parent->height );
        $self->header->imprint( $cr ) if $self->header;
    }
    
    $_->imprint( $cr ) for ( @{ $self->children } );
    
}






1;
