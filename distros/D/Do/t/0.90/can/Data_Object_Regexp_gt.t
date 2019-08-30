use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

gt

=usage

  # given $re

  $re->gt; # exception thrown

=description

The gt method is a consumer requirement but has no function and is not
implemented. This method will throw an exception if called.

=signature

gt(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Regexp';

my $data = Data::Object::Regexp->new(qr(\w+));

ok !eval { $data->gt() };

ok 1 and done_testing;
