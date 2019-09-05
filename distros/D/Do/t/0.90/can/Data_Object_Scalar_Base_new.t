use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  package My::Scalar;

  use parent 'Data::Object::Scalar::Base';

  my $scalar = My::Scalar->new(\*main);

=description

Construct a new object.

=signature

new(Any $arg1) : Object

=type

method

=cut

# TESTING

no warnings 'once';

use Data::Object::Scalar;
use Data::Object::Scalar::Base;

can_ok "Data::Object::Scalar::Base", "new";

my $data;

# instantiate
$data = Data::Object::Scalar->new(\*main);
isa_ok $data, 'Data::Object::Scalar::Base';

# instantiate with object
$data = Data::Object::Scalar::Base->new($data);
isa_ok $data, 'Data::Object::Scalar::Base';

# no instantiation error
ok eval{ Data::Object::Scalar::Base->new; 1 } && !$@;

ok 1 and done_testing;
