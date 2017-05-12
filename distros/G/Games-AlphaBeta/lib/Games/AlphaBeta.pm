package Games::AlphaBeta;
use base qw(Games::Sequential);

use Carp;
use 5.006001;

use strict;
use warnings;


our $VERSION = '0.4.7';

=head1 NAME

Games::AlphaBeta - game-tree search with object oriented interface

=head1 SYNOPSIS

    package My::GamePos;
    use base qw(Games::AlphaBeta::Position);

    # initialise starting position
    sub _init { ... }

    # Methods required by Games::AlphaBeta
    sub apply { ... }
    sub endpos { ... }          # optional
    sub evaluate { ... }
    sub findmoves { ... }

    # Draw a position in the game (optional)
    sub draw { ... }

    package main;
    my $pos = My::GamePos->new;
    my $game = Games::AlphaBeta->new($pos);

    while ($game->abmove) {
        print draw($game->peek_pos);
    }

=head1 DESCRIPTION

Games::AlphaBeta provides a generic implementation of the
AlphaBeta game-tree search algorithm (also known as MiniMax
search with alpha beta pruning). This algorithm can be used to
find the best move at a particular position in any two-player,
zero-sum game with perfect information. Examples of such games
include Chess, Othello, Connect4, Go, Tic-Tac-Toe and many, many
other boardgames. 

Users must pass an object representing the initial state of the
game as the first argument to C<new()>. This object must provide
the following methods: C<copy()>, C<apply()>, C<endpos()>,
C<evaluate()> and C<findmoves()>. This is explained more
carefully in L<Games::AlphaBeta::Position> which is a base class
you can use to implement your position object.

=head1 INHERITED METHODS

The following methods are inherited from L<Games::Sequential>:

=over

=item new

=item debug 

=item peek_pos

=item peek_move

=item move 

=item undo

=back

=head1 METHODS

=over 

=item _init [@list]

I<Internal method.>

Initialize an AlphaBeta object.

=cut

sub _init {
    my $self = shift;
    my %config = (
        # Runtime variables
        ply         => 2,       # default search depth
        alpha       => -100_000,
        beta        => 100_000,
    );

    @$self{keys %config} = values %config;
    $self->SUPER::_init(@_);

    my $pos = $self->peek_pos;
    croak "no endpos() method defined" unless $pos->can("endpos");
    croak "no evaluate() method defined" unless $pos->can("evaluate");
    croak "no findmoves() method defined" unless $pos->can("findmoves");

    return $self;
}


=item ply [$value]

Return current default search depth and, if invoked with an
argument, set to new value.

=cut

sub ply {
    my $self = shift;
    my $prev = $self->{ply};
    $self->{ply} = shift if @_;
    return $prev;
}


=item abmove [$ply]

Perform the best move found after an AlphaBeta game-tree search
to depth $ply. If $ply is not specified, the default depth is
used (see C<ply()>). The best move found is performed and a
reference to the resulting position is returned on success, and
undef is returned on failure.

Note that this function can take a long time if $ply is high,
particularly if the game in question has many possible moves at
each position.

If C<debug()> is set, some basic debugging is printed as the
search progresses.

=cut

sub abmove {
    my $self = shift;
    my $ply;

    if (@_) {
        $ply = shift;
        print "Explicit ply $ply overrides default ($self->{ply})\n" if $self->{debug};
    }
    else {
        $ply = $self->{ply};
    }

    my (@moves, $bestmove);
    my $bestmove_valid = 0;
    my $pos = $self->peek_pos;

    return if $pos->endpos;
    return unless @moves = $pos->findmoves;

    my $alpha = $self->{alpha};
    my $beta = $self->{beta};

    print "Searching to depth $ply\n" if $self->{debug};
    $self->{found_end} = $self->{count} = 0;
    for my $move (@moves) {
        my ($npos, $sc);
        $npos = $pos->copy;
        $npos->apply($move) or croak "apply() failed";
        $sc = -$self->_alphabeta($npos, -$beta, -$alpha, $ply - 1);

        print "ab val: $sc" if $self->{debug};
        if ($sc > $alpha) {
            print " > $alpha new best move" if $self->{debug};
            $bestmove_valid = 1;
            $bestmove = $move;
            $alpha = $sc;
        }
        print "\n" if $self->{debug};
    }
    print "$self->{count} visited\n" if $self->{debug};

    return unless $bestmove_valid;
    return $self->move($bestmove);
}


=item _alphabeta $pos $alpha $beta $ply

I<Internal method.>

=cut

sub _alphabeta {
    my ($self, $pos, $alpha, $beta, $ply) = @_;
    my @moves;

    # Keep count of the number of positions we've seen
    $self->{count}++;

    # When using iterative deepening we can optimise for the case
    # when we find an end position at every branch (for example,
    # near the end of the game)
    #
    if ($pos->endpos) {
        $self->{found_end}++;
        return $pos->evaluate;
    }
    elsif ($ply <= 0) {
        return $pos->evaluate;
    }

    unless (@moves = $pos->findmoves) {
        $self->{found_end}++;
        return $pos->evaluate;
    }

    for my $move (@moves) {
        my ($npos, $sc);
        $npos = $pos->copy or croak "$pos->copy() failed";
        $npos->apply($move) or croak "$pos->apply() failed";

        $sc = -$self->_alphabeta($npos, -$beta, -$alpha, $ply - 1);

        $alpha = $sc if $sc > $alpha;
        last unless $alpha < $beta;
    }

    return $alpha;
}


1;  # ensure using this module works
__END__

=back


=head1 BUGS

The valid range of values C<evaluate()> can return is hardcoded to
-99_999 - +99_999 at the moment. Probably should provide methods
to get/set these.


=head1 TODO

Implement the missing iterative deepening alphabeta routine. 


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
