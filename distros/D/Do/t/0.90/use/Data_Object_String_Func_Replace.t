use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Replace

=abstract

Data-Object String Function (Replace) Class

=synopsis

  use Data::Object::String::Func::Replace;

  my $func = Data::Object::String::Func::Replace->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=description

Data::Object::String::Func::Replace is a function object for
Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Replace';

ok 1 and done_testing;
