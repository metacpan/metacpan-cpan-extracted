package My::Example::Role::PickRandom;
use namespace::autoclean;
use MooseX::Role::Parameterized;

with 'My::Example::Role::RandomValue';

parameter name => (
    isa      => 'Str',
    required => 1,
);

parameter values => (
    isa      => 'ArrayRef',
    required => 1,
);

role {
    my $p = shift;

    method $p->{name} => sub {
        my $self = shift;
        return $self->random_value( @{ $p->{values} } );
    };
};

1;
