use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Lowercase

=abstract

Data-Object String Function (Lowercase) Class

=synopsis

  use Data::Object::String::Func::Lowercase;

  my $func = Data::Object::String::Func::Lowercase->new(@args);

  $func->execute;

=description

Data::Object::String::Func::Lowercase is a function object for
Data::Object::String. This package inherits all behavior from
L<Data::Object::String::Func>.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Lowercase';

ok 1 and done_testing;
