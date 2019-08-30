use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Undef::Func::Le

=abstract

Data-Object Undef Function (Le) Class

=synopsis

  use Data::Object::Undef::Func::Le;

  my $func = Data::Object::Undef::Func::Le->new(@args);

  $func->execute;

=description

Data::Object::Undef::Func::Le is a function object for Data::Object::Undef.
This package inherits all behavior from L<Data::Object::Undef::Func>.

=cut

# TESTING

use_ok 'Data::Object::Undef::Func::Le';

ok 1 and done_testing;
