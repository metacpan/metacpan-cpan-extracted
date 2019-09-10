use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given 1_000_000

  my $number = Data::Object::Number->new(1_000_000);

=description

The new method expects a number and returns a new class instance.

=signature

new(Int $arg1) : NumObject

=type

method

=cut

# TESTING

use Data::Object::Number;

can_ok "Data::Object::Number", "new";

my $data;

# instantiate
$data = Data::Object::Number->new(100);
isa_ok $data, 'Data::Object::Number';

# instantiate with object
$data = Data::Object::Number->new($data);
isa_ok $data, 'Data::Object::Number';

# instantiate without arg
$data = Data::Object::Number->new;
isa_ok $data, 'Data::Object::Number';
is_deeply $$data, '0';

# instantiation error
ok !eval{Data::Object::Number->new('y')};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
