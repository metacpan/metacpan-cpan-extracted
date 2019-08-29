use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given 9

  package My::Integer;

  use parent 'Data::Object::Integer::Base';

  my $integer = My::Integer->new(9);

=description

The new method expects a number and returns a new class instance.

=signature

new(Int $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Integer;
use Data::Object::Integer::Base;

can_ok "Data::Object::Integer::Base", "new";

my $data;

# instantiate
$data = Data::Object::Integer->new(-100);
isa_ok $data, 'Data::Object::Integer::Base';

# instantiate with object
$data = Data::Object::Integer::Base->new($data);
isa_ok $data, 'Data::Object::Integer::Base';

# instantiation error
ok !eval{Data::Object::Integer::Base->new};
like $@, qr(Instantiation Error);

ok 1 and done_testing;
