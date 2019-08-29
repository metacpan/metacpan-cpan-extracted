use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Any::Func::Lt

=abstract

Data-Object Any Function (Lt) Class

=synopsis

  use Data::Object::Any::Func::Lt;

  my $func = Data::Object::Any::Func::Lt->new(@args);

  $func->execute;

=description

Data::Object::Any::Func::Lt is a function object for Data::Object::Any.

=cut

# TESTING

use_ok 'Data::Object::Any::Func::Lt';

ok 1 and done_testing;
