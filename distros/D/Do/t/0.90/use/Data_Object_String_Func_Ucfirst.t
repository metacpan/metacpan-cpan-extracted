use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Ucfirst

=abstract

Data-Object String Function (Ucfirst) Class

=synopsis

  use Data::Object::String::Func::Ucfirst;

  my $func = Data::Object::String::Func::Ucfirst->new(@args);

  $func->execute;

=description

Data::Object::String::Func::Ucfirst is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Ucfirst';

ok 1 and done_testing;
