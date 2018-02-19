package Example::Overloads::HashSet;

use Mic::Impl
    has => { SET => { default => sub { {} } } },
;

sub has {
    my ($self, $e) = @_;
    exists $self->[SET]{$e};
}

sub add {
    my ($self, $e) = @_;
    ++$self->[SET]{$e};
}

sub to_str {
    my ($self) = @_;
    
    sprintf '{%s}', join ', ' => keys %{ $self->[SET] };
}

1;
