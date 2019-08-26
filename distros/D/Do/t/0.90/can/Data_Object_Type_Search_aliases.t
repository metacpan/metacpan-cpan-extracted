use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

aliases

=usage

  my $aliases = $self->aliases();

=description

The aliases method returns aliases to register in the type library.

=signature

aliases() : ArrayRef

=type

method

=cut

# TESTING

use_ok 'Data::Object::Type::Search';

my $data = Data::Object::Type::Search->new();

is_deeply $data->aliases(), ['SearchObj','SearchObject'];

ok 1 and done_testing;
