use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  package My::Array;

  use parent 'Data::Object::Array::Base';

  # given 1..9

  my $array = My::Array->new([1..9]);

=description

The new method expects a list or array reference and returns a new class
instance.

=signature

new(ArrayRef $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Array;
use Data::Object::Array::Base;

can_ok "Data::Object::Array::Base", "new";

my $data;

# instantiate
$data = Data::Object::Array->new([1..4]);
isa_ok $data, 'Data::Object::Array::Base';

# instantiate with object
$data = Data::Object::Array::Base->new($data);
isa_ok $data, 'Data::Object::Array::Base';

# instantiate without arg
$data = Data::Object::Array::Base->new;
isa_ok $data, 'Data::Object::Array::Base';
is_deeply $data, [];

# instantiation error
ok !eval{Data::Object::Array::Base->new({})};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
