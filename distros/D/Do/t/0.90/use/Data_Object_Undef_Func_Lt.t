use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Undef::Func::Lt

=abstract

Data-Object Undef Function (Lt) Class

=synopsis

  use Data::Object::Undef::Func::Lt;

  my $func = Data::Object::Undef::Func::Lt->new(@args);

  $func->execute;

=description

Data::Object::Undef::Func::Lt is a function object for Data::Object::Undef.

=cut

# TESTING

use_ok 'Data::Object::Undef::Func::Lt';

ok 1 and done_testing;
