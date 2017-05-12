package My::Example::Role::RandomValue;
use namespace::autoclean;
use Moose::Role;

sub random_value {
    my $self = shift;
    return $_[ int rand @_ ];
}

1;
