use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given abcedfghi

  package My::String;

  use parent 'Data::Object::String::Base';

  my $string = My::String->new('abcedfghi');

=description

The new method expects a string and returns a new class instance.

=signature

new(Str $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::String;
use Data::Object::String::Base;

can_ok "Data::Object::String::Base", "new";

my $data;

# instantiate
$data = Data::Object::String->new("hello world");
isa_ok $data, 'Data::Object::String::Base';

# instantiate with object
$data = Data::Object::String::Base->new($data);
isa_ok $data, 'Data::Object::String::Base';

# no instantiation error
ok !${Data::Object::String::Base->new};

ok 1 and done_testing;
