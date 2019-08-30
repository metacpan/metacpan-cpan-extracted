use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

ge

=usage

  # given $re

  $re->ge; # exception thrown

=description

The ge method is a consumer requirement but has no function and is not
implemented. This method will throw an exception if called.

=signature

ge(Any $arg1) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Regexp';

my $data = Data::Object::Regexp->new(qr(\w+));

ok !eval { $data->ge() };

ok 1 and done_testing;
