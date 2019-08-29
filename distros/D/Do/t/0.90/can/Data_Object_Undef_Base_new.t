use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given undef

  package My::Undef;

  use parent 'Data::Object::Undef::Base';

  my $undef = My::Undef->new(undef);

=description

The new method expects an undefined value and returns a new class instance.

=signature

new(Undef $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Undef;
use Data::Object::Undef::Base;

can_ok "Data::Object::Undef::Base", "new";

my $data;

# instantiate
$data = Data::Object::Undef->new(undef);
isa_ok $data, 'Data::Object::Undef::Base';

# instantiate with object
$data = Data::Object::Undef::Base->new($data);
isa_ok $data, 'Data::Object::Undef::Base';

# no instantiation error
ok !${Data::Object::Undef::Base->new};

ok 1 and done_testing;
