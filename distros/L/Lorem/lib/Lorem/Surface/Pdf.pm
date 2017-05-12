package Lorem::Surface::Pdf;
{
  $Lorem::Surface::Pdf::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;
extends 'Lorem::Surface';

has 'width' => (
    is => 'rw',
    isa => 'Num',
    required => 1,
);

has 'height' => (
    is => 'rw',
    isa => 'Num',
    required => 1,
);

has 'file_name' => (
    is => 'rw',
    isa => 'Str',
);


sub print {
    my ( $self, $doc ) = @_;
    my $surface = Cairo::PdfSurface->create ( $self->file_name, $self->width, $self->height );
    $doc->set_width( $self->width );
    $doc->set_height( $self->height );
    my $cr = Cairo::Context->create( $surface );

    &{$doc->builder_func}( $doc, $cr ) if $doc->builder_func;
    
    my @pages = @{$doc->children};

    for ( @pages ) {
        $_->imprint( $cr );
        $cr->show_page;
    }
}


1;
