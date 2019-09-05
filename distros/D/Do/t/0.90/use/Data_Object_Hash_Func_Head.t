use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Head

=abstract

Data-Object Hash Function (Head) Class

=synopsis

  use Data::Object::Hash::Func::Head;

  my $func = Data::Object::Hash::Func::Head->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=description

Data::Object::Hash::Func::Head is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Head';

ok 1 and done_testing;
