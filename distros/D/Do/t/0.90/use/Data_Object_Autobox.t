use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Autobox

=abstract

Data-Object Autoboxing

=synopsis

  use Data::Object::Autobox;

  my $input  = [1,1,1,1,3,3,2,1,5,6,7,8,9];
  my $output = $input->grep(sub{$_[0] < 5})->unique->sort; # [1,2,3]

  $output->join(',')->print; # 1,2,3

  $object->isa('Data::Object::Array');

=inherits

autobox

=libraries

Data::Object::Library

=description

This package implements autoboxing via L<autobox> to provide
L<boxing|http://en.wikipedia.org/wiki/Object_type_(object-oriented_programming)>
for native Perl 5 data types.

=cut

use_ok "Data::Object::Autobox";

ok 1 and done_testing;
