use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Le

=abstract

Data-Object String Function (Le) Class

=synopsis

  use Data::Object::String::Func::Le;

  my $func = Data::Object::String::Func::Le->new(@args);

  $func->execute;

=description

Data::Object::String::Func::Le is a function object for Data::Object::String.
This package inherits all behavior from L<Data::Object::String::Func>.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Le';

ok 1 and done_testing;
