use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Integer::Func::Downto

=abstract

Data-Object Integer Function (Downto) Class

=synopsis

  use Data::Object::Integer::Func::Downto;

  my $func = Data::Object::Integer::Func::Downto->new(@args);

  $func->execute;

=description

Data::Object::Integer::Func::Downto is a function object for
Data::Object::Integer. This package inherits all behavior from
L<Data::Object::Integer::Func>.

=cut

# TESTING

use_ok 'Data::Object::Integer::Func::Downto';

ok 1 and done_testing;
