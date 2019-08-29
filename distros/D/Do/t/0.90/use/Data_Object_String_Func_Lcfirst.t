use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Lcfirst

=abstract

Data-Object String Function (Lcfirst) Class

=synopsis

  use Data::Object::String::Func::Lcfirst;

  my $func = Data::Object::String::Func::Lcfirst->new(@args);

  $func->execute;

=description

Data::Object::String::Func::Lcfirst is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Lcfirst';

ok 1 and done_testing;
