package Game::Mahjong::Fan;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

has n => (is => 'ro', isa => Int, required => 1);

has key => (is => 'ro', isa => Str, required => 1);

has name => (is => 'ro', isa => Str, required => 1);

has points => (is => 'ro', isa => Int, required => 1);

has says => (is => 'ro', isa => Str, required => 1);

has excludes => (is => 'ro', isa => ArrayRef, default => []);

has implies => (is => 'ro', isa => ArrayRef, default => []);

has check => (is => 'ro', required => 1);

has special => (is => 'ro');

has combining => (is => 'ro', default => 0);

has whole => (is => 'ro', default => 0);

sub instances {
	my ($self, $view) = @_;
	return $self->check->($view);
}

sub times {
	my ($self, $view) = @_;
	my @i = $self->instances($view);
	return scalar @i;
}

1;

__END__

=head1 NAME

Game::Mahjong::Fan - one scoring element: its number, points, sentence and checker

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $fan = Game::Mahjong::Fans::by_key('mixed_triple_chow');
    $fan->n;          # 41
    $fan->points;     # 8
    $fan->says;       # the rulebook's sentence
    my @found = $fan->instances($view);   # each { sets => [indices] }

=head1 DESCRIPTION

A row of the eighty-one. The checker reads a view of one split of a hand
(L<Game::Mahjong::Fans/view>) and returns every instance of the fan it
finds, each naming the sets it used, so the scorer can apply the
account-once principle to the set-based fans and count the ones that
score more than once (a flower, a pung of terminals) as many times as they
occur.

=head1 ATTRIBUTES

=head2 n

The rulebook's number, 1 to 81.

=head2 key

The snake_case key the site's catalogue and the log use.

=head2 name

The rulebook's English name.

=head2 points

88, 64, 48, 32, 24, 16, 12, 8, 6, 4, 2 or 1.

=head2 says

The rulebook's sentence, verbatim, which C<xt/fans-cited.t> finds in the
fetched text.

=head2 excludes

Keys this fan does not combine with, transcribed from Appendix 1.

=head2 implies

Keys this fan inevitably includes, which the non-repeat principle drops.

=head2 check

The checker, a code reference taking a view.

=head2 special

Set for a fan the scorer applies itself rather than through the checker
(Chicken Hand).

=head2 combining

1 for a fan made by combining two or more sets (the double and triple
chows and pungs, the straights, the shifted runs, the four-set patterns):
the account-once principle counts the sets these use. A fan that describes
the whole hand (All Chows, Outside Hand) lists its sets for information and
consumes none.

=head2 whole

1 for a fan that describes every set of the hand (All Pungs, All Chows,
Outside Hand, All Types, and so on): true of a complete hand or not at all,
so the bot's floor, which sees only the melds, never counts it.

=head1 METHODS

=head2 instances

The instances found in a view, each C<< { sets => [indices], points =>
optional override } >>.

=head2 times

How many instances.

=head1 SEE ALSO

L<Game::Mahjong::Fans>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
