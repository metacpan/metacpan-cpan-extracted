package Facebook::InstantArticle::Author;
use Moose;
use namespace::autoclean;

extends 'Facebook::InstantArticle::BaseElement';

has 'name' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
    default => '',
);

has 'is_valid' => (
    isa => 'Bool',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        return length $self->name ? 1 : 0;
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

    return $gen->address(
        $gen->a( $self->name ),
    );
}

1;
