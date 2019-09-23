use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

boolean

=usage

  # given 1

  my $bool = Data::Object->boolean(1); # true

=description

The C<boolean> constructor function returns a L<Data::Object::Boolean> object for the given argument.

=signature

boolean(Any $arg) : BooleanObject

=type

method

=cut

# TESTING

use Data::Object;

can_ok "Data::Object", "boolean";

my $boolean;

$boolean = Data::Object->boolean(1);

isa_ok $boolean, 'Data::Object::Boolean';

$boolean = Data::Object->boolean(0);

isa_ok $boolean, 'Data::Object::Boolean';

ok 1 and done_testing;
