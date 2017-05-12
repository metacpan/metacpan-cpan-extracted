package Games::FrogJump::Board;
use 5.012;
use strict;
use warnings;
use Moo;

use if $^O eq "MSWin32", "Win32::Console::ANSI";
use Term::ANSIColor;
use List::MoreUtils qw/none/;

has frog_number   => is => 'rw', default => 6;
has frog_width    => is => 'rw', default => 3;
has stone_number  => is => 'rw', default => sub { my $self = shift; $self->frog_number + 1 };
has stone_width   => is => 'rw', default => 7;
has stone_gap     => is => 'rw', default => 2;

has border_width  => is => 'rw', default => 2;
has border_height => is => 'rw', default => 1;
has border_color  => is => 'rw', default => 'on_cyan';
has content_width => is => 'rw', default => 70;
has content_height => is => 'rw', default => 13;
has padding       => is => 'rw', default => 4;

has _frogs       => is => 'lazy';
has current_frog => is => 'rw', default => '';
has animations   => is => 'rw', default => sub { [] };

sub draw {
    my ( $self ) = @_;
    local $| = 1;
    $self->hide_cursor;
    $self->draw_frog;
    $self->draw_border;
    $self->draw_title;
    $self->draw_guide;
    $self->draw_stone;

}

sub draw_frog {
    my $self = shift;
    foreach my $frog ( @{$self->_frogs} ){
        if ( $frog->x ne $frog->oldx or $frog->y ne $frog->oldy ){
            $self->save_cursor;
            $self->move_cursor($frog->oldx, $frog->oldy);
            print ' ' x 3;
            $self->restore_cursor;

            $self->save_cursor;
            $self->move_cursor($frog->x, $frog->y);
            print $frog->graph;
            $self->restore_cursor;
        }
        else{
            $self->save_cursor;
            $self->move_cursor($frog->x, $frog->y);
            print $frog->graph;
            $self->restore_cursor;
        }
    }
}

sub draw_stone {
    my ( $self )  = @_;
    $self->save_cursor;
    $self->move_cursor(6, $self->content_height);
    foreach my $index ( 0..$self->stone_number-1 ){
        my $stone;
        my $gap;
        $stone = ' ' x $self->stone_width;
        $stone = color('reverse cyan'). $stone . color('reset');
        $gap   = ' ' x $self->stone_gap;
        print $stone;
        print $gap;
    }
    $self->restore_cursor;
}

sub draw_guide {
    my $self = shift;
    $self->save_cursor;
    $self->move_cursor($self->content_width-15, 2);
    print color('green') . '<-' . color('reset') . ' : select frog';
    $self->move_cursor(-16, 1);
    print color('green') . '->' . color('reset') . ' : select frog';
    $self->move_cursor(-16, 1);
    print color('green') . 'sp' . color('reset') . ' : jump       ';
    $self->move_cursor(-16, 1);
    print color('green') . 'r ' . color('reset') . ' : restart    ';
    $self->move_cursor(-16, 1);
    print color('green') . 'q ' . color('reset') . ' : quit       ';
    $self->restore_cursor;
}

sub draw_title {
    my $self = shift;
    $self->save_cursor;
    $self->move_cursor(30, 2);
    print color('green') . 'Frog Jump --_' . color('reset');
    $self->restore_cursor;
}

sub draw_win {
    my $self = shift;
    $self->save_cursor;
    $self->move_cursor(30, 2);
    print color('green') . 'You  Win  @@_' . color('reset');
    $self->restore_cursor;
}

sub draw_quit {
    my $self = shift;
    $self->move_cursor(0, $self->content_height + 5);
    say color('reset') . '';
    $self->show_cursor;
}
sub draw_border {
    my $self = shift;
    $self->save_cursor;
    say color($self->border_color), " " x $self->board_width, color("reset") for 1..$self->border_height;
    foreach my $col ( 0..$self->content_height-1 ){
        print color($self->border_color), " " x $self->border_width, color("reset");
        $self->move_cursor(70, 0);
        print color($self->border_color), " " x $self->border_width, color("reset");
        print "\n";
    }

    say color($self->border_color), " " x $self->board_width, color("reset") for 1..$self->border_height;
    $self->restore_cursor;
}

sub add_animation {
    my ( $self, $animation ) = @_;
    if ( none { $_->name eq $animation->name } @{$self->animations} ){
        push $self->animations, $animation;
    }
}

sub remove_animation {
    my ( $self, $animation ) = @_;
    my $new_animations = [ grep { $_->name ne $animation->name } @{$self->animations} ];
    $self->animations($new_animations);
}

sub board_width {
    my $self = shift;
    return $self->content_width + $self->border_width * 2;
}

sub board_height {
    my $self = shift;
    return $self->border_height * 2 + $self->content_height;
}

sub move_cursor {
    my ( $self, $dx, $dy ) = @_;
    $dx > 0 ? do { printf "\e[%dC", $dx } : $dx < 0 ? do { printf "\e[%dD", -$dx } : do {};
    $dy > 0 ? do { printf "\e[%dB", $dy } : $dy < 0 ? do { printf "\e[%dA", -$dy } : do {};
}

sub save_cursor {
    my $self = shift;
    print "\e[s";
}

sub restore_cursor {
    my $self = shift;
    print "\e[u";
}

sub hide_cursor {
    my $self = shift;
    state $once = eval 'END { $self->show_cursor }';
    print "\e[?25l";
}
sub show_cursor {
    my $self = shift;
    print "\e[?25h";
}

sub clear_screen {
    my $self = shift;
    print "\e[1J";
    print "\e[1;1H";
}

sub get_frog {
    my $self = shift;
    my $n    = shift;
    return $self->_frogs->[$n];
}

sub set_frog {
    my ( $self, $index, $frog )= @_;
    $self->_frogs->[$index] = $frog;
}

sub frog_on_stone {
    my ( $self, $stone_n ) = @_;
    foreach my $n ( 0..$self->frog_number-1 ){
        my $frog = $self->get_frog($n);
        return $frog if $frog->stone_index == $stone_n;
    }
    my $null_frog = Games::FrogJump::Frog->new();
    return $null_frog;
}

sub jump_frog_left {
    my ( $self, $frog, $step ) = @_;
    $frog->stone_index($frog->stone_index - $step);

    my $stopx = $frog->x - $step * ( $self->stone_width + $self->stone_gap );

    my $animation_x = Games::FrogJump::Animation->new(
        name     => 'x',
        duration => 0.5,
        obj      => $frog,
        attr     => 'set_x',
        snapshot => [$frog->x, int(($frog->x + $stopx) / 2), $stopx],
        );
    my $animation_y = Games::FrogJump::Animation->new(
        name     => 'y',
        duration => 0.5,
        obj      => $frog,
        attr     => 'set_y',
        snapshot => [$frog->y, $frog->y - $step, $frog->y],
        );
    $self->add_animation($animation_x);
    $self->add_animation($animation_y);

}

sub jump_frog_right {
    my ( $self, $frog, $step ) = @_;
    $frog->stone_index($frog->stone_index + $step);

    my $stopx = $frog->x + $step * ( $self->stone_width + $self->stone_gap);

    my $animation_x = Games::FrogJump::Animation->new(
        name     => 'x',
        duration => 0.5,
        obj      => $frog,
        attr     => 'set_x',
        snapshot => [$frog->x, int(($frog->x + $stopx) / 2), $stopx],
        );
    my $animation_y = Games::FrogJump::Animation->new(
        name     => 'y',
        duration => 0.5,
        obj      => $frog,
        attr     => 'set_y',
        snapshot => [$frog->y, $frog->y - $step, $frog->y],
        );
    $self->add_animation($animation_x);
    $self->add_animation($animation_y);
}

sub _build__frogs {
    my $self = shift;
    [ 1..$self->frog_number ];
}


sub set_current_frog {
    my ( $self, $frog ) = @_;
    $self->current_frog->unactive if $self->current_frog ne '';
    $self->current_frog($frog);
    $frog->active;
}



1;
