package Example::Construction::Acme::Set_v2;

use Mic::Impl
    has => { 
        SET => { 
            default => sub { {} },
        } 
    },
;

sub BUILD {
    my ($self, $args) = @_;

    $self->[SET] = { map { $_ => 1 } @{ $args } };
}

sub has {
    my ($self, $e) = @_;

    exists $self->[SET]{$e};
}

sub add {
    my ($self, $e) = @_;

    ++$self->[SET]{$e};
}

sub size {
    my ($self) = @_;
    scalar(keys %{ $self->[SET] });
}

1;
