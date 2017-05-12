package Games::Zumbis::Zumbi;
BEGIN {
  $Games::Zumbis::Zumbi::VERSION = '0.05';
}
use Mouse;
use SDL::Rect;
use SDL::Image;
use SDL::Video;
use Games::Zumbis;

use constant SPRITE_NUM_COLS => 3;
use constant SPRITE_NUM_ROWS => 4;
use constant SPRITE_WIDTH => 32;
use constant SPRITE_HEIGHT => 45;
use constant SPRITE_TPS => 2;

has x => (is => 'rw', required => 1);
has y => (is => 'rw', required => 1);
has sprite => (is => 'ro', handles => ['sequence']);
has tx => (is => 'rw');
has ty => (is => 'rw');
has vel => (is => 'rw', default => 0.5);
has change_dt => (is => 'rw', default => \&set_new_dt  );
has dt => (is => 'rw', default => 0 );

sub set_new_dt { (500 + rand 10) }

my $imagem_zumbi = SDL::Image::load( Games::Zumbis->sharedir->file('dados/zumbi.png') );
my $rect_zumbi = SDL::Rect->new(SPRITE_NUM_COLS,
                                SPRITE_NUM_ROWS,
                                SPRITE_WIDTH,
                                SPRITE_HEIGHT);

sub BUILDARGS {
    my ($self, %args) = @_;

    my $z = SDLx::Sprite::Animated->new
      ( surface => $imagem_zumbi,
        rect  => $rect_zumbi,
        ticks_per_frame => SPRITE_TPS,
      );

    $z->set_sequences
      ( parado_esquerda   => [ [1, 3] ],
        parado_direita    => [ [1, 1] ],
        parado_cima       => [ [1, 0] ],
        parado_baixo      => [ [1, 2] ],
        esquerda          => [ [0,3], [1,3], [2,3] ],
        direita           => [ [0,1], [1,1], [2,1] ],
        cima              => [ [0,0], [1,0], [2,0] ],
        baixo             => [ [0,2], [1,2], [2,2] ],
        morrendo_cima     => [ [0,4], [1,4], [2,4], [0,8], [1,8], [2,8] ],
        morrendo_direita  => [ [0,5], [1,5], [2,5], [0,8], [1,8], [2,8] ],
        morrendo_baixo    => [ [0,6], [1,6], [2,6], [0,8], [1,8], [2,8] ],
        morrendo_esquerda => [ [0,7], [1,7], [2,7], [0,8], [1,8], [2,8] ],
        morrendo_parado_cima     => [ [0,4], [1,4], [2,4], [0,8], [1,8], [2,8] ],
        morrendo_parado_direita  => [ [0,5], [1,5], [2,5], [0,8], [1,8], [2,8] ],
        morrendo_parado_baixo    => [ [0,6], [1,6], [2,6], [0,8], [1,8], [2,8] ],
        morrendo_parado_esquerda => [ [0,7], [1,7], [2,7], [0,8], [1,8], [2,8] ],
      );

    $z->sequence('parado_baixo');
    $z->start();

    return { %args, sprite => $z };
};

sub _muda_direcao {
    my $self = shift;
    my @direcoes = @_;
    @direcoes = qw(cima baixo esquerda direita) unless @direcoes;
    $self->sequence($direcoes[int rand @direcoes ]);
}

sub tick {
    my ($self, $dt, $mapa, $heroi_x, $heroi_y) = @_;
    my $tilesize = $mapa->tilesize;


    my ($h_tx, $h_ty, $z_tx, $z_ty) = map { int($_ / $tilesize) }
      $heroi_x, $heroi_y, $self->x, $self->y;

    # muda a direcao do zumbi com o tempo
#    $self->dt( $self->dt + $dt );
#    if ($self->dt > $self->change_dt) {
#        $self->dt(0);
    if (!$self->tx ||
        !$self->ty ||
        $z_tx != $self->tx ||
        $z_ty != $self->ty) {

        # acabou de mudar de quadrado... então pode decidir a direção
        $self->tx($z_tx);
        $self->ty($z_ty);

        if (rand(1) < 0.4) {
            # zumbis sao 1/3 idiotas ;)
            $self->_muda_direcao(qw(direita esquerda cima baixo));
        } else {
            # decidir a próxima direção... precisamos fazer uma cópia do
            # mapa de colisão para fazer o algoritmo de shortest-path do
            # Dijkstra.
            my @opcoes = ();
            if ($h_tx > $z_tx) {
                push @opcoes, 'direita';
            } elsif ($h_tx < $z_tx) {
                push @opcoes, 'esquerda';
            }
            if ($h_ty > $z_ty) {
                push @opcoes, 'baixo';
            } elsif ($h_ty < $z_ty) {
                push @opcoes, 'cima';
            }
            $self->_muda_direcao(@opcoes);
        }
    }

    # move o zumbi
    my $sequencia = $self->sequence;
    my $vel = $self->vel;
    my ($change_x, $change_y) = (0,0);
    if ($sequencia eq 'esquerda') {
        $change_x = 0 - $vel * $dt;
    } elsif ($sequencia eq 'direita' ) {
        $change_x = $vel * $dt;
    } elsif ($sequencia eq 'cima'    ) {
        $change_y = 0 - $vel * $dt;
    } elsif ($sequencia eq 'baixo'   ) {
        $change_y = $vel * $dt;
    }

    my $tilex = int(($self->x + $change_x + 15) / $tilesize);
    my $tiley = int(($self->y + $change_y + 35) / $tilesize);

    if ($mapa->colisao->[$tilex][$tiley]) {
        $self->_muda_direcao();
    } else {
        $self->x( $self->x + $change_x);
        $self->y( $self->y + $change_y);
    }

}

sub rect {
    return SDL::Rect->new($_[0]->x + 15, $_[0]->y + 35,
                          32,32);
}


sub render {
    my ($self, $surface) = @_;
    $self->sprite->stop if $self->sequence =~ /morrendo/ && $self->sprite->current_frame == 5;
    $self->sprite->draw_xy( $surface, $self->x, $self->y );
}

__PACKAGE__->meta->make_immutable();

1;
