package Example::Construction::Acme::Counter_v2;

use Mic::Impl
    has  => {
        COUNT => { },
    }, 
;

sub BUILD {
    my ($self, $arg) = @_;

    $self->[COUNT] = $arg->{start};
}

sub next {
    my ($self) = @_;

    $self->[COUNT]++;
}

1;
