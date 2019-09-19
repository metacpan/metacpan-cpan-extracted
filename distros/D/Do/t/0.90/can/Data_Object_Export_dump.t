use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

dump

=usage

  # given $value

  my $str = do('dump', $value);

=description

The dump function uses L<Data::Dumper> to return a string representation of the
argument provided. This function is not exported but can be access via the
L<super-do|/do> function.

=signature

dump(Any $value) : Str

=type

function

=cut

# TESTING

use Data::Object::Export;

can_ok "Data::Object::Export", "dump";

ok 1 and done_testing;
