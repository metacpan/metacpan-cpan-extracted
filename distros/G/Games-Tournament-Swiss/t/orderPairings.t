
# DESCRIPTION:  Check that F1 ordering works
# Created:  西元2009年07月03日 12時18分05秒
# Last Edit: 2016 Jan 01, 13:37:44

=head3 DESCRIPTION

Order pairings in F1 order

The last criterion of the ranking of the higher-ranked player at the table is not tested so well perhaps. The test gives the ranking to the first player at the table.

I'm also wondering about the homomorphism from poset of scores of lower-scoring players to that of total scores.

=cut

use lib qw/t lib/;

use strict;
use warnings;
use Test::Base;

BEGIN {
    $Games::Tournament::Swiss::Config::firstround = 1;
    @Games::Tournament::Swiss::Config::roles      = qw/White Black/;
    %Games::Tournament::Swiss::Config::scores =
      ( Win => 1, Draw => 0.5, Loss => 0, Absence => 0, Bye => 1 );
    $Games::Tournament::Swiss::Config::algorithm =
      'Games::Tournament::Swiss::Procedure::FIDE';
}

use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Swiss;
use Games::Tournament::Card;

filters { input => [qw/yaml order/], expected => [qw/chomp split array/] };

plan tests => 1 * blocks;

sub order {
    my $criteria              = shift;
    my $tableN = scalar @{ $criteria->{topplayer} };
    my ( @tables, @entrants );
    for my $table ( 0 .. $tableN-1 ) {
	my %players = (
                $Games::Tournament::Swiss::Config::roles[0] =>
                  Games::Tournament::Contestant::Swiss->new(
                    id     => $table . 0,
                    name   => chr( 2 * $table + 65 ),
                    rating => ( 2000 - $criteria->{A2ranking}->[$table] ),
                    score => ( 2 * $tableN-$criteria->{topplayer}->[$table] ) ),
		  $Games::Tournament::Swiss::Config::roles[1] =>
                  Games::Tournament::Contestant::Swiss->new(
                    id     => $table . 1,
                    name   => chr( 2 * $table + 66 ),
                    rating => 1,
                    score => ( 2 * $tableN - $criteria->{topplayer}->[$table] -
					    $criteria->{lowplayer}->[$table] ) )
                  );
	push @entrants, values %players;
        push @tables, Games::Tournament::Card->new(
	    id => $table,
            contestants => \%players );
    }
    my $tourney = Games::Tournament::Swiss->new( entrants => \@entrants);
    my @neworder = $tourney->orderPairings( @tables );
    my %ranking2id = map { $_ + 1 => $neworder[$_]->{id} } 0 .. $#neworder;
    my %id2ranking = reverse %ranking2id;
    my @hoped = ('');
    push @hoped, $id2ranking{$_} for sort keys %id2ranking;
    return \@hoped;
}

run_is_deeply input => 'expected';

__DATA__

=== top players 1
--- input
topplayer: [1, 2, 3]
lowplayer: [2, 1, 2]
A2ranking: [3, 1, 2]
--- expected
            1  2  3

=== top players 2
--- input
topplayer: [1, 3, 2]
lowplayer: [2, 1, 3]
A2ranking: [3, 1, 2]
--- expected
            1  3  2

=== top players 3
--- input
topplayer: [2, 1, 3, 4]
lowplayer: [1, 1, 1, 4]
A2ranking: [3, 2, 1, 4]
--- expected
            2  1  3  4

=== top players 4
--- input
topplayer: [2, 3, 1, 4]
lowplayer: [2, 1, 3, 3]
A2ranking: [1, 1, 1, 1]
--- expected
            2  3  1  4

=== low players 1
--- input
topplayer: [1, 1, 1]
lowplayer: [1, 2, 3]
A2ranking: [3, 1, 2]
--- expected
            1  2  3

=== low players 2
--- input
topplayer: [1, 1, 1]
lowplayer: [1, 3, 2]
A2ranking: [3, 1, 2]
--- expected
            1  3  2

=== low players 3
--- input
topplayer: [1, 1, 1]
lowplayer: [2, 1, 3]
A2ranking: [3, 1, 2]
--- expected
            2  1  3

=== low players 4
--- input
topplayer: [1, 1, 1]
lowplayer: [2, 3, 1]
A2ranking: [3, 1, 2]
--- expected
            2  3  1

=== A2 rankings 1
--- input
topplayer: [1, 1, 1]
lowplayer: [1, 1, 1]
A2ranking: [1, 2, 3]
--- expected
            1  2  3

=== A2 rankings 2
--- input
topplayer: [1, 1, 1]
lowplayer: [1, 1, 1]
A2ranking: [2, 3, 1]
--- expected
            2  3  1

=== A2 rankings 3
--- input
topplayer: [1, 1, 1]
lowplayer: [1, 1, 1]
A2ranking: [3, 1, 2]
--- expected
            3  1  2

=== A2 rankings 4
--- input
topplayer: [1, 1, 1]
lowplayer: [1, 1, 1]
A2ranking: [3, 2, 1]
--- expected
            3  2  1

=== top & low players 1
--- input
topplayer: [2, 2, 1, 2]
lowplayer: [2, 1, 3, 3]
A2ranking: [1, 2, 3, 4]
--- expected
            3  2  1  4

=== top & low players 2
--- input
topplayer: [3, 3, 1, 1]
lowplayer: [1, 2, 3, 4]
A2ranking: [1, 2, 3, 4]
--- expected
            3  4  1  2

=== top & low players 3
--- input
topplayer: [2, 2, 1, 2]
lowplayer: [1, 3, 1, 4]
A2ranking: [1, 2, 3, 4]
--- expected
            2  3  1  4

=== top & low players 4
--- input
topplayer: [1, 1, 1, 2]
lowplayer: [1, 3, 2, 4]
A2ranking: [1, 2, 3, 4]
--- expected
            1  3  2  4

=== top, low players & A2 rankings 1
--- input
topplayer: [1, 1, 3, 3]
lowplayer: [1, 3, 1, 3]
A2ranking: [1, 2, 3, 4]
--- expected
            1  2  3  4

=== top, low players & A2 rankings 2
--- input
topplayer: [1, 1, 1, 3]
lowplayer: [1, 3, 1, 3]
A2ranking: [1, 2, 3, 4]
--- expected
            1  3  2  4

=== top, low players & A2 rankings 3
--- input
topplayer: [1, 1, 1, 3]
lowplayer: [1, 4, 1, 3]
A2ranking: [1, 2, 3, 4]
--- expected
            1  3  2  4

=== top, low players & A2 rankings 4
--- input
topplayer: [1, 3, 1, 3]
lowplayer: [1, 3, 1, 3]
A2ranking: [1, 2, 3, 4]
--- expected
            1  3  2  4

