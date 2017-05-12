package Games::Zumbis::Mapa;
BEGIN {
  $Games::Zumbis::Mapa::VERSION = '0.05';
}
use Mouse;
use Games::Zumbis;
use Games::Zumbis::L10N;
use XML::Compile::Schema;
use XML::Compile::Util qw(pack_type);
use constant MAP_NS => 'http://perl.org.br/games/zumbis';
my $map_schema = XML::Compile::Schema->new( Games::Zumbis->sharedir->file('mapa.xsd') );
my $map_reader = $map_schema->compile(READER => pack_type(MAP_NS, 'mapa'),
                                      sloppy_integers => 1, sloppy_floats => 1);
use SDL;
use SDL::Color;
use SDL::TTF;
use SDL::Rect;
use SDL::Image;
use SDL::Video;
use Carp ();

SDL::TTF::init;
has arquivo => (is => 'ro', isa => 'Path::Class::File', required => 1);
has dados => (is => 'ro', isa => 'HashRef' );
has colisao => (is => 'ro', isa => 'ArrayRef');
has tileset => (is => 'ro');

my $lh = Games::Zumbis::L10N->get_handle() or die "unable to indentify language";

# translation handles inside renderer was making things too slow
my $texto_mortes = $lh->maketext('Mortes:');
my $texto_segundos = $lh->maketext('segundos');

my $font_p = SDL::TTF::open_font( Games::Zumbis->sharedir->file('dados/AtariSmall.ttf'), 16) or
  die $lh->maketext('Erro carregando a fonte');

my $color = SDL::Color->new(0,0,0);

sub BUILDARGS {
    my ($self, %args) = @_;

    $args{dados} = $map_reader->($args{arquivo});

    # povoa a matrix de colisoes com 0
    $args{colisao} =
      [ map { [ map { 0 } 0..($args{dados}{width}-1) ] } 0..($args{dados}{height}-1) ];

    for my $object (@{$args{dados}{object}}) {
        my ($x,$y) = split /,/, $object->{position};
        $args{colisao}[$x][$y] = 1 if $object->{collide};
    }

    my $tileset_filename = Games::Zumbis->sharedir->file( $args{dados}{tileset} );
    Carp::croak "tileset '$tileset_filename' não encontrado\n"
        unless -f $tileset_filename;

    $args{tileset} = SDL::Image::load( $tileset_filename );

    return \%args;
};

sub playerstart {
    my ($self) = @_;
    return split(/,/, $self->dados->{playerstart});
};

sub playerstart_px {
    my ($self) = @_;
    my $tilesize = $self->dados->{tilesize};
    return map { $_ * $tilesize } $self->playerstart;
};

sub width {
    my ($self) = @_;
    return $self->dados->{width};
};

sub height {
    my ($self) = @_;
    return $self->dados->{height};
};

sub width_px {
    my ($self) = @_;
    return $self->dados->{width} * $self->dados->{tilesize};
};

sub height_px {
    my ($self) = @_;
    return $self->dados->{height} * $self->dados->{tilesize};
};

sub tilesize {
    my ($self) = @_;
    return $self->dados->{tilesize};
}

sub render {
    my ($self, $surface, $tempo, $score) = @_;
    my $tilesize = $self->dados->{tilesize};
    my $tileset  = $self->tileset;

    # renderizar o background;
    my $back_rect = SDL::Rect->new((map {$_ * $tilesize } split /,/, $self->dados->{background}),
                                   $tilesize, $tilesize);
    for my $x (0..($self->dados->{width}-1)) {
        for my $y (0..($self->dados->{height}-1)) {
            my $rect = SDL::Rect->new($x*$tilesize, $y*$tilesize,
                                      $tilesize, $tilesize);
            SDL::Video::blit_surface( $tileset, $back_rect,
                                      $surface, $rect );
        }
    }

    # renderizar os objetos;
    for my $object (@{$self->dados->{object}}) {
        my $src_rect = SDL::Rect->new((map { $_ * $tilesize } split /,/, $object->{tile}),
                                      $tilesize, $tilesize);
        my $dst_rect = SDL::Rect->new((map { $_ * $tilesize } split /,/, $object->{position}),
                                      $tilesize, $tilesize);
        SDL::Video::blit_surface( $tileset, $src_rect,
                                  $surface, $dst_rect );
    }


    my $timer =
      SDL::TTF::render_text_blended
          ($font_p, "$texto_mortes $score. $tempo $texto_segundos", $color)
            or die 'TTF render error: ' . SDL::get_error();
    my $timer_w = $timer->w;
    my $timer_h = $timer->h;
    my $timer_srcrect = SDL::Rect->new(0,0,$timer_w,$timer_h);
    my $dstrect = SDL::Rect->new(40,$surface->h - $timer_h - 30,$timer_w,$timer_h);
    SDL::Video::blit_surface($timer, $timer_srcrect, $surface, $dstrect);

};

sub next_spawnpoint_px {
    my ($self) = @_;
    my $tilesize = $self->dados->{tilesize};
    my $sp_count = scalar @{$self->dados->{zombie}};
    my $sp_num = int(rand($sp_count - 1)+0.5);
    return map { $_ * $tilesize } split /,/, $self->dados->{zombie}[$sp_num]{posicao};
}

__PACKAGE__->meta->make_immutable();

1;
