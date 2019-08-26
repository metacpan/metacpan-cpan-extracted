use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lut

=usage

  my $lut = $registry->lut($key);

=description

Returns the lookup table for a given namespace.

=signature

lut(Str $arg1) : ArrayRef

=type

method

=cut

# TESTING

use_ok 'Data::Object::Registry';

my $data = Data::Object::Registry->new();

is_deeply $data->lut(), [];

ok 1 and done_testing;
