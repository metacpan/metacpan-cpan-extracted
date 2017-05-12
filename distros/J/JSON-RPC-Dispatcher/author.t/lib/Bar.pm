package Bar;

use Moose;
extends 'Foo';

sub concat_with_spaces {
    my ($self, @params) = @_;
    return join " ", @params;
}

sub rpc_method_names {
    my ($self) = @_;
    return [$self->_rpc_method_names];
}


__PACKAGE__->register_rpc_method_names( qw( concat_with_spaces rpc_method_names ) );

1;
