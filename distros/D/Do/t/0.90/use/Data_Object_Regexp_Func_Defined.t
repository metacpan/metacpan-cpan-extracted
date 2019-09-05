use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Regexp::Func::Defined

=abstract

Data-Object Regexp Function (Defined) Class

=synopsis

  use Data::Object::Regexp::Func::Defined;

  my $func = Data::Object::Regexp::Func::Defined->new(@args);

  $func->execute;

=inherits

Data::Object::Regexp::Func

=description

Data::Object::Regexp::Func::Defined is a function object for
Data::Object::Regexp.

=cut

# TESTING

use_ok 'Data::Object::Regexp::Func::Defined';

ok 1 and done_testing;
