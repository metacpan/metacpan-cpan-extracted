use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  package My::Any;

  use parent 'Data::Object::Base::Any';

  my $any = My::Any->new(\*main);

=description

Construct a new object.

=signature

new(Any $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Base::Any;

can_ok "Data::Object::Base::Any", "new";

my $data;

# instantiate
$data = Data::Object::Base::Any->new(sub {1});
isa_ok $data, 'Data::Object::Base::Any';

# instantiate with object
$data = Data::Object::Base::Any->new($data);
isa_ok $data, 'Data::Object::Base::Any';

# no instantiation error
ok eval { Data::Object::Base::Any->new; 1 } && !$@;

ok 1 and done_testing;
