use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Iterator

=abstract

Data-Object Hash Function (Iterator) Class

=synopsis

  use Data::Object::Hash::Func::Iterator;

  my $func = Data::Object::Hash::Func::Iterator->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Iterator is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Iterator';

ok 1 and done_testing;
