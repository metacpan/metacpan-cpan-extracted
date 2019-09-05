use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Chop

=abstract

Data-Object String Function (Chop) Class

=synopsis

  use Data::Object::String::Func::Chop;

  my $func = Data::Object::String::Func::Chop->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=description

Data::Object::String::Func::Chop is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Chop';

ok 1 and done_testing;
