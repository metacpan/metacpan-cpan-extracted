use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::FilterExclude

=abstract

Data-Object Hash Function (FilterExclude) Class

=synopsis

  use Data::Object::Hash::Func::FilterExclude;

  my $func = Data::Object::Hash::Func::FilterExclude->new(@args);

  $func->execute;

=description

Data::Object::Hash::Func::FilterExclude is a function object for
Data::Object::Hash. This package inherits all behavior from
L<Data::Object::Hash::Func>.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::FilterExclude';

ok 1 and done_testing;
