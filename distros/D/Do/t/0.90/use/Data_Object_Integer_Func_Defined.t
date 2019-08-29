use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Integer::Func::Defined

=abstract

Data-Object Integer Function (Defined) Class

=synopsis

  use Data::Object::Integer::Func::Defined;

  my $func = Data::Object::Integer::Func::Defined->new(@args);

  $func->execute;

=description

Data::Object::Integer::Func::Defined is a function object for Data::Object::Integer.

=cut

# TESTING

use_ok 'Data::Object::Integer::Func::Defined';

ok 1 and done_testing;
