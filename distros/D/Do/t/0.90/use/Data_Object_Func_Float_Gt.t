use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Float::Gt

=abstract

Data-Object Float Function (Gt) Class

=synopsis

  use Data::Object::Func::Float::Gt;

  my $func = Data::Object::Func::Float::Gt->new(@args);

  $func->execute;

=description

Data::Object::Func::Float::Gt is a function object for Data::Object::Float.

=cut

# TESTING

use_ok 'Data::Object::Func::Float::Gt';

ok 1 and done_testing;
