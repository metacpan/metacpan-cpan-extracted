package Games::AlphaBeta::Reversi;
use base qw(Games::AlphaBeta::Position);
use Carp;

use strict;
use warnings;

our $VERSION = '0.1.5';

=head1 NAME

Games::AlphaBeta::Reversi - Reversi position class for use with
Games::AlphaBeta 

=head1 SYNOPSIS

    package My::Reversi;
    use base qw(Games::AlphaBeta::Reversi);

    # implement drawing routine
    sub draw { ... }

    package main;
    use My::Reversi;
    use Games::AlphaBeta;

    my ($p, $g);
    $p = My::Reversi->new;
    $g = Games::AlphaBeta->new($p);

    while ($p = $g->abmove) {
        $p->draw;
    }

=head1 DESCRIPTION

This module implements a position-object suitable for use with
L<Games::AlphaBeta>. It inherits from the
L<Games::AlphaBeta::Position> base class, so be sure to read its
documentation. The methods implemented there will not be
described here.


=head1 METHODS

=over 4

=item init()

Initialize the initial state. Call SUPER::init(@_) to do part of
the work.

=cut

sub init {
    my $self = shift;

    my $size = shift || 8;
    my $half = abs($size / 2);
    my %config = (
        player => 1,
        size => $size,
        board => undef,
    );

    # Create a blank board
    $size--;
    for my $x (0 .. $size) {
        for my $y (0 .. $size) {
            $config{board}[$x][$y] = 0;
        }
    }

    # Put initial pieces on board
    $config{board}[$size - $half][$size - $half] = 1;
    $config{board}[$half][$half] = 1;
    $config{board}[$size - $half][$half] = 2;
    $config{board}[$half][$size - $half] = 2;

    @$self{keys %config} = values %config;

    $self->SUPER::init(@_) or croak "failed to call SUPER:init()";
    return $self;
}

=item as_string

Return a plain-text representation of the current game position
as a string.

=cut

sub as_string {
    my $self = shift;

    # Header
    my ($c, $str) = "a";
    $str .= " " . $c++ for (1 .. $self->{size});
    $str  = sprintf("    %s\n", $str);
    $str .= sprintf("   +%s\n", "--" x $self->{size});

    # Actual board (with numbers down the left side)
    my $i;
    for (@{$self->{board}}) {
        for (join " ", @$_) {
            tr/012/.ox/;
            $str .= sprintf("%2d | %s\n", ++$i, $_);
        }
    }
    
    # Footer
    $str .= "Player " . $self->{player} . " to move.\n";
    return $str;
}


=item findmoves [$own_call]

Return an array of all legal moves at the current position for
the current player.

If $own_call is true, we have been recursively called by ourself
to find out if the other player could move. If neither player can
move, return undef to denote this as an ending position.
Otherwise return a pass move.

=cut

sub findmoves {
    my ($self, $own_call) = @_;

    my $b = $self->{board};
    my $size = $self->{size};
    my @moves;

    for my $x (0 .. $size - 1) {
        INNER: for my $y (0 .. $size - 1) {
            unless ($b->[$x][$y]) {
                # Define some convenient names.
                my $me      = $self->{player};
                my $not_me  = 3 - $me;

                my ($tx, $ty);

                # Check left 
                for ($tx = $x - 1; $tx >= 0 && $b->[$tx][$y] == $not_me; $tx--) {
                     ;
                }
                if ($tx >= 0 && $tx != $x - 1 && $b->[$tx][$y] == $me) {
                    push @moves, [$x, $y];
                    next INNER;
                }

                # Check right
                for ($tx = $x + 1; $tx < $size && $b->[$tx][$y] == $not_me; $tx++) {
                    ;
                }
                if ($tx < $size && $tx != $x + 1 && $b->[$tx][$y] == $me) {
                    push @moves, [$x, $y];
                    next INNER;
                }

                # Check up
                for ($ty = $y - 1; $ty >= 0 && $b->[$x][$ty] == $not_me; $ty--) {
                    ;
                }
                if ($ty >= 0 && $ty != $y - 1 && $b->[$x][$ty] == $me) {
                    push @moves, [$x, $y];
                    next INNER;
                }

                # Check down
                for ($ty = $y + 1; $ty < $size && $b->[$x][$ty] == $not_me; $ty++) {
                    ;
                }
                if ($ty < $size && $ty != $y + 1 && $b->[$x][$ty] == $me) {
                    push @moves, [$x, $y];
                    next INNER;
                }

                # Check up/left
                $tx = $x - 1;
                $ty = $y - 1;
                while ($tx >= 0 && $ty >= 0 && $b->[$tx][$ty] == $not_me) {
                    $tx--; 
                    $ty--;
                }
                if ($tx >= 0 && $ty >= 0 && $tx != $x - 1 && $ty != $y - 1 &&
                    $b->[$tx][$ty] == $me) {
                    push @moves, [$x, $y];
                    next INNER;
                }


                # Check up/right
                $tx = $x - 1;
                $ty = $y + 1;
                while ($tx >= 0 && $ty < $size && $b->[$tx][$ty] == $not_me) {
                    $tx--; 
                    $ty++;
                }
                if ($tx >= 0 && $ty < $size && $tx != $x - 1 && $ty != $y + 1 &&
                    $b->[$tx][$ty] == $me) {
                    push @moves, [$x, $y];
                    next INNER;
                }

                # Check down/right
                $tx = $x + 1;
                $ty = $y + 1;
                while ($tx < $size && $ty < $size && $b->[$tx][$ty] == $not_me) {
                    $tx++; 
                    $ty++;
                }
                if ($tx < $size && $ty < $size && $tx != $x + 1 && $ty != $y + 1 &&
                    $b->[$tx][$ty] == $me) {
                    push @moves, [$x, $y];
                    next INNER;
                }

                # Check down/left
                $tx = $x + 1;
                $ty = $y - 1;
                while ($tx < $size && $ty >= 0 && $b->[$tx][$ty] == $not_me) {
                    $tx++; 
                    $ty--;
                }
                if ($tx < $size && $ty >= 0 && $tx != $x + 1 && $ty != $y - 1 &&
                    $b->[$tx][$ty] == $me) {
                    push @moves, [$x, $y];
                    next INNER;
                }
            }
        }
    }

    # If current player cannot move, check if other player can
    # move. If she can't, the game is over. If she can, let the
    # current player do a pass move.
    unless (@moves || $own_call) {
        $self->player(3 - $self->player);
        if ($self->findmoves(1)) {
            @moves = undef;
        }
        $self->player(3 - $self->player);
    }

    return @moves;
}


=item evaluate

Evaluate a game position and return its fitness value.

=cut

sub evaluate {
    my $self = shift;
    my $player = $self->{player};
    my ($me, $not_me);

    $me = scalar $self->findmoves;
    $self->{player} = 3 - $player;
    $not_me = scalar $self->findmoves;
    $self->{player} = $player;

    return $me - $not_me;
}


=item apply $move

Apply a move to the current position, transforming it into the
next position. Return reference to itself on succes, undef on
error.

=cut

sub apply ($) {
    my ($self, $move) = @_;

    my $me      = $self->{player};
    my $not_me  = 3 - $self->{player};

    # null or pass move
    unless ($move) {
        $self->{player} = $not_me;
        return $self;
    }

    my $size    = $self->{size};
    my $b       = $self->{board};
    my ($x, $y) = @$move;

    my ($tx, $ty, $flipped);

    # slot must not be outside the board, or already occupied
    if ($x < 0 || $x >= $size || $y < 0 || $y >= $size) {
        return undef;
    }
    elsif ($b->[$x][$y]) {
        return undef;
    }

    # left
    for ($tx = $x - 1; $tx >= 0 && $b->[$tx][$y] == $not_me; $tx--) {
        ;
    }
    if ($tx >= 0 && $tx != $x - 1 && $b->[$tx][$y] == $me) {
        $tx = $x - 1;
        while ($tx >= 0 && $b->[$tx][$y] == $not_me) {
            $b->[$tx][$y] = $me;
            $tx--;
        }
        $flipped++;
    }

    # right
    for ($tx = $x + 1; $tx < $size && $b->[$tx][$y] == $not_me; $tx++) {
        ;
    }
    if ($tx < $size && $tx != $x + 1 && $b->[$tx][$y] == $me) {
        $tx = $x + 1;
        while ($tx < $size && $b->[$tx][$y] == $not_me) {
            $b->[$tx][$y] = $me;
            $tx++;
        }
        $flipped++;
    }

    # up
    for ($ty = $y - 1; $ty >= 0 && $b->[$x][$ty] == $not_me; $ty--) {
        ;
    }
    if ($ty >= 0 && $ty != $y - 1 && $b->[$x][$ty] == $me) {
        $ty = $y - 1;
        while ($ty >= 0 && $b->[$x][$ty] == $not_me) {
            $b->[$x][$ty] = $me;
            $ty--;
        }
        $flipped++;
    }
    
    # down
    for ($ty = $y + 1; $ty < $size && $b->[$x][$ty] == $not_me; $ty++) {
        ;
    }
    if ($ty < $size && $ty != $y + 1 && $b->[$x][$ty] == $me) {
        $ty = $y + 1;
        while ($ty < $size && $b->[$x][$ty] == $not_me) {
            $b->[$x][$ty] = $me;
            $ty++;
        }
        $flipped++;
    }
    
    # up/left
    $tx = $x - 1;
    $ty = $y - 1; 
    while ($tx >= 0 && $ty >= 0 && $b->[$tx][$ty] == $not_me) {
        $tx--;
        $ty--;
    }
    if ($tx >= 0 && $ty >= 0 && $tx != $x - 1 && $ty != $y - 1 && 
            $b->[$tx][$ty] == $me) {
        $tx = $x - 1;
        $ty = $y - 1;
        while ($tx >= 0 && $ty >= 0 && $b->[$tx][$ty] == $not_me) {
            $b->[$tx][$ty] = $me;
            $tx--; 
            $ty--;
        }
        $flipped++;
    }

    # up/right
    $tx = $x - 1;
    $ty = $y + 1; 
    while ($tx >= 0 && $ty < $size && $b->[$tx][$ty] == $not_me) {
        $tx--;
        $ty++;
    }
    if ($tx >= 0 && $ty < $size && $tx != $x - 1 && $ty != $y + 1 && 
            $b->[$tx][$ty] == $me) {
        $tx = $x - 1;
        $ty = $y + 1;
        while ($tx >= 0 && $ty < $size && $b->[$tx][$ty] == $not_me) {
            $b->[$tx][$ty] = $me;
            $tx--;
            $ty++;
        }
        $flipped++;
    }
    
    # down/right
    $tx = $x + 1;
    $ty = $y + 1; 
    while ($tx < $size && $ty < $size && $b->[$tx][$ty] == $not_me) {
        $tx++;
        $ty++;
    }
    if ($tx < $size && $ty < $size && $tx != $x + 1 && $ty != $y + 1 && 
            $b->[$tx][$ty] == $me) {
        $tx = $x + 1;
        $ty = $y + 1;
        while ($tx < $size && $ty < $size && $b->[$tx][$ty] == $not_me) {
            $b->[$tx][$ty] = $me;
            $tx++;
            $ty++;
        }
        $flipped++;
    }

    # down/left
    $tx = $x + 1;
    $ty = $y - 1;
    while ($tx < $size && $ty >= 0 && $b->[$tx][$ty] == $not_me) {
        $tx++;
        $ty--;
    }
    if ($tx < $size && $ty >= 0 && $tx != $x + 1 && $ty != $y - 1 && 
            $b->[$tx][$ty] == $me) {
        $tx = $x + 1;
        $ty = $y - 1;
        while ($tx < $size && $ty >= 0 && $b->[$tx][$ty] == $not_me) {
            $b->[$tx][$ty] = $me;
            $tx++;
            $ty--;
        }
        $flipped++;
    }

    unless ($flipped) {
        return undef;
    }

    $b->[$x][$y] = $me;
    $self->{player} = $not_me;

    return $self;
}

=back

=head1 BUGS

The C<findmoves()> method is too slow. This method is critical to
performance when running under Games::AlphaBeta, as more than 60%
of the execution time is spent there (when searching to ply 3).
Both the C<evaluate()> and C<endpos()> routines use
C<findmoves()> internally, so by speeding this routine up we
could gain a lot of speed.


=head1 SEE ALSO

The author's website, describing this and other projects:
L<http://brautaset.org/projects/>


=head1 AUTHOR

Stig Brautaset, E<lt>stig@brautaset.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2004 by Stig Brautaset

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

# vim: shiftwidth=4 tabstop=4 softtabstop=4 expandtab 
