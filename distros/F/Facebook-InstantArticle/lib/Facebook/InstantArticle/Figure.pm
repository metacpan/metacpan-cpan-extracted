package Facebook::InstantArticle::Figure;
use Moose;
use namespace::autoclean;

extends 'Facebook::InstantArticle::BaseElement';

has 'source' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
    default => '',
);

has 'caption' => (
    isa => 'Str',
    is => 'rw',
    required => 0,
    default => '',
);

has 'enable_comments' => (
    isa => 'Bool',
    is => 'rw',
    required => 0,
    default => 0,
);

has 'enable_likes' => (
    isa => 'Bool',
    is => 'rw',
    required => 0,
    default => 0,
);

has 'presentation' => (
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

        return ( $self->source =~ m,^https?://.+, ) ? 1 : 0;
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

    my @comments_likes = ();
    push( @comments_likes, 'fb:comments' ) if ( $self->enable_comments );
    push( @comments_likes, 'fb:likes'    ) if ( $self->enable_likes    );

    my %attrs = ();

    if ( @comments_likes ) {
        $attrs{'data-feedback'} = join( ' ', @comments_likes );
    }

    if ( length $self->presentation ) {
        $attrs{'data-mode'} = $self->presentation;
    }

    if ( $self->isa('Facebook::InstantArticle::Figure::Image') ) {
        return $gen->figure(
            ( keys %attrs ? \%attrs : undef ),
            $gen->img( { src => $self->source } ),
            ( length $self->caption ? $gen->figcaption(\$self->caption) : undef ),
        );
    }
    elsif ( $self->isa('Facebook::InstantArticle::Figure::Video') ) {
        return $gen->figure(
            ( keys %attrs ? \%attrs : undef ),
            $gen->video(
                $gen->source( { src => $self->source } ),
            ),
            ( length $self->caption ? $gen->figcaption(\$self->caption) : undef ),
        );
    }
}

1;
