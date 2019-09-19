use 5.014;

use strict;
use warnings;

use Test::More;

plan skip_all => 'Refactoring';

# POD

=name

load

=usage

  # given 'List::Util';

  $package = do('load', 'List::Util'); # List::Util

=description

The load function attempts to dynamically load a module and either raises an
exception or returns the package name of the loaded module. This function is
not exported but can be access via the L<super-do|/do> function.

=signature

load(Str $arg1) : ClassName

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'load';

ok 1 and done_testing;
