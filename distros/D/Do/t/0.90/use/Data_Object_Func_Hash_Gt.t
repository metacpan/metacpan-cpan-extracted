use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Gt

=abstract

Data-Object Hash Function (Gt) Class

=synopsis

  use Data::Object::Func::Hash::Gt;

  my $func = Data::Object::Func::Hash::Gt->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Gt is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Gt';

ok 1 and done_testing;
