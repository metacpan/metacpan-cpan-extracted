use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

le

=usage

  # given $re

  $re->le; # exception thrown

=description

The le method is a consumer requirement but has no function and is not
implemented. This method will throw an exception if called.

=signature

le(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Regexp';

my $data = Data::Object::Regexp->new(qr(\w+));

ok !eval { $data->le() };

ok 1 and done_testing;
