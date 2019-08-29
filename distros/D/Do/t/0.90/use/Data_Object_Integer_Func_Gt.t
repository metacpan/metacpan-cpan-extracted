use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Integer::Func::Gt

=abstract

Data-Object Integer Function (Gt) Class

=synopsis

  use Data::Object::Integer::Func::Gt;

  my $func = Data::Object::Integer::Func::Gt->new(@args);

  $func->execute;

=description

Data::Object::Integer::Func::Gt is a function object for Data::Object::Integer.

=cut

# TESTING

use_ok 'Data::Object::Integer::Func::Gt';

ok 1 and done_testing;
