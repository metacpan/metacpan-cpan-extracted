use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given 1..9

  my $array = Data::Object::Array->new(1..9);
  my $array = Data::Object::Array->new([1..9]);

=description

The new method expects a list or array reference and returns a new class
instance.

=signature

new(ArrayRef $arg1) : ArrayObject

=type

method

=cut

# TESTING

use Data::Object::Array;

can_ok "Data::Object::Array", "new";

my $data;

# instantiate
$data = Data::Object::Array->new([1..4]);
isa_ok $data, 'Data::Object::Array';

# instantiate with object
$data = Data::Object::Array->new($data);
isa_ok $data, 'Data::Object::Array';

# instantiate without arg
$data = Data::Object::Array->new;
isa_ok $data, 'Data::Object::Array';
is_deeply $data, [];

# instantiation error
ok !eval{Data::Object::Array->new({})};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
