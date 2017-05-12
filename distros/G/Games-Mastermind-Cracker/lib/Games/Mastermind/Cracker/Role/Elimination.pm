package Games::Mastermind::Cracker::Role::Elimination;
use Moose::Role;

has possibilities => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->all_codes;
    },
);

around result_of => sub {
    my $orig = shift;
    my ($self, $guess, $black, $white) = @_;

    # reset iterator
    keys %{ $self->possibilities };

    while (my $code = each %{ $self->possibilities }) {
        my ($b, $w) = $self->score($guess, $code);
        delete $self->possibilities->{$code}
            unless $b == $black && $w == $white;
    }

    $orig->(@_);
};

around make_guess => sub {
    my $orig = shift;
    my ($self) = @_;

    if (keys %{ $self->possibilities } == 1) {
        my ($correct) = keys %{ $self->possibilities };
        return \$correct;
    }

    $orig->(@_);
};

1;

