use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Lc

=abstract

Data-Object String Function (Lc) Class

=synopsis

  use Data::Object::Func::String::Lc;

  my $func = Data::Object::Func::String::Lc->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Lc is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Lc';

ok 1 and done_testing;
