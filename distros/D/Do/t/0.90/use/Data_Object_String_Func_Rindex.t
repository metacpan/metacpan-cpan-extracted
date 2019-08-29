use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Rindex

=abstract

Data-Object String Function (Rindex) Class

=synopsis

  use Data::Object::String::Func::Rindex;

  my $func = Data::Object::String::Func::Rindex->new(@args);

  $func->execute;

=description

Data::Object::String::Func::Rindex is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Rindex';

ok 1 and done_testing;
