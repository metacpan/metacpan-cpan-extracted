use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::List

=abstract

Data-Object Hash Function (List) Class

=synopsis

  use Data::Object::Hash::Func::List;

  my $func = Data::Object::Hash::Func::List->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::List is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::List';

ok 1 and done_testing;
