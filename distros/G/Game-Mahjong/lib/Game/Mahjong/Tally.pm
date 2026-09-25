package Game::Mahjong::Tally;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

has points => (is => 'ro', isa => Int, required => 1);

has basic => (is => 'ro', isa => Int, required => 1);

has flowers => (is => 'ro', isa => Int, default => 0);

has fans => (is => 'ro', isa => ArrayRef, default => []);

has split => (is => 'ro');

has minimum_met => (is => 'ro', default => 0);

sub keys_of { return map { $_->{key} } @{ $_[0]->fans } }

sub has_fan {
	my ($self, $key) = @_;
	for my $f (@{ $self->fans }) { return $f->{times} if $f->{key} eq $key }
	return 0;
}

sub describe {
	my ($self) = @_;
	return join(', ', map { $_->{name} . ($_->{times} > 1 ? " x$_->{times}" : '') . " ($_->{total})" } @{ $self->fans })
		. ' = ' . $self->points;
}

1;

__END__

=head1 NAME

Game::Mahjong::Tally - what a winning hand scored, and how

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $tally = Game::Mahjong::Score::score($hand, $winning, \%ctx);
    $tally->points;        # 91, flowers included
    $tally->basic;         # 91, without flowers: what the minimum reads
    $tally->minimum_met;   # 1
    $tally->fans;          # [ { key, name, points, times, total }, ... ], highest first
    $tally->has_fan('big_four_winds');   # 1

=head1 DESCRIPTION

The scorer's answer for one hand: the fans that counted after the five
principles, each with how many times it counted and what that came to, the
split the maximum was found in, the flowers, and whether the eight-point
minimum was met without them.

=head1 ATTRIBUTES

=head2 points

The total, flowers included.

=head2 basic

The total without flowers, which the minimum is tested against (3.11.6.6).

=head2 flowers

How many flower points were added.

=head2 fans

The fans that scored, highest first: C<< { key, name, points, times, total } >>.

=head2 split

The decomposition the maximum came from, with its placement.

=head2 minimum_met

Whether C<basic> reaches L<Game::Mahjong::Score>'s C<MINIMUM>.

=head1 METHODS

=head2 keys_of

The fan keys, in order.

=head2 has_fan

How many times a fan counted, 0 if it did not.

=head2 describe

One line, for the terminal.

=head1 SEE ALSO

L<Game::Mahjong::Score>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
