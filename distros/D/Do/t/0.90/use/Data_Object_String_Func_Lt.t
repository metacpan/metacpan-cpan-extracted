use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Lt

=abstract

Data-Object String Function (Lt) Class

=synopsis

  use Data::Object::String::Func::Lt;

  my $func = Data::Object::String::Func::Lt->new(@args);

  $func->execute;

=description

Data::Object::String::Func::Lt is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Lt';

ok 1 and done_testing;
