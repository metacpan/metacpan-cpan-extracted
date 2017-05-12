package Games::Mastermind::Cracker;
use Moose;

our $VERSION = '0.03';

has holes => (
    is      => 'ro',
    isa     => 'Int',
    default => 4,
);

has pegs => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [qw/K B G R Y W/] },
);

has history => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has get_result => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub { sub {
        my $self = shift;
        my $guess = shift;
        print "Guessing $guess. How many black and white pegs? ";
        local $_ = <>;

        # if < 10 holes, then no separator necessary
        if ($self->holes < 10) {
            return /(\d).*?(\d)/;
        }

        return /(\d+)\D+(\d+)/;
    }},
);

# repeatedly prompt the user until we get realistic input
sub play {
    my $self  = shift;
    my $guess = shift;
    my ($black, $white);

    do {
        do {
            ($black, $white) = $self->get_result->($self, $guess);
        }
        until defined $black && defined $white;
    }
    until $black + $white <= $self->holes;

    return ($black, $white);
}

# go from zero to solution
sub crack {
    my $self = shift;

    while (1) {
        my $guess = $self->make_guess;

        # no solution found
        return undef if !defined($guess);

        # solution found
        return $$guess if ref($guess);

        my ($black, $white) = $self->play($guess);

        return $guess
            if $black == $self->holes;

        push @{ $self->history }, [$guess, $black, $white];

        $self->result_of($guess, $black, $white);
    }
}

# don't let the user instantiate this directly
around new => sub {
    my $orig  = shift;
    my $class = shift;
    $class = blessed($class) || $class;

    if ($class eq 'Games::Mastermind::Cracker') {
        confess "You must choose a subclass of Games::Mastermind::Cracker. I recommend Games::Mastermind::Cracker::Sequential.";
    }

    $orig->($class, @_);
};

# callback to let the cracker module know how he did
sub result_of { }

# the meat of the cracker modules
sub make_guess {
    confess "Your subclass must override make_guess.";
}

# auxiliary methods

sub last_guess {
    my $self = shift;

    my $last = $self->history->[-1];

    return undef if !defined($last);
    return $last->[0];
}

sub random_peg {
    my $self = shift;

    return $self->pegs->[rand @{$self->pegs}];
}

sub all_codes {
    my $self = shift;

    my $possibilities = {};

    my @pegs  = @{ $self->pegs };
    my $holes = $self->holes;

    # generate all holes-length permutations of @pegs recursively
    my $generate;
    $generate = sub {
        my $p = shift;
        my $len = 1 + shift;

        if ($len == $holes) {
            $possibilities->{$p . $_} = 1 for @pegs;
        }
        else {
            $generate->($p . $_, $len) for @pegs;
        }
    };

    # start this baby off
    $generate->('', 0);

    return $possibilities;
}

sub score {
    my $self  = shift;
    my @guess = split '', shift;
    my @code  = split '', shift;

    my $black = 0;
    my $white = 0;

    no warnings 'uninitialized';

    # code stolen from Games::Mastermind

    # black marks
    for my $i (0 .. @code - 1) {
        if ($guess[$i] eq $code[$i]) {
            ++$black;
            $guess[$i] = $code[$i] = undef;
        }
    }

    # white marks
    @guess = sort grep { defined } @guess;
    @code  = sort grep { defined } @code;

    while (@guess && @code) {
        if ($guess[0] eq $code[0]) {
            $white++;
            shift @guess;
            shift @code;
        }
        else {
            if ($guess[0] lt $code[0]) { shift @guess }
            else                       { shift @code  }
        }
    }

    return ($black, $white);
}

1;

=head1 NAME

Games::Mastermind::Cracker - quickly crack Mastermind

=head1 SYNOPSIS

    use Games::Mastermind::Cracker::Sequential;
    my $cracker = Games::Mastermind::Cracker::Sequential->new();
    printf "The solution is %s!\n", $cracker->cracker;

=head1 DESCRIPTION

Mastermind is a code-breaking game played by two players, the "code maker" and
the "code breaker".

This module plays the role of code breaker. The only requirement is that you
provide the answers to how many black pegs and how many white pegs a code
gives.

You must instantiate a subclass of this module to actually break codes. There
are a number of different cracker modules, described in L</ALGORITHMS>.

L<Games::Mastermind> is the same game, except it plays the role of code maker.

=head1 ALGORITHMS

Here are the algorithms, in roughly increasing order of quality.

=head2 L<Games::Mastermind::Cracker::Random>

This randomly guesses until it gets the right answer. It does not attempt to
avoid guessing the same code twice.

=head2 L<Games::Mastermind::Cracker::Sequential>

This guesses each code in order until it gets the right answer. It uses no
information from the results to prepare its next guesses.

=head2 L<Games::Mastermind::Cracker::Basic>

This is the first usable algorithm. It will keep track of all the possible
codes. When a result is known, it will go through the possible codes and
eliminate any result inconsistent with the result. For example, C<BBBB> is not
a possible result when C<WKYW> is guessed and receives a result of 1 black.
This is because C<WKYW> would not score 1 black if the correct code is
C<BBBB>.

=head1 USAGE

=head2 C<new>

Creates a new L<Games::Mastermind::Cracker::*> object. Note that you MUST
instantiate a subclass of this module. C<new> takes a number of arguments:

=head3 C<holes>

The number of holes. Default: 4.

=head3 C<pegs>

The representations of the pegs. Default: 'K', 'B', 'G', 'R', 'Y', 'W'.

=head3 C<get_result>

A coderef to call any time the module wants user input. It passes the coderef
C<$self> and the string of the guess (e.g. C<KRBK>) and expects to receive two
numbers, C<black pegs> and C<white pegs>, as return value. I will call this
method multiple times if necessary to get sane output, so you don't need to do
much processing.

The default queries the user through standard output and standard input.

=head2 C<crack>

The method to call to crack a particular game of Mastermind. This takes no
arguments. It returns the solution as a string, or C<undef> if no solution
could be found.

=head2 C<holes>

This will return the number of holes used in the game.

=head2 C<pegs>

This will return an array reference of the pegs used in the game.

=head2 C<history>

This will return an array reference of the guesses made so far in the game.
Each item in C<history> is an array refrence itself, containing the guess, its
black pegs, and its white pegs.

=head1 SUBCLASSING

This module uses L<Moose> so please use it to extend this module. C<:)>

Your cracker should operate such that any update to its internal state is caused
by C<result_of>, not C<make_guess>. This is because your C<result_of> method
may be called (multiple times) before C<make_guess> is first called.

If you absolutely have to entangle your guessing and result processing code,
one way to make this work is to have C<result_of> do all the calculation and
store the next guess to make in an attribute.

=head2 REQUIRED METHODS

=head3 make_guess

This method will receive no arguments, and expects a string representing the
guessed code as a result. If your C<make_guess> returns C<undef>, that will be
interpreted as "unable to crack this code." If your C<make_guess> returns a
scalar reference, that will be interpreted as the correct solution.

=head2 OPTIONAL METHODS

=head3 result_of

This method will receive three arguments: the guess made, the number of black
pegs, and the number of white pegs. It doesn't have to return anything.

=head2 HELPER METHODS

=head3 last_guess

This returns the last code guessed, or C<undef> if no code has been guessed
yet.

=head3 random_peg

This returns a peg randomly selected from valid pegs.

=head3 all_codes

This returns a hash reference of all possible codes. This is not cached in any
way, so each call is a large speed penalty.

=head3 score

This expects two codes. It will return the black and white marker count as if
the first is a guess against the second. (actually, this method is associative,
so you could say the second against the first C<:)>).

=head1 SEE ALSO

L<Games::Mastermind>, L<Games::Mastermind::Solver>

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

