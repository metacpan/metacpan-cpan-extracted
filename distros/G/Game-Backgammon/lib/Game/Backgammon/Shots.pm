package Game::Backgammon::Shots;

use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT_OK = qw(shots_at);

my @SHOTS;
{
    for my $d (1 .. 24) {
        my $n = 0;
        for my $a (1 .. 6) {
            for my $b (1 .. 6) {
                my %reach;
                if ($a == $b) { $reach{ $a * $_ } = 1 for 1 .. 4 }
                else          { @reach{ $a, $b, $a + $b } = (1) x 3 }
                $n++ if $reach{$d};
            }
        }
        $SHOTS[$d] = $n;
    }
}

sub shots_at {
    my ($distance) = @_;
    return 0 unless defined $distance && $distance >= 1 && $distance <= 24;
    return $SHOTS[$distance];
}

sub table { return [ @SHOTS ] }

1;

__END__

=head1 NAME

Game::Backgammon::Shots - how many of the 36 rolls reach a point

=head1 SYNOPSIS

    use Game::Backgammon::Shots qw(shots_at);

    shots_at(6);     # 17: a direct 6, plus 5-1, 4-2, 3-3, 2-2
    shots_at(7);     # 6: only the combinations
    shots_at(11);    # 2: 6-5 either way round

=head1 DESCRIPTION

The number of the 36 ordered dice rolls that can cover C<$distance> pips,
which is what says whether a blot is safe. Six away is 17 shots; seven away
is 6. A pip count cannot see that difference and it decides games.

The table is computed by enumeration rather than typed in, so the published
shot table can be used as a test of it rather than as its source.

=head2 What it ignores

Blocked intermediate points. A combination shot needs somewhere to land
halfway, so a blot behind a made point is safer than this says. The error is
small and in the safe direction: it makes the bot shyer than it needs to be.

=head1 FUNCTIONS

=head2 shots_at($distance)

How many of the 36 rolls can cover C<$distance> pips. 0 outside 1 to 24.

=head2 table

The whole table as an arrayref, indexed by distance.

=cut
