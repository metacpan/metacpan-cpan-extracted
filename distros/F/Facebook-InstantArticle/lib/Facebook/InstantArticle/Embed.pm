package Facebook::InstantArticle::Embed;
use Moose;
use namespace::autoclean;

extends 'Facebook::InstantArticle::BaseElement';

has 'content' => (
    isa => 'Str',
    is => 'rw',
    required => 0,
    default => '',
);

has 'source' => (
    isa => 'Str',
    is => 'rw',
    required => 0,
    default => '',
);

has 'width' => (
    isa => 'Int',
    is => 'rw',
    required => 0,
    default => 0,
);

has 'height' => (
    isa => 'Int',
    is => 'rw',
    required => 0,
    default => 0,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( content => $_[0] );
    }
    else {
        return $class->$orig( @_ );
    }
};

has 'is_valid' => (
    isa => 'Bool',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        return ( length $self->content || length $self->source ) ? 1 : 0;
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

    my %attrs = ();
    $attrs{ src } = $self->source if ( length $self->source );
    $attrs{ width } = $self->width if ( $self->width );
    $attrs{ height } = $self->height if ( $self->height );

    return $gen->figure(
        { class => 'op-interactive' },
        $gen->iframe(
            ( keys %attrs ? \%attrs : undef ),
            \$self->content,
        ),
    );
}

1;
