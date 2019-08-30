use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::String::Func::Defined

=abstract

Data-Object String Function (Defined) Class

=synopsis

  use Data::Object::String::Func::Defined;

  my $func = Data::Object::String::Func::Defined->new(@args);

  $func->execute;

=description

Data::Object::String::Func::Defined is a function object for
Data::Object::String. This package inherits all behavior from
L<Data::Object::String::Func>.

=cut

# TESTING

use_ok 'Data::Object::String::Func::Defined';

ok 1 and done_testing;
