use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Float::Func::Defined

=abstract

Data-Object Float Function (Defined) Class

=synopsis

  use Data::Object::Float::Func::Defined;

  my $func = Data::Object::Float::Func::Defined->new(@args);

  $func->execute;

=description

Data::Object::Float::Func::Defined is a function object for
Data::Object::Float. This package inherits all behavior from
L<Data::Object::Float::Func>.

=cut

# TESTING

use_ok 'Data::Object::Float::Func::Defined';

ok 1 and done_testing;
