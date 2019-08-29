use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Invert

=abstract

Data-Object Hash Function (Invert) Class

=synopsis

  use Data::Object::Hash::Func::Invert;

  my $func = Data::Object::Hash::Func::Invert->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Invert is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Invert';

ok 1 and done_testing;
