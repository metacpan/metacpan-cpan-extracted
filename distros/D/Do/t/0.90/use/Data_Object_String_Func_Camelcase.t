use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Camelcase

=abstract

Data-Object String Function (Camelcase) Class

=synopsis

  use Data::Object::String::Func::Camelcase;

  my $func = Data::Object::String::Func::Camelcase->new(@args);

  $func->execute;

=inherits

Data::Object::String::Func

=description

Data::Object::String::Func::Camelcase is a function object for
Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Camelcase';

ok 1 and done_testing;
