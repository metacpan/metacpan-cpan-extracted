use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Split

=abstract

Data-Object String Function (Split) Class

=synopsis

  use Data::Object::String::Func::Split;

  my $func = Data::Object::String::Func::Split->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=description

Data::Object::String::Func::Split is a function object for
Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Split';

ok 1 and done_testing;
