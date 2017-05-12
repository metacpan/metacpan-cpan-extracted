use strict;
use warnings;
package SimpleFlagSetter;

use Moose;
with 'Dist::Zilla::Role::MetaProvider';
use namespace::autoclean;

has value => (
    is => 'ro', isa => 'Bool',
    predicate => '_has_value',
);
sub metadata
{
    my $self = shift;

    return +{} if not $self->_has_value;
    return +{ x_static_install => ($self->value ? 1 : 0) };
}

1;
