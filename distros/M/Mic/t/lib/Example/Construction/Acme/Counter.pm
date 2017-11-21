package Example::Construction::Acme::Counter;

use Mic::Impl
    has  => {
        COUNT => { init_arg => 'start' },
    }, 
;

sub next {
    my ($self) = @_;

    $self->[COUNT]++;
}

1;
