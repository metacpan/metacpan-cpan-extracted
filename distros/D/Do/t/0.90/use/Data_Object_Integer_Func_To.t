use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Integer::Func::To

=abstract

Data-Object Integer Function (To) Class

=synopsis

  use Data::Object::Integer::Func::To;

  my $func = Data::Object::Integer::Func::To->new(@args);

  $func->execute;

=description

Data::Object::Integer::Func::To is a function object for Data::Object::Integer.

=cut

# TESTING

use_ok 'Data::Object::Integer::Func::To';

ok 1 and done_testing;
