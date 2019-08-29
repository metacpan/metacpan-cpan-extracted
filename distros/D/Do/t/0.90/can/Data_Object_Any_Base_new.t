use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  package My::Any;

  use parent 'Data::Object::Any::Base';

  my $any = My::Any->new(\*main);

=description

Construct a new object.

=signature

new(Any $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Any::Base;

can_ok "Data::Object::Any::Base", "new";

my $data;

# instantiate
$data = Data::Object::Any::Base->new(sub {1});
isa_ok $data, 'Data::Object::Any::Base';

# instantiate with object
$data = Data::Object::Any::Base->new($data);
isa_ok $data, 'Data::Object::Any::Base';

# no instantiation error
ok eval { Data::Object::Any::Base->new; 1 } && !$@;

ok 1 and done_testing;
