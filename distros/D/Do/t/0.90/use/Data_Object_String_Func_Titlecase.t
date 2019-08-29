use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Titlecase

=abstract

Data-Object String Function (Titlecase) Class

=synopsis

  use Data::Object::String::Func::Titlecase;

  my $func = Data::Object::String::Func::Titlecase->new(@args);

  $func->execute;

=description

Data::Object::String::Func::Titlecase is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Titlecase';

ok 1 and done_testing;
