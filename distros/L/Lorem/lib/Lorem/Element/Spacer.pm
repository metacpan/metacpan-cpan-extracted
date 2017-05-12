package Lorem::Element::Spacer;
{
  $Lorem::Element::Spacer::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

use Cairo;
use Pango;


extends 'Lorem::Element::Box';

sub imprint {
    my ( $self, $cr ) = @_;
    confess 'you must supply a contextt' if ! $cr;
    
    my $allocated = $self->size_allocation;
    confess 'you must call size_allocate on this element before imprinting it' if ! $allocated;
    
    for my $c ( @{$self->children} ) {
        $c->imprint( $cr );
    }
}

sub size_request  {
    my ( $self, $cr ) = @_;
    confess 'you must supply a contextt' if ! $cr;
    
    return { width => 1, height => $self->height };
}

sub size_allocate {
    my ( $self, $x, $y, $width, $height ) = @_;
    my %allocation = (width => $width, height => $height, x => $x, y => $y);
    $self->set_size_allocation( \%allocation );
}



1;
