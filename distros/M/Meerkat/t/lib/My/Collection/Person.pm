use strict;
use warnings;

package My::Collection::Person;

use Moose 2;
extends 'Meerkat::Collection';

sub find_name {
    my ( $self, $name ) = @_;
    return $self->find_one( { name => $name } );
}

1;

