package Example::Construction::Acme::CounterWithNew;

use Mic::Impl
    has  => {
        COUNT => { },
    }, 
    classmethod => ['new'],
;

sub next {
    my ($self) = @_;

    $self->[ $COUNT ]++;
}

sub new {
    my ($class, $start) = @_;

    my $builder = Mic::builder_for($class);
    my $obj = $builder->new_object({COUNT => $start});
    return $obj;
};

1;
