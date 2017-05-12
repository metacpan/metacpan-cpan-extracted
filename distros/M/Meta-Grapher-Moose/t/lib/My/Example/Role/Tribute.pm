package My::Example::Role::Tribute;
use namespace::autoclean;
use MooseX::Role::Parameterized;

parameter grohl => (
    isa => 'Bool',
);

role {
    my $p = shift;

    ## no critic (Moose::ProhibitMultipleWiths)
    if ( $p->{grohl} ) {
        with 'My::Example::Role::JackBlack';
    }
    else {
        with 'My::Example::Role::Katniss';
    }
};

1;
