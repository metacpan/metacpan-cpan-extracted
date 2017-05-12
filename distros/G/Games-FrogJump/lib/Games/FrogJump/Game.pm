package Games::FrogJump::Game;
use 5.012;
use Moo;


extends 'Games::FrogJump::Board';

has init_directions   => is => 'ro' => default => sub { [ 'right', 'right', 'right', 'left', 'left', 'left' ] };
has target_directions => is => 'ro' => default => sub { [ 'left', 'left', 'left', 'null', 'right', 'right', 'right' ] };

sub init {
    my $self = shift;
    my $directions = $self->init_directions;
    foreach my $index ( 0..$self->frog_number - 1 ){
        my $frog = Games::FrogJump::Frog->new(
            direction    => $directions->[$index],
            stone_index  => $index < 3 ? $index : $index + 1,
            bg_color     => $index < 3 ? 'on_yellow' : 'on_green',
            ansi         => $index < 3 ? '_--'  : '--_',
            x            => $index < 3 ?
                            $self->border_width + $self->padding + ($self->stone_width - $self->frog_width) / 2 + $index * ( $self->stone_width + $self->stone_gap ) :
                            $self->border_width + $self->padding + ($self->stone_width - $self->frog_width) / 2 + ($index + 1) * ( $self->stone_width + $self->stone_gap ),
            y            => $self->content_height - 1,
            oldx         => $index < 3 ?
                            $self->border_width + $self->padding + ($self->stone_width - $self->frog_width) / 2 + $index * ( $self->stone_width + $self->stone_gap ) :
                            $self->border_width + $self->padding + ($self->stone_width - $self->frog_width) / 2 + ($index + 1) * ( $self->stone_width + $self->stone_gap ),
            oldy         => $self->content_height - 1,
            );
        $self->set_frog( $index, $frog );
    }
    $self->set_current_frog($self->get_frog(0));
    $SIG{INT} = sub { $self->draw_quit; exit 1 };
    $SIG{__DIE__} = sub { $self->draw_quit; exit 1};
    $self->clear_screen;
}

sub act {
    my $self = shift;
    my $cmd  = shift;
    if ( $cmd eq 'left' ){
        $self->move_left;
    }
    if ( $cmd eq 'right' ){
        $self->move_right;
    }
    if ( $cmd eq 'jump' ){
        $self->jump;
    }
}
sub jump {
    my ( $self ) = @_;
    my $current_frog = $self->current_frog;
    my $current_stone = $current_frog->stone_index;
    my $direction = $current_frog->direction;
    if ( $direction eq 'right' ){
        $self->alarm_no_jump and return if $current_stone == $self->stone_number - 1;
        my $next_frog = $self->frog_on_stone($current_stone + 1);
        if ( $next_frog->direction eq 'null' ){
            $self->jump_frog_right($current_frog, 1);
            return;
        }
        $self->alarm_no_jump and return if $current_stone == $self->stone_number - 2;
        my $next_next_frog = $self->frog_on_stone($current_stone + 2);
        if ( $next_next_frog->direction eq 'null' ){
            $self->jump_frog_right($current_frog, 2);
            return;
        }
        $self->alarm_no_jump and return;
    }
    if ( $direction eq 'left' ){
        $self->alarm_no_jump and return if $current_stone == 0;
        my $next_frog = $self->frog_on_stone($current_stone - 1);
        if ( $next_frog->direction eq 'null' ){
            $self->jump_frog_left($current_frog, 1);
            return;
        }
        $self->alarm_no_jump and return if $current_stone == 1;
        my $next_next_frog = $self->frog_on_stone($current_stone - 2);
        if ( $next_next_frog->direction eq 'null' ){
            $self->jump_frog_left($current_frog, 2);
            return;
        }
        $self->alarm_no_jump and return;
    }
}

sub move_left {
    my ( $self ) = @_;
    my $current_stone = $self->current_frog->stone_index;
    if( $current_stone == 0 ){
        return;
    }
    my $next_frog = $self->frog_on_stone($current_stone - 1);
    if ($next_frog->direction eq 'null' ) {
        if ( $current_stone == 1 ){
            return;
        }
        else{
            $next_frog = $self->frog_on_stone($current_stone - 2);
        }
    }
    $self->set_current_frog( $next_frog );
}

sub move_right {
    my ( $self ) = @_;
    my $current_stone = $self->current_frog->stone_index;
    if( $current_stone == $self->stone_number - 1 ){
        return;
    }
    my $next_frog = $self->frog_on_stone($current_stone + 1);
    if ($next_frog->direction eq 'null' ) {
        if ( $current_stone == $self->stone_number - 2 ){
            return;
        }
        else{
            $next_frog = $self->frog_on_stone($current_stone + 2);
        }
    }
    $self->set_current_frog( $next_frog );
}

sub alarm_no_jump {
    my $self = shift;
    my $animation = Games::FrogJump::Animation->new(
        name     => 'alarm_no_jump',
        duration => 0.5,
        obj      => $self,
        attr     => 'border_color',
        snapshot => ['on_white', $self->border_color],
        );
    $self->add_animation($animation);
    return 1;
}

sub win {
    my $self = shift;
    foreach my $stone ( 0..$self->stone_number-1 ){
        return 0 if $self->target_directions->[$stone] ne $self->frog_on_stone($stone)->direction;
    }
    return 1;
}

sub lose {
    my $self = shift;
    return 0;
}

sub restart {
    my $self = shift;
    $self->move_cursor(0, $self->border_height + $self->content_height);
    $self->clear_screen;
}
1;
