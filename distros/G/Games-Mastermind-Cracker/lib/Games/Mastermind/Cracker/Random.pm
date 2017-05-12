package Games::Mastermind::Cracker::Random;
use Moose;
extends 'Games::Mastermind::Cracker';

sub make_guess {
    my $self = shift;
    join '', map { $self->random_peg } 1 .. $self->holes;
}

1;

__END__

=head1 NAME

Games::Mastermind::Cracker::Random - make completely random guesses

=cut

