use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Lt

=abstract

Data-Object Hash Function (Lt) Class

=synopsis

  use Data::Object::Hash::Func::Lt;

  my $func = Data::Object::Hash::Func::Lt->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=description

Data::Object::Hash::Func::Lt is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Lt';

ok 1 and done_testing;
