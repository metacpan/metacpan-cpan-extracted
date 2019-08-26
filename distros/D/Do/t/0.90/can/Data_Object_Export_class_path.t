use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

class_path

=usage

  # given 'Foo::BarBaz'

  class_path('Foo::BarBaz'); 'Foo/BarBaz.pm'

=description

The class_path function converts a class name to a class file.

=signature

class_path(Str $arg1) : Str

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'class_path';

is Data::Object::Export::class_path('Foo::BarBaz'), 'Foo/BarBaz.pm';

ok 1 and done_testing;
