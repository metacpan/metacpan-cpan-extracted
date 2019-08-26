use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given \*main

  package My::Scalar;

  use parent 'Data::Object::Base::Scalar';

  my $scalar = My::Scalar->new(\*main);

=description

The new method expects a scalar reference and returns a new class instance.

=signature

new(ScalarRef $arg1) : Object

=type

method

=cut

# TESTING

no warnings 'once';

use Data::Object::Scalar;
use Data::Object::Base::Scalar;

can_ok "Data::Object::Base::Scalar", "new";

my $data;

# instantiate
$data = Data::Object::Scalar->new(\*main);
isa_ok $data, 'Data::Object::Base::Scalar';

# instantiate with object
$data = Data::Object::Base::Scalar->new($data);
isa_ok $data, 'Data::Object::Base::Scalar';

# no instantiation error
ok eval{ Data::Object::Base::Scalar->new; 1 } && !$@;

ok 1 and done_testing;
