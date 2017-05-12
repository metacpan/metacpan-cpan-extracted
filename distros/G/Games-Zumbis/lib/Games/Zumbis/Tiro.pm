package Games::Zumbis::Tiro;
BEGIN {
  $Games::Zumbis::Tiro::VERSION = '0.05';
}
use 5.10.0;
use Mouse;
use SDL::Rect;
use SDL::Image;
use SDL::Video;
use Games::Zumbis::Audio;
use Games::Zumbis;

has x => (is => 'rw');
has y => (is => 'rw');
has vel => (is => 'rw', default => 0.8);
has type => (is => 'rw');
has collided => (is => 'rw', default => 0);
has sound => (
               is      => 'ro',
               default => sub {
                   Games::Zumbis::Audio->load_sound(
                        Games::Zumbis->sharedir->file('dados/shot.ogg')
                   )
               }
             );

sub BUILD {
    Games::Zumbis::Audio->play( shift->sound );
}

my $sprites = SDL::Image::load( Games::Zumbis->sharedir->file('dados/bullet.png'));
my %rects =
  ( left  => SDL::Rect->new(0, 0, 20, 10),
    right => SDL::Rect->new(0, 10, 20, 10),
    up    => SDL::Rect->new(0, 20, 10, 20),
    down  => SDL::Rect->new(10, 20, 10, 20),
  );

my $cache_colisao;
my $cache_dados;
my $cache_identity = 0;

sub tick {
    my ($self, $dt, $mapa) = @_;
    return 0 if $self->{collided};
    if ($cache_identity != $mapa) {
        $cache_colisao = $mapa->colisao;
        $cache_dados = $mapa->dados;
        $cache_identity = $mapa;
    }
    my $tilesize = $cache_dados->{tilesize};

    my ($x, $y) = ($self->x, $self->y);
    my ($o_t_x, $o_t_y) = map { int( $_ / $tilesize ) } $x, $y;

    my ($change_x, $change_y) = (0,0);
    my ($type, $vel) = ($self->type, $self->vel);
    
    if    ($type eq 'left')  { $change_x = 0 - $vel * $dt }
    elsif ($type eq 'right') { $change_x =     $vel * $dt }
    elsif ($type eq 'up')    { $change_y = 0 - $vel * $dt }
    elsif ($type eq 'down')  { $change_y =     $vel * $dt }

    my ($tiles_x, $tiles_y) = map { int($_ / $tilesize) }
      ($change_x, $change_y);

    my ($step_x, $step_y) = map { $_ > 0 ? 1 : -1 }
      ($tiles_x, $tiles_y);

    my $mwidth = $cache_dados->{width};
    my $mheight = $cache_dados->{height};

    my ($n_t_x, $n_t_y) = ($o_t_x, $o_t_y);
    while ($tiles_x &&
           $n_t_x >= 0 &&
           $n_t_x < $mwidth) {
        if ($cache_colisao->[$n_t_x][$n_t_y]) {
            return 0;
        }
        $tiles_x -= $step_x;
        $n_t_x += $step_x;
    }
    while ($tiles_y &&
           $n_t_y >= 0 &&
           $n_t_y < $mheight) {
        if ($cache_colisao->[$n_t_x][$n_t_y]) {
            return 0;
        }
        $tiles_y -= $step_y;
        $n_t_y += $step_y;
    }
    if ($n_t_x <= 0 ||
        $n_t_x >= $mwidth ||
        $n_t_y <= 0 ||
        $n_t_y >= $mheight) {
        return 0;
    }

    $self->{x} = ($x + $change_x);
    $self->{y} = ($y + $change_y);

    return 1;
}


sub rect {
    my ($self) = @_;
    return SDL::Rect->new($self->x, $self->y,
                          $rects{$self->type}->w,$rects{$self->type}->h);
}

sub render {
    my ($self,$surface) = @_;
    SDL::Video::blit_surface( $sprites, $rects{$self->type},
                              $surface, $self->rect );
}

__PACKAGE__->meta->make_immutable();

1;
