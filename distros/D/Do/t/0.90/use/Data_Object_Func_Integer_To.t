use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Integer::To

=abstract

Data-Object Integer Function (To) Class

=synopsis

  use Data::Object::Func::Integer::To;

  my $func = Data::Object::Func::Integer::To->new(@args);

  $func->execute;

=description

Data::Object::Func::Integer::To is a function object for Data::Object::Integer.

=cut

# TESTING

use_ok 'Data::Object::Func::Integer::To';

ok 1 and done_testing;
