use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given undef

  my $undef = Data::Object::Undef->new(undef);

=description

The new method expects an undefined value and returns a new class instance.

=signature

new(Undef $arg1) : UndefObject

=type

method

=cut

# TESTING

use Data::Object::Undef;

can_ok "Data::Object::Undef", "new";

my $data;

# instantiate
$data = Data::Object::Undef->new(undef);
isa_ok $data, 'Data::Object::Undef';

# instantiate with object
$data = Data::Object::Undef->new($data);
isa_ok $data, 'Data::Object::Undef';

# no instantiation error
ok !Data::Object::Undef->new;

ok 1 and done_testing;
