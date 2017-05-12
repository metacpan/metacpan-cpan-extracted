package Games::Zumbis::TelaGameOver;
BEGIN {
  $Games::Zumbis::TelaGameOver::VERSION = '0.05';
}
use Mouse;
use SDL::Rect;
use SDL::Image;
use SDL::Video;
use SDLx::Surface;
use SDL::TTF;
use Games::Zumbis;
use Games::Zumbis::L10N;
use utf8;

has tempo => (is => 'ro', required => 1);
has ultimo_frame => (is => 'ro', required => 1);
has texto => (is => 'ro', required => 1);
has texto_sc => (is => 'ro', required => 1);

my $lh = Games::Zumbis::L10N->get_handle() or die "unable to indentify language";

my $image = SDLx::Surface->new(surface => SDL::Image::load( Games::Zumbis->sharedir->file('dados/gameover.png') ));

SDL::TTF::init();
my $font = SDL::TTF::open_font( Games::Zumbis->sharedir->file('dados/AtariSmall.ttf'), 30) or
  die $lh->maketext('Erro carregando a fonte');

my $font_p = SDL::TTF::open_font( Games::Zumbis->sharedir->file('dados/AtariSmall.ttf'), 16) or
  die $lh->maketext('Erro carregando a fonte');

my $color = SDL::Color->new(0,0,0);

my $selectchar =
  SDL::TTF::render_text_blended
  ($font_p, $lh->maketext('Aperte 1 para Heroi, 2 para Heroina ou enter para continuar!'), $color)
  or die 'TTF render error: ' . SDL::get_error();

my $selectchar_w = $selectchar->w;
my $selectchar_h = $selectchar->h;
my $selectchar_srcrect = SDL::Rect->new(0,0,$selectchar_w,$selectchar_h);

sub BUILDARGS {
    my ($self, %args) = @_;

    my $surface = delete $args{surface}
      or die 'faltou o argumento "surface" com a tela do jogo';

    my $ultimo_frame = SDLx::Surface->new(width => $surface->w,
                                          height => $surface->h);
    my $rect1 =  SDL::Rect->new(0,0,$surface->w,$surface->h);
    my $rect2 =  SDL::Rect->new(0,0,$surface->w,$surface->h);
    $surface->blit($ultimo_frame, $rect1, $rect2);

    my $texto = SDL::TTF::render_text_blended(
           $font,
           $lh->maketext('Voce sobreviveu por [_1] segundos!', $args{tempo}),
           $color
    ) or die 'TTF render error: ' . SDL::get_error();

    my $texto_sc = SDL::TTF::render_text_blended(
            $font,
            $lh->maketext('E matou [quant,_1,zumbi]!', $args{score}),
            $color
    ) or die 'TTF render error: ' . SDL::get_error();

    $args{ultimo_frame} = $ultimo_frame;
    $args{texto} = $texto;
    $args{texto_sc} = $texto_sc;
    return \%args;
}

sub render {
    my ($self, $surface) = @_;

    my $rect1 = SDL::Rect->new(0,0,$surface->w,$surface->h);
    my $rect2 = SDL::Rect->new(0,0,$surface->w,$surface->h);
    $self->ultimo_frame->blit($surface, $rect1, $rect2);
    my $srcrect = SDL::Rect->new(0,0,759,408);
    my $dstrect = SDL::Rect->new($surface->w/2-759/2,$surface->h/2-408/2,759,408);
    $image->blit($surface, $srcrect, $dstrect);

    my $texto = $self->texto;
    my $texto_w = $texto->w;
    my $texto_h = $texto->h;
    $srcrect = SDL::Rect->new(0,0,$texto_w,$texto_h);
    $dstrect = SDL::Rect->new($surface->w/2-$texto_w/2,$surface->h/2-$texto_h/2,$texto_w,$texto_h);
    SDL::Video::blit_surface($texto, $srcrect, $surface->surface, $dstrect);

    my $texto_sc = $self->texto_sc;
    my $texto_sc_w = $texto_sc->w;
    my $texto_sc_h = $texto_sc->h;
    $srcrect = SDL::Rect->new(0,0,$texto_sc_w,$texto_sc_h);
    $dstrect = SDL::Rect->new($surface->w/2-$texto_sc_w/2,$surface->h/2-$texto_sc_h/2+$texto_h+15,$texto_w,$texto_h);
    SDL::Video::blit_surface($texto_sc, $srcrect, $surface->surface, $dstrect);


    $dstrect = SDL::Rect->new(40,$surface->h - $selectchar_h - 60,$selectchar_w,$selectchar_h);
    SDL::Video::blit_surface($selectchar, $selectchar_srcrect, $surface->surface, $dstrect);

}

__PACKAGE__->meta->make_immutable();


1;
