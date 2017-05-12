package Facebook::InstantArticle::Heading;
use Moose;
use namespace::autoclean;

extends 'Facebook::InstantArticle::BaseElement';

has 'level' => (
    isa => 'Int',
    is => 'rw',
    required => 1,
    default => 0,
);

has 'text' => (
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

        return (length $self->text && $self->level > 1 && $self->level < 7) ? 1 :0;
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

    if ( $self->level == 1 ) {
        return $gen->h1(
            \$self->text,
        );
    }
    else {
        return $gen->h2(
            \$self->text,
        );
    }
}

1;
