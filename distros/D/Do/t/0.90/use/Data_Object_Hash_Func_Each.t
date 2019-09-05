use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Each

=abstract

Data-Object Hash Function (Each) Class

=synopsis

  use Data::Object::Hash::Func::Each;

  my $func = Data::Object::Hash::Func::Each->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=description

Data::Object::Hash::Func::Each is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Each';

ok 1 and done_testing;
