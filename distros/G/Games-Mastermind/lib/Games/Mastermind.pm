package Games::Mastermind;
{
  $Games::Mastermind::VERSION = '0.06';
}

use warnings;
use strict;
use Carp;

sub new {
    my $class = shift;
    my $self  = bless {
        # blacK Blue Green Red Yellow White
        pegs  => [qw( K B G R Y W )],
        holes => 4,
        @_,
        history => [],
    }, $class;
    $self->reset;

    return $self;
}

# some quick accessors
for my $attr (qw( pegs holes code history )) {
    no strict 'refs';
    *$attr = sub {
        if( @_ > 1 ) {
            $_[0]->reset;
            $_[0]->{$attr} = $_[1];
        }
        $_[0]->{$attr};
    };
}

sub turn { scalar @{$_[0]->history}; }

sub reset {
    my $self = shift;
    my $pegs = $self->pegs;
    $self->{history} = [];    # don't use the accessors here
    $self->{code} = [ map { $pegs->[ rand @$pegs ] } 1 .. $self->holes ];
}

sub play {
    my $self  = shift;
    my @guess = @_;
    my @code  = @{ $self->code };

    croak "Not enough pegs in guess (@guess)"
      if( @guess != @code );

    my $marks = [ 0, 0 ];

    # black marks
    for my $i ( 0 .. @code - 1 ) {
        if( $guess[$i] eq $code[$i] ) {
            $marks->[0]++;
            $guess[$i] = $code[$i] = undef;
        }
    }

    # white marks
    @guess = sort grep defined, @guess;
    @code  = sort grep defined, @code;
    while( @guess && @code ) {
        if( $guess[0] eq $code[0] ) {
            $marks->[1]++;
            shift @guess;
            shift @code;
        }
        else {
            if ( $guess[0] lt $code[0] ) { shift @guess }
            else { shift @code }
        }
    }

    # copy data into history
    push @{$self->history}, [ [ @_ ], [ @$marks ] ];

    return $marks;
}

1;



=pod

=encoding iso-8859-1

=head1 NAME

Games::Mastermind - A simple framework for Mastermind games

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use Games::Mastermind;

    # the classic game
    $mm = Games::Mastermind->new;

    # make a guess
    $marks = $game->play(qw( Y C W R ));

    # results
    print "You win!\n" if $marks->[0] == $mm->holes();

    # the game history is available at all times
    $history   = $mm->history();
    $last_turn = $mm->history()->[-1];

    # reset the game
    $mm->reset();

=head1 DESCRIPTION

Games::Mastermind is a very simple framework for running Mastermind
games.

=head1 METHODS

The Games::Mastermind class provides the following methods:

=over 4

=item new( %args )

Constructor. Valid parameters are C<pegs>, a reference to the list
of available pegs and C<holes>, the number of holes in the game.

The default game is the original Mastermind:

    pegs  => [qw( B C G R Y W )]
    holes => 4

=item play( @guess )

Give the answer to C<@guess> as a reference to an array of two numbers:
the number of black marks (right colour in the right position) and
the number of white marks (right colour in the wrong position).

The winning combination is C<< [ $mm->holes(), 0 ] >>.

=item reset()

Start a new game: clear the history and compute a new code.

=item turn()

Return the move number. C<0> if the game hasn't started yet.

=back

=head2 Accessors

Accessors are available for most of the game parameters:

=over 4

=item pegs()

The list of pegs (as a reference to a list of strings).

=item holes()

The number of holes.

=item history()

Return a reference to the game history, as an array of C<[ guess, answer ]>
arrays.

=item code()

The hidden code, as a reference to the list of hidden pegs.

=back

All these getters are also setters. Note that setting any of these
parameters will automatically C<reset()> the game.

=head1 GAME API

This section describes how to interface the game with a player.

Once the game is created, for each turn, it is given a guess
and returns the outcome of this turn.

This example script show a very dumb player program:

    use Games::Mastermind;

    my $game  = Games::Mastermind->new();    # standard game
    my $holes = $game->holes();
    my @pegs  = @{ $game->pegs() };

    # simply play at random
    my $result = [ 0, 0 ];
    while ( $result->[0] != $holes ) {
        $result =
          $game->play( my @guess = map { $pegs[ rand @pegs ] } 1 .. $holes );
        print "@guess | @$result\n";
    }

The flow of control is in the hand of the player program or object,
which asks the game if the guess was good. The count of turns must
be handled by the controlling program.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-mastermind@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Mastermind>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Sébastien Aperghis-Tramoni opened his old Super Mastermind game to
check out what the black markers meant.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Mastermind or by email to
bug-games-mastermind@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2005-2013 Philippe Bruhat (BooK), All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


__END__

# ABSTRACT: A simple framework for Mastermind games

