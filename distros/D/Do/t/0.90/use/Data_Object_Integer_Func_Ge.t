use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Integer::Func::Ge

=abstract

Data-Object Integer Function (Ge) Class

=synopsis

  use Data::Object::Integer::Func::Ge;

  my $func = Data::Object::Integer::Func::Ge->new(@args);

  $func->execute;

=description

Data::Object::Integer::Func::Ge is a function object for Data::Object::Integer.
This package inherits all behavior from L<Data::Object::Integer::Func>.

=cut

# TESTING

use_ok 'Data::Object::Integer::Func::Ge';

ok 1 and done_testing;
