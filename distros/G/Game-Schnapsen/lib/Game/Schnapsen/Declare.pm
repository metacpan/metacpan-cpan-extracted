package Game::Schnapsen::Declare;

use strict;
use warnings;

use Exporter 'import';

use Game::Schnapsen::Card qw(suit_of rank_of id_of);

our $VERSION = '0.01';
our @EXPORT_OK = qw(marriages_in marriage_value exchange_card
                    MARRIAGE MARRIAGE_TRUMP);

use constant MARRIAGE       => 20;
use constant MARRIAGE_TRUMP => 40;

sub marriage_value {
    my ($suit, $trump) = @_;
    return $suit eq $trump ? MARRIAGE_TRUMP : MARRIAGE;
}

sub marriages_in {
    my ($cards, $trump) = @_;
    my %have;
    $have{ suit_of($_) }{ rank_of($_) } = $_ for @$cards;

    my @out;
    for my $suit (sort keys %have) {
        next unless $have{$suit}{K} && $have{$suit}{Q};
        push @out, {
            suit  => $suit,
            value => marriage_value($suit, $trump),
            king  => $have{$suit}{K},
            queen => $have{$suit}{Q},
        };
    }
    return \@out;
}

sub exchange_card {
    my ($cards, $trump, $rank) = @_;
    my $want = id_of("$rank$trump");
    return undef unless defined $want;
    return scalar(grep { $_ == $want } @$cards) ? $want : undef;
}

1;

__END__

=head1 NAME

Game::Schnapsen::Declare - marriages and the trump exchange, as arithmetic

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Schnapsen::Declare qw(marriages_in exchange_card);

    my $m = marriages_in($hand->cards, 'H');
    $m->[0]{suit};    # 'H'
    $m->[0]{value};   # 40, because hearts are trumps
    $m->[0]{king};    # the id to lead or to show

    exchange_card($hand->cards, 'H', 'J');   # the jack of hearts, or undef

=head1 DESCRIPTION

What a hand could declare, given the trump suit. Nothing here knows whether the
declaration is B<allowed>: that depends on whose lead it is, on whether the
talon is open, on how many tricks the player has taken and on which of the two
games is being played, and it therefore belongs to L<Game::Schnapsen::Deal>.

Keeping the two apart is the point. The arithmetic is shared by both games word
for word; the permission is where five of the eleven divergences live.

=head2 A marriage is twenty, or forty in trumps

The matched king and queen of a suit. Both rulesets agree on the values, on who
may declare one and on what it costs to declare one you cannot use, so all of
that is written once.

Three rules about them live in the deal rather than here, because each needs
state this module is not given:

=over 4

=item * only the player whose turn it is to lead may declare;

=item * the declarer must then lead one of the two cards, which is a constraint
on the following lead;

=item * B<the twenty or forty does not count until the declarer has taken a
trick>, so a marriage is held pending and folded in at that moment. A player who
declares and never takes a trick scores nothing for it.

=back

That third one is the rule most often got wrong, and it is worth knowing that it
is not implemented here.

=head2 The exchange card is the lowest trump

The trump jack in Schnapsen and the trump nine in Sixty-Six, which is in each
case the lowest trump in that pack. C<exchange_card> is told which rank to look
for rather than which game it is in.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 marriages_in

    marriages_in(\@cards, $trump);

Every marriage the hand holds, as an arrayref of
C<{ suit, value, king, queen }>, in suit order. Empty if there are none.

=head2 marriage_value

20, or 40 for the trump suit.

=head2 exchange_card

    exchange_card(\@cards, $trump, $rank);

The id of the exchange card if the hand holds it, otherwise undef.

=head2 MARRIAGE, MARRIAGE_TRUMP

20 and 40.

=head1 SEE ALSO

L<Game::Schnapsen::Deal>, L<Game::Schnapsen::Variant>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
