package My::Example::Role::ShedColor;
use namespace::autoclean;
use MooseX::Role::Parameterized;

parameter default_color => (
    isa      => 'Str',
    required => 1,
);

parameter enable_painting => (
    isa => 'Bool',
);

role {
    my $p = shift;

    has color => (
        is      => 'ro',
        isa     => 'Str',
        default => $p->default_color,
    );

    if ( $p->enable_painting ) {
        ## no critic (ControlStructures::ProhibitYadaOperator)
        method paint => sub {
            return;
        };
    }
};

1;
