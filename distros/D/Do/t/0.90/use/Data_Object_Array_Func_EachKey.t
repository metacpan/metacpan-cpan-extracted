use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Array::Func::EachKey

=abstract

Data-Object Array Function (EachKey) Class

=synopsis

  use Data::Object::Array::Func::EachKey;

  my $func = Data::Object::Array::Func::EachKey->new(@args);

  $func->execute;

=description

Data::Object::Array::Func::EachKey is a function object for
Data::Object::Array. This package inherits all behavior from
L<Data::Object::Array::Func>.

=cut

# TESTING

use_ok 'Data::Object::Array::Func::EachKey';

ok 1 and done_testing;
