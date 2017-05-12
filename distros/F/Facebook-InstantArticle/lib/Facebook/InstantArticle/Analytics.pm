package Facebook::InstantArticle::Analytics;
use Moose;
use namespace::autoclean;

extends 'Facebook::InstantArticle::BaseElement';

has 'source' => (
    isa => 'Str',
    is => 'rw',
    required => 0,
    default => '',
);

has 'content' => (
    isa => 'Str',
    is => 'rw',
    required => 0,
    default => '',
);

has 'is_valid' => (
    isa => 'Bool',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        return ( length $self->source || length $self->content ) ? 1 : 0;
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
        { class => 'op-tracker' },
        $gen->iframe(
            ( length $self->source ? { src => $self->source } : undef ),
            ( length $self->content ? \$self->content : undef ),
        ),
    );
}

1;
