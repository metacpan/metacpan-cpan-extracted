package Facebook::InstantArticle::List;
use Moose;
use namespace::autoclean;

extends 'Facebook::InstantArticle::BaseElement';

has 'elements' => (
    isa => 'ArrayRef[Str]',
    is => 'rw',
    required => 0,
    default => sub { [] },
);

has 'ordered' => (
    isa => 'Bool',
    is => 'rw',
    required => 0,
    default => 0,
);

has 'is_valid' => (
    isa => 'Bool',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        return scalar @{ $self->elements } ? 1 : 0;
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

    my $tag = ( $self->ordered ) ? 'ol' : 'ul';

    return $gen->$tag(
        map { $gen->li(\$_) } @{ $self->elements },
    );
}

1;
