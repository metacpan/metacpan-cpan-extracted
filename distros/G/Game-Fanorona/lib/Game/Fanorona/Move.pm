package Game::Fanorona::Move;

use 5.014;
use strict;
use warnings;

use Object::Proto::Sugar;

our $VERSION = '0.01';

has from => (is => 'ro');

has steps => (is => 'ro', default => sub { [] });

sub to {
    my ($self) = @_;
    my $steps = $self->steps;
    return @$steps ? $steps->[-1]{to} : undef;
}

sub length {
    my ($self) = @_;
    return scalar @{ $self->steps };
}

sub taken {
    my ($self) = @_;
    return map { @{ $_->{taken} } } @{ $self->steps };
}

sub is_paika {
    my ($self) = @_;
    my $steps = $self->steps;
    return @$steps == 1 && !@{ $steps->[0]{taken} } ? 1 : 0;
}

sub points {
    my ($self) = @_;
    return ($self->from, map { $_->{to} } @{ $self->steps });
}

1;

__END__

=head1 NAME

Game::Fanorona::Move - one whole move: a stone, its steps, and what each took

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Fanorona::Engine ':all';

    my $board = Game::Fanorona::Engine->new;
    for my $move ($board->moves) {
        printf "from %d, %d step(s), %d stone(s) taken\n",
            $move->from, $move->length, scalar($move->taken);
    }

=head1 DESCRIPTION

Everything one side does before the other plays. A move is either a single
step that takes nothing, a B<paika>, or a B<chain>: one or more steps by the
same stone, every one of which takes.

A chain may be stopped after any of its steps. So where a stone could take
three times running, taking once, taking twice and taking three times are
three different moves, and L<Game::Fanorona::Engine/moves> lists all three.

A move is a value. It is made by the engine and holds no board; playing it is
L<Game::Fanorona::Engine/play_move>.

=head1 METHODS

=head2 from

The point the stone starts on.

=head2 to

The point it ends on.

=head2 steps

An array reference of the steps, in order. Each is the hash
L<Game::Fanorona::Engine/"A step"> describes: C<from>, C<to>, C<dir>, C<kind>
and C<taken>.

=head2 length

How many steps: 1 for a paika.

=head2 taken

Every point a stone was taken from, in the order they went.

=head2 is_paika

True for a move that takes nothing.

=head2 points

Every point the stone stands on, the start first.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
