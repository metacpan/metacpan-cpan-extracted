package LIVRContractSimpleClassExample;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use LIVR::Contract;

contract 'create_object_named_input' => (
    requires => {
        name => [ 'required' ],
        id   => [ 'required', 'positive_integer' ]
    },
    ensures => {
        0 => [ 'required', 'positive_integer' ]
    }
);

contract 'create_object_positional_input' => (
    requires => {
        1 => [ 'required', 'positive_integer' ],
        2 => [ 'required' ],
    },
    ensures => {
        0 => [ 'required', 'positive_integer' ]
    }
);

sub create_object_named_input {
    my ( $class, %args ) = @_;

    return {
        name => $args{name},
        id   => $args{id}
    };
}

sub create_object_positional_input {
    my ( $class, $id, $name ) = @_;

    return {
        id   => $id,
        name => $name,
    };
}

1;
