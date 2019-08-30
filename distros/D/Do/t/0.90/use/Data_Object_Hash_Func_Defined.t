use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::Defined

=abstract

Data-Object Hash Function (Defined) Class

=synopsis

  use Data::Object::Hash::Func::Defined;

  my $func = Data::Object::Hash::Func::Defined->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::Defined is a function object for Data::Object::Hash.
This package inherits all behavior from L<Data::Object::Hash::Func>.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::Defined';

ok 1 and done_testing;
