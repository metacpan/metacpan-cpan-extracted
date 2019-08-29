use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Clear

=abstract

Data-Object Hash Function (Clear) Class

=synopsis

  use Data::Object::Hash::Func::Clear;

  my $func = Data::Object::Hash::Func::Clear->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Clear is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Clear';

ok 1 and done_testing;
