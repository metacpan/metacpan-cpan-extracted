use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given 9.9999

  my $float = Data::Object::Float->new(9.9999);

=description

The new method expects a floating-point number and returns a new class instance.

=signature

new(Num $arg1) : FloatObject

=type

method

=cut

# TESTING

use Data::Object::Float;

can_ok "Data::Object::Float", "new";

my $data;

# instantiate
$data = Data::Object::Float->new(5.25);
isa_ok $data, 'Data::Object::Float';

# instantiate with object
$data = Data::Object::Float->new($data);
isa_ok $data, 'Data::Object::Float';

# instantiation error
ok !eval{Data::Object::Float->new};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
