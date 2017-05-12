# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 010-Register.t'

#########################

use strict;
use warnings;

use Test::More tests => 26;
use Try::Tiny;
use Games::Go::AGA::DataObjects::Player;
use Games::Go::AGA::Parse::Register;

use_ok('Games::Go::AGA::DataObjects::Register');

my $reg = new_ok ('Games::Go::AGA::DataObjects::Register');

my $parser = Games::Go::AGA::Parse::Register->new(
    filename => 'data_in_010-Register.t',
);
while(<DATA>) {
    my $result = $parser->parse_line($_);
    if (exists $result->{directive}) {
        $reg->set_directive_value(
            $result->{directive},
            $result->{value},
        );
    }
    elsif (exists $result->{id}) {
        my $player = Games::Go::AGA::DataObjects::Player->new(%{$result});
        $reg->insert_player_at_idx(-1, $player);
    }
    elsif (exists $result->{comment}) {
      # push (@comments, $result->{comment});
    }
    elsif (keys %{$result}) {
        die "unknown result";
    }
}

my $players = $reg->players;

# foreach (@{$players}) {
#     $_->print;
# }

is (${$players}[0]->last_name, 'Person', 'first player, last name is Person');

my $err = "no error";
try {
    $reg->insert_player_at_idx(-1, $players->[1]);
} catch {
    $err = $_;
};
like ($err, '/duplicate ID/', 'duplicate ID produces error');
is ($players->[3]->rank, 4.44, 'fourth player, rank is 4.44');
is ($reg->id_is_duplicate('UAS333', undef), 0, 'non-duplicated ID not reported as duplicate');
is ($reg->id_is_duplicate('USA3', undef), 1, 'duplicated ID is detected'); # same as USA003
is ($reg->get_directive_value('BAND_BREAKS'), '1 -2', "BAND_BREAKS is '1 -2'");
for my $ii (0 .. $#{$players}) {
    my $rating = $players->[$ii]->rating;
    my $expect = 0;
    $expect++ if ($rating < 1.0);
    $expect++ if ($rating <= -3.0);
    my $rank = $players->[$ii]->rank;
    is ($reg->which_band_is($rank), $expect, "rank $rank is in band $expect");
}


__DATA__

## TOURNEY Test Tournament
## RULES ING
#  # HANDICAPS MIN    Bad directive - should be seen as a comment
## ROUNDS 4
## BANDS 3
#
#   Location:
#       in a galaxy far, far away
#
USA001 Person, A                   2D
USA002 Person, Another             1d CLUB=AGA # some comment
USA003 People, Some                3k      
XXX004 Person, Some Other  4.44

XXX005 Person, B  4.44
XXX006 Person, C  -3.9
XXX007 Person, D  -3.5
XXX008 Person, E  -3.1

XXX009 Person, F  -3.0
XXX010 Person, G  -2.99
XXX011 Person, H  -2.9
XXX012 Person, I  -2.5

XXX013 Person, J  -2.1
XXX014 Person, K  -2.0
XXX015 Person, L  -1.99
XXX016 Person, M  -1.00

XXX017 Person, N  1.00
XXX018 Person, O  1.99
