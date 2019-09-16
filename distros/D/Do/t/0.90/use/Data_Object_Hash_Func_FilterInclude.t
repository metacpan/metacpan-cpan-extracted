use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Hash::Func::FilterInclude

=abstract

Data-Object Hash Function (FilterInclude) Class

=synopsis

  use Data::Object::Hash::Func::FilterInclude;

  my $func = Data::Object::Hash::Func::FilterInclude->new(@args);

  $func->execute;

=inherits

Data::Object::Hash::Func

=attributes

arg1(Object, req, ro)
args(ArrayRef[StringLike], req, ro)

=libraries

Data::Object::Library

=description

Data::Object::Hash::Func::FilterInclude is a function object for
Data::Object::Hash.

=cut

# TESTING

use_ok 'Data::Object::Hash::Func::FilterInclude';

ok 1 and done_testing;
