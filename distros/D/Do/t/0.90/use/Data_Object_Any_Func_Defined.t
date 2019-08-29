use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Any::Func::Defined

=abstract

Data-Object Any Function (Defined) Class

=synopsis

  use Data::Object::Any::Func::Defined;

  my $func = Data::Object::Any::Func::Defined->new(@args);

  $func->execute;

=description

Data::Object::Any::Func::Defined is a function object for Data::Object::Any.

=cut

# TESTING

use_ok 'Data::Object::Any::Func::Defined';

ok 1 and done_testing;
