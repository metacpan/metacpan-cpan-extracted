use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Hash::FilterInclude

=abstract

Data-Object Hash Function (FilterInclude) Class

=synopsis

  use Data::Object::Func::Hash::FilterInclude;

  my $func = Data::Object::Func::Hash::FilterInclude->new(@args);

  $func->execute;

=description

Data::Object::Func::Hash::FilterInclude is a function object for Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Func::Hash::FilterInclude';

ok 1 and done_testing;
