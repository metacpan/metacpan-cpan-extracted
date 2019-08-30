use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lt

=usage

  # given $re

  $re->lt; # exception thrown

=description

The lt method is a consumer requirement but has no function and is not
implemented. This method will throw an exception if called.

=signature

lt(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Regexp';

my $data = Data::Object::Regexp->new(qr(\w+));

ok !eval { $data->lt() };

ok 1 and done_testing;
