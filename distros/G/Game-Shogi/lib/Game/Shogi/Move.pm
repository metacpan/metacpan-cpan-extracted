package Game::Shogi::Move;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

our $VERSION = '0.01';

my $BOARD = qr/\A([1-9][a-i])([1-9][a-i])(\+?)\z/;
my $DROP  = qr/\A([PLNSGBR])\*([1-9][a-i])\z/;

has usi => (is => 'ro');

sub BUILD {
    my ($self) = @_;
    my $usi = $self->usi;
    Carp::croak("Game::Shogi::Move: '" . ($usi // 'undef') . "' is not a USI move")
        unless defined $usi && ($usi =~ $BOARD && $1 ne $2 || $usi =~ $DROP);
    return;
}

sub of {
    my ($class, $usi) = @_;
    return undef unless defined $usi && ($usi =~ $BOARD && $1 ne $2 || $usi =~ $DROP);
    return $class->new(usi => $usi);
}

sub of_parts {
    my ($class, %part) = @_;
    my $usi = defined $part{drop}
        ? ($part{drop} // '') . '*' . ($part{to} // '')
        : ($part{from} // '') . ($part{to} // '') . ($part{promote} ? '+' : '');
    return $class->of($usi);
}

sub is_drop { $_[0]->usi =~ /\*/ ? 1 : 0 }
sub drop    { $_[0]->usi =~ $DROP ? $1 : undef }
sub from    { $_[0]->usi =~ $BOARD ? $1 : undef }
sub to      { $_[0]->usi =~ $BOARD ? $2 : ($_[0]->usi =~ $DROP)[1] }
sub promote { $_[0]->usi =~ /\+\z/ ? 1 : 0 }

1;

__END__

=head1 NAME

Game::Shogi::Move - a shogi move as a value

=head1 SYNOPSIS

    my $m = Game::Shogi::Move->of('8h2b+');
    print $m->from, ' ', $m->to, ' ', $m->promote, "\n";   # 8h 2b 1

    my $d = Game::Shogi::Move->of_parts(drop => 'P', to => '5e');
    print $d->usi, "\n";                                    # P*5e

=head1 DESCRIPTION

A move as USI writes it, and its parts. It says nothing about whether the move
is legal anywhere: that is the board's question.

=head1 CONSTRUCTORS

=head2 new

    Game::Shogi::Move->new(usi => '7g7f')

Croaks when the string is not a USI move.

=head2 of

    Game::Shogi::Move->of($usi)

The move, or C<undef> when the string is not one.

=head2 of_parts

    Game::Shogi::Move->of_parts(from => '7g', to => '7f', promote => 0)
    Game::Shogi::Move->of_parts(drop => 'P', to => '5e')

The move from its parts, or C<undef>.

=head1 ATTRIBUTES

=head2 usi

The move as USI writes it: C<7g7f>, C<8h2b+>, C<P*5e>.

=head1 METHODS

=head2 from

The square a board move leaves, or C<undef> for a drop.

=head2 to

The square the move reaches.

=head2 promote

True when a board move promotes.

=head2 drop

The piece a drop puts down, in capitals, or C<undef> for a board move.

=head2 is_drop

True for a drop.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
