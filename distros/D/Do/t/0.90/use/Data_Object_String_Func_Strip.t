use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Strip

=abstract

Data-Object String Function (Strip) Class

=synopsis

  use Data::Object::String::Func::Strip;

  my $func = Data::Object::String::Func::Strip->new(@args);

  $func->execute;

=description

Data::Object::String::Func::Strip is a function object for Data::Object::String.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Strip';

ok 1 and done_testing;
