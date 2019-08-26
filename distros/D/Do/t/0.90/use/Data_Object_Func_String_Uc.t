use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Uc

=abstract

Data-Object String Function (Uc) Class

=synopsis

  use Data::Object::Func::String::Uc;

  my $func = Data::Object::Func::String::Uc->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Uc is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Uc';

ok 1 and done_testing;
