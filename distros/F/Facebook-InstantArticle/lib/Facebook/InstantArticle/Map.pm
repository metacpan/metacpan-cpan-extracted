package Facebook::InstantArticle::Map;
use Moose;
use namespace::autoclean;

extends 'Facebook::InstantArticle::BaseElement';

has 'type' => (
    isa => 'Str',
    is => 'rw',
    required => 0,
    default => 'Point',
);

has 'latitude' => (
    isa => 'Maybe[Num]',
    is => 'rw',
    required => 1,
    default => 0,
);

has 'longitude' => (
    isa => 'Maybe[Num]',
    is => 'rw',
    required => 1,
    default => 0,
);

has 'is_valid' => (
    isa => 'Bool',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        return ( defined $self->latitude && defined $self->longitude ) ? 1 : 0;
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
        { class => 'op-map' },
        $gen->script(
            { type => 'application/json', class => 'op-geotag' },
            '{
              "type": "Feature",
              "geometry":
                {
                  "type": "' . $self->type . '",
                  "coordinates": [' . $self->latitude . ', ' . $self->longitude . ']
                },
              "properties":
                {
                  "title": "",
                  "radius": 350000,
                  "pivot": true,
                  "style": "satellite",
                }
            }',
        ),
    );
}

1;
