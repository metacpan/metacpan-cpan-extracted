use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::String::Chomp

=abstract

Data-Object String Function (Chomp) Class

=synopsis

  use Data::Object::Func::String::Chomp;

  my $func = Data::Object::Func::String::Chomp->new(@args);

  $func->execute;

=description

Data::Object::Func::String::Chomp is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::Func::String::Chomp';

ok 1 and done_testing;
