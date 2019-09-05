use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Lc

=abstract

Data-Object String Function (Lc) Class

=synopsis

  use Data::Object::String::Func::Lc;

  my $func = Data::Object::String::Func::Lc->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=description

Data::Object::String::Func::Lc is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Lc';

ok 1 and done_testing;
