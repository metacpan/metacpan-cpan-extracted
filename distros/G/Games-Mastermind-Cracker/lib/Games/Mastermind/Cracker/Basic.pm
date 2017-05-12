package Games::Mastermind::Cracker::Basic;
use Moose;

extends 'Games::Mastermind::Cracker';
with 'Games::Mastermind::Cracker::Role::Elimination';

sub make_guess {
    my $self = shift;

    # reset iterator
    keys %{ $self->possibilities };

    # return an arbitrary possibility
    return scalar each %{ $self->possibilities };
}

sub result_of { }

1;

__END__

=head1 NAME

Games::Mastermind::Cracker::Basic - guess arbitrary possible codes

=cut

