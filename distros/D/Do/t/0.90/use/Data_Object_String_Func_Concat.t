use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Concat

=abstract

Data-Object String Function (Concat) Class

=synopsis

  use Data::Object::String::Func::Concat;

  my $func = Data::Object::String::Func::Concat->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=description

Data::Object::String::Func::Concat is a function object for
Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Concat';

ok 1 and done_testing;
