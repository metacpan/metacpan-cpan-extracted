use strict;
use Test::More;
use Games::Mastermind;

plan tests => 7;

my $mm = Games::Mastermind->new;
my @pegs = @{ $mm->pegs }; 

my @h;

is( $mm->turn, 0, "Game not started" );
for( 1 .. 4 ) {
    my $play = [ map { $pegs[rand @pegs] } 1 .. 4 ];
    my $marks = $mm->play( @$play );
    push @h, [ $play, $marks ];
    is( $mm->turn, $_, "Turn $_" );
}

is_deeply( \@h, $mm->history, "Didn't change history" );

# change a parameter
$mm->holes( 5 );
is_deeply( $mm->history, [], "The setters reset the game" );
