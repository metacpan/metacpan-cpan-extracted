use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::Lt

=abstract

Data-Object Hash Function (Lt) Class

=synopsis

  use Data::Object::Func::Hash::Lt;

  my $func = Data::Object::Func::Hash::Lt->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::Lt is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::Lt';

ok 1 and done_testing;
