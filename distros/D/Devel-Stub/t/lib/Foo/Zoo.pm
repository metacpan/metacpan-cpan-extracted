package Foo::Zoo;

sub new {
    my $class = shift;
    bless {},$class;
}

sub zoo {
    my $self = shift;
    $self->{zoo};
}

1;