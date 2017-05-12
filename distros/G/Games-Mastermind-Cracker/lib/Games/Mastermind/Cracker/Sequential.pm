package Games::Mastermind::Cracker::Sequential;
use Moose;
extends 'Games::Mastermind::Cracker';

sub make_guess {
    my $self = shift;
    my $last_guess = $self->last_guess;

    return $self->pegs->[0] x $self->holes
        if !defined($last_guess);

    my $guess = $self->increment_guess($last_guess);

    # if it's the final possibility, then yes, damnit.
    if ($guess eq $self->pegs->[-1] x $self->holes) {
        return \$guess;
    }

    return $guess;
}

sub increment_guess {
    my $self  = shift;
    my $guess = shift;

    # map peg to number
    my $pegs = 0;
    my %number_of = map { $_ => ++$pegs } @{ $self->pegs };

    # convert the guess to an array of numbers
    my @guess = map { $number_of{$_} } split '', $guess;

    # increment guess, return undef if we're at the top guess
    $guess[-1]++;
    for (my $i = @guess - 1; $i >= 0; --$i) {
        if ($guess[$i] > $pegs) {
            return undef if $i == 0; # top
            $guess[$i-1]++;
            $guess[$i] = 1;
        }
        else {
            last;
        }
    }

    return join '', map { $self->pegs->[$_-1] } @guess;
}

1;

__END__

=head1 NAME

Games::Mastermind::Cracker::Sequential - guess every code in order

=cut

