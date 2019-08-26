use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

reify

=usage

  # given 'Str';

  $type = reify 'Str'; # Type::Tiny

=description

The reify function will construct a L<Type::Tiny> type constraint object for
the type expression provided.

=signature

reify(Str $arg1) : Object

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'reify';

ok 1 and done_testing;
