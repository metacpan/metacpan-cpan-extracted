=head1 NAME

Games::FrogJump - An ASCII game for fun

=head1 SYNOPIS

 use Games::FrogJump;
 Games::FrogJump->new->run;

=head1 DESCRIPTION

This module is an ASCII game , It runs at command-line. Control the frogs jump to each side.

Play the game with command:

  frogjump

=begin HTML

<p><img src="http://ww3.sinaimg.cn/large/a8e976cegw1ej24klqiqkj20gf07gt8t.jpg" /></p>

=end HTML

=head1 ACKNOWLEDGEMENTS

BLAIZER, Author of L<Games::2048>

=head1 AUTHOR

tadegenban <tadegenban@gmail.com>

=cut

package Games::FrogJump;
use 5.012;
use Moo;

our $VERSION = '0.05';

use Time::HiRes;
our $FRAME_TIME = 1/20;

use Games::FrogJump::Game;
use Games::FrogJump::Frog;
use Games::FrogJump::Input;
use Games::FrogJump::Animation;

sub run {
    my $self = shift;
    my $game;
    my $restart;
    my $quit;

    while (!$quit) {

        if ( !$game ) {
            $game = Games::FrogJump::Game->new();
        }
        if ( $restart ){
            $game->restart;
        }
        $game->init;
        $game->draw;
        my $time = Time::HiRes::time;
      PLAY:
        while ( 1 ) {
            while ( defined(my $key = Games::FrogJump::Input::read_key) ) {
                my $cmd = Games::FrogJump::Input::key_to_cmd($key);
                if ( $cmd eq 'quit' ){
                    $quit = 1;
                    last PLAY;
                }
                if ( $cmd eq 'restart' ){
                    $restart = 1;
                    last PLAY;
                }
                if ( $cmd ) {
                    $game->act($cmd);
                }
            }
            if ( @{$game->animations} ){
                foreach my $animation ( @{$game->animations} ){
                    $game->remove_animation($animation) if $animation->end;
                    $animation->update;
                }
            }
            $game->draw;
            my $new_time = Time::HiRes::time;
            my $delta_time = $new_time - $time;
            my $delay = $FRAME_TIME - $delta_time;
            $time = $new_time;
            if ($delay > 0) {
                Time::HiRes::sleep($delay);
                $time += $delay;
            }
            if ( $game->win || $game->lose ){
                last PLAY;
            }
        }
        if ( $game->win ){
            $game->draw_win;
            $quit = 1;
        }
    }
    $game->draw_quit;
}
1;
