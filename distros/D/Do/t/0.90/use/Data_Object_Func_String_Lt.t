use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Lt

=abstract

Data-Object String Function (Lt) Class

=synopsis

  use Data::Object::Func::String::Lt;

  my $func = Data::Object::Func::String::Lt->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Lt is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Lt';

ok 1 and done_testing;
