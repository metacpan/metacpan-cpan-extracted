package Game::Gin::Deadwood;

use strict;
use warnings;

use Exporter 'import';

use Game::Gin::Card qw(deadwood_of);
use Game::Gin::Meld qw(melds_in);

our $VERSION = '0.01';
our @EXPORT_OK = qw(best deadwood can_knock is_gin KNOCK_AT);

use constant KNOCK_AT => 10;

my %CACHE;

sub _total { my $t = 0; $t += deadwood_of($_) for @{ $_[0] }; return $t }

sub best {
    my ($cards) = @_;
    $cards ||= [];
    return { melds => [], deadwood => 0, unmatched => [] } unless @$cards;

    my $key = join ',', sort { $a <=> $b } @$cards;
    return $CACHE{$key} if $CACHE{$key};

    my $total = _total($cards);

    my (%at, @by_pos);
    for my $i (0 .. $#$cards) { $at{ $cards->[$i] } = $i; $by_pos[$i] = $cards->[$i] }

    my @cand;
    for my $meld (melds_in($cards)) {
        my ($mask, $value) = (0, 0);
        for my $c (@$meld) {
            $mask |= 1 << $at{$c};
            $value += deadwood_of($c);
        }
        push @cand, { mask => $mask, value => $value, cards => $meld };
    }

    @cand = sort { $b->{value} <=> $a->{value} } @cand;

    my ($best_value, @best_melds) = (0);
    my @chosen;

    my @suffix = (0) x (@cand + 1);
    for (my $i = $#cand; $i >= 0; $i--) { $suffix[$i] = $suffix[ $i + 1 ] + $cand[$i]{value} }

    my $walk;
    $walk = sub {
        my ($i, $used, $value) = @_;
        if ($value > $best_value) {
            $best_value = $value;
            @best_melds = map { [@$_] } @chosen;
        }
        return if $i > $#cand;
        return if $value + $suffix[$i] <= $best_value;

        for my $k ($i .. $#cand) {
            next if $cand[$k]{mask} & $used;
            return if $value + $suffix[$k] <= $best_value;
            push @chosen, $cand[$k]{cards};
            $walk->($k + 1, $used | $cand[$k]{mask}, $value + $cand[$k]{value});
            pop @chosen;
        }
        return;
    };
    $walk->(0, 0, 0);

    my $melded = 0;
    $melded |= (1 << $at{$_}) for map { @$_ } @best_melds;
    my @unmatched = grep { !($melded & (1 << $at{$_})) } @$cards;

    return $CACHE{$key} = {
        melds     => \@best_melds,
        deadwood  => $total - $best_value,
        unmatched => \@unmatched,
    };
}

sub deadwood  { return best($_[0])->{deadwood} }
sub can_knock { return best($_[0])->{deadwood} <= KNOCK_AT ? 1 : 0 }
sub is_gin    { return best($_[0])->{deadwood} == 0 ? 1 : 0 }

1;

__END__

=head1 NAME

Game::Gin::Deadwood - the least deadwood a hand can be left with

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Gin::Deadwood qw(best deadwood can_knock is_gin);

    my $b = best(\@cards);
    $b->{melds};       # arrayrefs of ids
    $b->{deadwood};    # what is left, in points
    $b->{unmatched};   # the cards that are left

    deadwood(\@cards);     # just the number
    can_knock(\@cards);    # deadwood <= 10
    is_gin(\@cards);       # deadwood == 0

=head1 DESCRIPTION

Finds the arrangement of a hand into sets and runs that leaves the least
deadwood, and says what is left over.

Every other question in gin rummy is this one asked again: whether you may
knock, whether it is gin, what a hand scored, what the bot should discard.

=head2 It is exact

Not greedy. A card wanted by both a set and a run is a real decision, and
taking the longest meld first loses hands. L<Game::Gin::Meld> enumerates
sub-melds so that the choice exists, and this searches the disjoint
combinations of them.

Eleven cards produce around twenty candidate melds, so the exact search costs
nothing worth saving.

=head2 It is memoised

On the sorted hand. A bot asks about the same eleven cards once per candidate
discard, so the same question arrives many times in one turn.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 best

    my $b = best(\@cards);

A hashref of C<melds>, C<deadwood> and C<unmatched>. An empty hand is zero
deadwood and no melds.

=head2 deadwood

The number alone.

=head2 can_knock

Whether the deadwood is at or under the knock threshold.

=head2 is_gin

Whether the hand melds completely.

=head2 KNOCK_AT

10.

=head1 SEE ALSO

L<Game::Gin::Meld>, L<Game::Gin::Card>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
