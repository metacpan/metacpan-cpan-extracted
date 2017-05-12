package Facebook::InstantArticle::Slideshow;
use Moose;
use namespace::autoclean;

extends 'Facebook::InstantArticle::BaseElement';

use Facebook::InstantArticle::Figure::Image;

has '_images' => (
    isa => 'ArrayRef[Facebook::InstantArticle::Figure::Image]',
    is => 'ro',
    default => sub { [] },
);

sub add_image {
    my $self = shift;

    if ( my $e = Facebook::InstantArticle::Figure::Image->new(@_) ) {
        if ( $e->is_valid ) {
            return push( @{$self->_images}, $e );
        }
    }

    $self->_log->warn( 'Failed to add image to slideshow!' );
}

has 'is_valid' => (
    isa => 'Bool',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        return scalar( @{$self->_images} ) ? 1 : 0;
    },
);

has 'as_xml_gen' => (
    isa => 'Object',
    is => 'ro',
    lazy => 1,
    builder => '_build_as_xml_gen',
);

sub _build_as_xml_gen {
    my $self = shift;

    my $gen = XML::Generator->new( ':pretty' );

    return $gen->figure(
        { class => 'op-slideshow' },
        map { $_->as_xml_gen } @{ $self->_images },
    );
}

1;
