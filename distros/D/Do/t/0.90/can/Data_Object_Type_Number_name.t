use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

name

=usage

  my $name = $self->name();

=description

The name method returns the name of the data type.

=signature

name() : StrObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type::Number';

my $data = Data::Object::Type::Number->new();

is_deeply $data->name(), 'DoNum';

ok 1 and done_testing;
