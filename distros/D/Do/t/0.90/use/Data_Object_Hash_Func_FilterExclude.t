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

=inherits

Data::Object::Hash::Func

=attributes

arg1(Object, req, ro)
args(ArrayRef[Str], req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Hash::Func::FilterExclude is a function object for
Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::FilterExclude';

ok 1 and done_testing;
