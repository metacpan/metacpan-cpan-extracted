use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $code = Data::Object::Autobox::Code->new(sub{1});

=description

Construct a new object.

=signature

new(CodeRef $arg1) : CodeObject

=type

method

=cut

# TESTING

use Data::Object::Autobox::Code;

can_ok "Data::Object::Autobox::Code", "new";

ok 1 and done_testing;
