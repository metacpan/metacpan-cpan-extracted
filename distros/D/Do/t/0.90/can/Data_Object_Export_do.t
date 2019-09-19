use 5.014;

use strict;
use warnings;

use Test::More;

plan skip_all => 'Refactoring';

# POD

=name

do

=usage

  # given file syntax

  do 'file.pl'

  # given block syntax

  do { @{"${class}::ISA"} }

  # given func-args syntax

  do('array', [1..4]); # Data::Object::Array

=description

The do function is a special constructor function that is automatically
exported into the consuming package. It overloads and extends the core
L<perlfunc/do> function, supporting the core functionality and adding a new
feature, and exists to dispatch to exportable Data-Object functions and other
dispatchers.

=signature

do(Str $arg1, Any @args) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

can_ok 'Data::Object::Export', 'do';

use Data::Object 'Core';

ok !eval { do() };
ok !eval { do('') };

ok do {{}};
ok do ('cast', {});
ok !do '/path/to/file';

ok 1 and done_testing;
